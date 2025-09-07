import numpy as np
import struct

from tqdm import tqdm


def float16_to_hex4(value: float) -> list[str]:
    """
    将一个浮点数转换为 IEEE 754 半精度浮点数 (float16)，
    并输出 4 个 16 进制字符串（每个2位）。
    """
    # 转换为float16
    f16 = np.float16(value)

    # 获取16位无符号整数表示
    bits = f16.view(np.uint16)

    # 拆分成4个十六进制字符串（每个代表4位）
    hex_list = [f"{(bits >> shift) & 0xF:X}".lower() for shift in (12, 8, 4, 0)]

    return hex_list


def hex4_to_float16(hexStr) -> float:
    """
    将4个16进制字符串（每个1位，合起来16位）
    转换为IEEE 754半精度浮点数，并返回float值。
    例如: ['3','c','0','0'] -> 1.0
    """
    if len(hexStr) != 4:
        raise ValueError("必须传入4个16进制字符串")

    # 拼接成完整的16位十六进制
    bits = int(hexStr, 16)  # 转换为整数

    # 转换为float16，再转为Python float
    f16 = np.uint16(bits).view(np.float16)
    return float(f16)


def hex_to_float(hex_str):
    """将8位16进制字符串转为IEEE754单精度浮点数"""
    # 转成 int，再转成4字节
    i = int(hex_str, 16)
    b = i.to_bytes(4, byteorder='big')  # 假设大端（常见存储方式）
    return struct.unpack('!f', b)[0]  # ! 表示network(big-endian)

def float_to_hex(f):
    """将IEEE754单精度浮点数转为8位16进制字符串"""
    b = struct.pack('!f', f)            # ! 表示 big-endian，4字节
    return b.hex()


# ---------------- 工具函数 ----------------
def load_weights(filename, shape):
    """从txt文件加载权重并reshape"""
    with open(filename, "r") as f:
        data = f.read().split()
    data = [hex4_to_float16(x[i:i + 4]) for x in data for i in range(0, len(x), 4)]
    weights = np.array([float(x) for x in data])
    return weights.reshape(shape)


def load_weights32(filename, shape):
    """从txt文件加载权重并reshape"""
    with open(filename, "r") as f:
        data = f.read().split()
    data = [hex_to_float(x) for x in data]
    weights = np.array([float(x) for x in data])
    return weights.reshape(shape)


def hex_to_image(hex_list):
    """4096个16进制字符串 -> 32x32灰度图 (范围0-1)"""
    arr = np.array(hex_list, dtype=np.float32)
    arr = arr.reshape(32, 32)
    return arr[np.newaxis, :, :]  # shape (1,32,32)


def relu(x):
    return np.maximum(0, x)


def conv2d(x, w, stride=1, padding=0):
    """
    x: (C_in, H, W)
    w: (C_out, C_in, kH, kW)
    """
    C_in, H, W = x.shape
    C_out, _, kH, kW = w.shape

    H_out = (H + 2 * padding - kH) // stride + 1
    W_out = (W + 2 * padding - kW) // stride + 1

    out = np.zeros((C_out, H_out, W_out))

    x_padded = np.pad(x, ((0, 0), (padding, padding), (padding, padding)), mode="constant")

    for co in range(C_out):
        for h in range(H_out):
            for ww in range(W_out):
                hs, ws = h * stride, ww * stride
                region = x_padded[:, hs:hs + kH, ws:ws + kW]
                out[co, h, ww] = np.sum(region * w[co])
    return out


def maxpool2d(x, size=2, stride=2):
    C, H, W = x.shape
    H_out, W_out = H // stride, W // stride
    out = np.zeros((C, H_out, W_out))
    for c in range(C):
        for h in range(H_out):
            for w in range(W_out):
                hs, ws = h * stride, w * stride
                out[c, h, w] = np.max(x[c, hs:hs + size, ws:ws + size])
    return out


def linear(x, W):
    return np.dot(x.T, W)


# ---------------- 加载权重 ----------------
conv1_w = load_weights("./distilled/conv1_hex.txt", (6, 1, 5, 5))  # 6个5x5卷积核
# conv1_b = load_bias("conv1.txt", 6)

conv2_w = load_weights("./distilled/conv2_hex.txt", (16, 6, 5, 5))
# conv2_b = load_bias("conv2.txt", 16)

conv3_w = load_weights("./distilled/conv3_hex.txt", (32, 16, 3, 3))
# conv3_b = load_bias("conv3.txt", 32)

fc1_w = load_weights32("./distilled/fc1_hex.txt", (288, 120))
# fc1_b = load_bias("fc1.txt", 120)

fc2_w = load_weights32("./distilled/fc2_hex.txt", (120, 120))
# fc2_b = load_bias("fc2.txt", 120)

fc3_w = load_weights32("./distilled/fc3_hex.txt", (120, 84))
# fc3_b = load_bias("fc3.txt", 84)

fc4_w = load_weights32("./distilled/fc4_hex.txt", (84, 10))


# fc4_b = load_bias("fc4.txt", 10)


# ---------------- 推理函数 ----------------
def predict(hex_list):
    x = hex_to_image(hex_list)

    # Conv1 -> ReLU -> Pool
    x = relu(conv2d(x, conv1_w,padding=2))
    x = maxpool2d(x)

    # Conv2 -> ReLU -> Pool
    x = relu(conv2d(x, conv2_w))
    x = maxpool2d(x)

    # Conv3 -> ReLU
    x = relu(conv2d(x, conv3_w,padding=1))
    x = maxpool2d(x)

    # Flatten
    x = x.flatten()

    # x = hex_list

    # FC1 -> ReLU
    x = relu(linear(x, fc1_w))

    # FC2 -> ReLU
    x = relu(linear(x, fc2_w))

    # FC3 -> ReLU
    x = relu(linear(x, fc3_w))

    # FC4 -> Softmax
    x = linear(x, fc4_w)
    # probs = softmax(x)

    return np.argmax(x), x


# ---------------- 示例 ----------------
if __name__ == "__main__":
    correct = 0
    with open('./test_images_hex.txt', 'r') as f:
        images = f.readlines()
    images = [x.replace('\n', '') for x in images]
    with open('./test_labels.txt', 'r') as f:
        labels = f.readlines()
    labels = [int(x.replace('\n', '')) for x in labels]
    for ima, glab in tqdm(zip(images, labels)):
        hex_list = [hex4_to_float16(ima[i:i + 4]) for i in range(0, len(ima), 4)]
        label, probs = predict(hex_list)
        if label == glab:
            correct += 1
    print(correct / len(images))
    # ft = '3800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003d66e000380000003800000038000000380000003e37e0003d212000380000003c6d00003800000038000000380000003800000038000000380000003db7a00038000000380000003800000038000000380000003e58c00038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003c8580003ea1a000380000003e4b4000380000003da1200038000000380000003db7400038000000380000003d1a800038000000380000003e89e0003ec620003de7a0003ee2a0003e6dc0003d87c0003df8e0003d2000003e4720003e3be00038000000380000003d6420003d8620003800000038000000380000003e1420003d80200038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003e0480003d12e0003e87c0003e45a0003e9d40003e5fe0003e7080003e1bc0003e2700003e8dc0003e1460003d4400003800000038000000380000003d83c0003eaaa0003d4f40003d69c00038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003d64800038000000380000003800000038000000380000003800000038000000380000003deb60003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003dfe200038000000380000003d8d000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003e4400003e83c0003ed200003eb8a0003e9520003f2740003e7c80003f0320003e88a00038000000380000003cda000038000000380000003e5ca00038000000380000003c87800038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003ede2000380000003e5080003da9c00038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003e07c0003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003800000038000000380000003de300003e21c0003de880003e6f80003e7d80003e5d80003e3580003ecd80003d2240003cfac0003da7e0003efc4000380000003dc8c00038000000380000003e3080003dce60003e0de0003d55c00038000000380000003e89a00038000000380000003800000038000000'
    # ft = [hex_to_float(ft[i:i + 8]) for i in range(0, len(ft), 8)]
    # ft = np.array(ft, dtype=np.float32)
    # idx, res = predict(ft)
    # pass
