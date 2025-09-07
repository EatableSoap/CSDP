import gzip
import numpy as np
import torch
import os


def read_idx_images(filename):
    with gzip.open(filename, 'rb') as f:
        magic = int.from_bytes(f.read(4), 'big')
        if magic != 2051:
            raise ValueError(f"Invalid magic number {magic} in image file {filename}")
        num_images = int.from_bytes(f.read(4), 'big')
        rows = int.from_bytes(f.read(4), 'big')
        cols = int.from_bytes(f.read(4), 'big')
        buf = f.read(rows * cols * num_images)
        data = np.frombuffer(buf, dtype=np.uint8)
        data = data.reshape(num_images, rows, cols)
    return data


def read_idx_labels(filename):
    """读取 idx1-ubyte.gz 标签文件"""
    with gzip.open(filename, 'rb') as f:
        magic = int.from_bytes(f.read(4), 'big')
        if magic != 2049:
            raise ValueError(f"Invalid magic number {magic} in label file {filename}")
        num_labels = int.from_bytes(f.read(4), 'big')
        buf = f.read(num_labels)
        labels = np.frombuffer(buf, dtype=np.uint8)
    return labels


def image_to_fp16_hex_line(image):
    """
    将单张图像 numpy array [H,W] -> FP32归一化 -> FP16 -> 16进制字符串
    返回一行字符串，每个像素 4 位 hex，用空格分隔
    """
    image_fp32 = image.astype(np.float32) / 255.0
    tensor_fp16 = torch.tensor(image_fp32, dtype=torch.float16)
    tensor_uint16 = tensor_fp16.numpy().view(np.uint16)
    hex_list = [f"{val:04x}" for val in tensor_uint16.flatten()]
    return " ".join(hex_list)


def process_spots10_testset_single_file(image_path="./Dataset/test-images-idx3-ubyte.gz",
                                        label_path="./Dataset/test-labels-idx1-ubyte.gz",
                                        output_image_file="test_images_hex.txt",
                                        output_label_file="test_labels.txt"):
    images = read_idx_images(image_path)
    labels = read_idx_labels(label_path)

    with open(output_image_file, 'w') as f_img, open(output_label_file, 'w') as f_label:
        for idx, image in enumerate(images):
            hex_line = image_to_fp16_hex_line(image)
            f_img.write(hex_line + "\n")
            f_label.write(str(labels[idx]) + "\n")
            if (idx + 1) % 100 == 0:
                print(f"Processed {idx + 1}/{len(images)} images")

    print(f"Finished. Hex images saved to '{output_image_file}', labels saved to '{output_label_file}'.")


process_spots10_testset_single_file()
