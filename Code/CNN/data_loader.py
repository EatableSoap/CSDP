import gzip
import numpy as np
import struct
import os
from array import array
import torch
from torch.utils.data import Dataset, DataLoader


class SPOT10Loader:
    def __init__(self):
        pass

    @staticmethod
    def get_data(dataset_dir, kind='train'):
        """Load custom MNIST data from `path`"""
        labels_path = os.path.join(dataset_dir, f'{kind}-labels-idx1-ubyte.gz')
        images_path = os.path.join(dataset_dir, f'{kind}-images-idx3-ubyte.gz')

        with gzip.open(labels_path, 'rb') as file:
            magic, size = struct.unpack(">II", file.read(8))
            if magic != 2049:
                raise ValueError('Magic number mismatch, expected 2049, got {}'.format(magic))
            labels = array("B", file.read())

        with gzip.open(images_path, 'rb') as file:
            magic, size, rows, cols = struct.unpack(">IIII", file.read(16))
            if magic != 2051:
                raise ValueError('Magic number mismatch, expected 2051, got {}'.format(magic))
            image_data = array("B", file.read())

        images = np.zeros((size, rows, cols), dtype=np.uint8)
        for i in range(size):
            images[i] = np.array(image_data[i * rows * cols:(i + 1) * rows * cols]).reshape(rows, cols)

        return np.array(images), np.array(labels)


class SPOT10Dataset(Dataset):
    def __init__(self, images, labels, transform=None):
        self.images = images
        self.labels = labels
        self.transform = transform

    def __len__(self):
        return len(self.images)

    def __getitem__(self, idx):
        image = self.images[idx]
        label = self.labels[idx]

        # Add channel dimension and normalize
        image = image.astype(np.float32) / 255.0
        image = np.expand_dims(image, axis=0)

        if self.transform:
            image = self.transform(image)

        return torch.tensor(image, dtype=torch.float32), torch.tensor(label, dtype=torch.long)


def get_data_loaders(batch_size=64):
    data_loader = SPOT10Loader()

    # Load training data
    train_images, train_labels = data_loader.get_data(dataset_dir="./dataset", kind='train')
    test_images, test_labels = data_loader.get_data(dataset_dir="./dataset", kind='test')

    # Create datasets
    train_dataset = SPOT10Dataset(train_images, train_labels)
    test_dataset = SPOT10Dataset(test_images, test_labels)

    # Create data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=2)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=2)

    return train_loader, test_loader


# Test the data loader
if __name__ == "__main__":
    train_loader, test_loader = get_data_loaders(batch_size=32)

    # Check one batch
    for images, labels in train_loader:
        print(f"Batch images shape: {images.shape}")
        print(f"Batch labels shape: {labels.shape}")
        print(f"Labels: {labels[:10]}")
        break