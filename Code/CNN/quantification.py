import torch
import numpy as np
import os
from model import LeNet5


def save_weights_mixed_precision_hex(model, output_dir="weights_mixed_hex"):
    os.makedirs(output_dir, exist_ok=True)

    for name, module in model.named_modules():
        if isinstance(module, (torch.nn.Conv2d, torch.nn.Linear)):
            param = module.weight.detach().cpu().numpy()
            layer_type = "conv" if isinstance(module, torch.nn.Conv2d) else "fc"

            if layer_type == "conv":
                # 卷积层: [out_ch, in_ch, kH, kW]
                param_dtype = np.float16
                param_hex = param.astype(np.float16).view(np.uint16)
            else:  # fc
                # 全连接层: [out, in] -> [in, out]
                param = np.transpose(param, (1, 0))
                param_dtype = np.float32
                param_hex = param.astype(np.float32).view(np.uint32)

            weight_file = os.path.join(output_dir, f"{name.replace('.', '_')}_hex.txt")

            with open(weight_file, "w") as f:
                if param.ndim == 4:  # conv: [in_ch, out_ch, kH, kW]
                    for o in range(param.shape[0]):
                        line = ''
                        for i in range(param.shape[1]):
                            line += "".join(f"{w:04x}" for w in param_hex[o, i].flatten())
                        f.write(line + "\n")
                elif param.ndim == 2:  # fc: [in, out]
                    for i in range(param.shape[0]):
                        line = "\n".join(f"{w:08x}" for w in param_hex[i])
                        f.write(line + "\n")
                else:
                    # 其他维度直接 flatten
                    line = " ".join(f"{w:04x}" if layer_type == "conv" else f"{w:08x}"
                                    for w in param_hex.flatten())
                    f.write(line + "\n")

            print(f"Saved {layer_type} weights -> {weight_file}, shape={param.shape}, dtype={param_dtype}")

    print(f"卷积层 FP16 和全连接层 FP32 权重已保存为 16 进制 TXT 文件 -> {output_dir}/")


if __name__ == "__main__":
    model = LeNet5()
    state_dict = torch.load("best_student.pth", map_location="cuda:0", weights_only=True)
    model.load_state_dict(state_dict)
    model.eval()

    save_weights_mixed_precision_hex(model, output_dir="best_student_weights_mixed_hex")
