import torch
import torch.nn as nn
import torch.nn.functional as F


class LeNet5(nn.Module):
    def __init__(self, num_classes=10):
        super(LeNet5, self).__init__()
        # 输入: 1×32×32
        self.conv1 = nn.Conv2d(1, 6, kernel_size=5, stride=1, padding=2, bias=False)  # 输出: 6×32×32
        self.pool1 = nn.MaxPool2d(kernel_size=2, stride=2)  # 输出: 6×16×16

        self.conv2 = nn.Conv2d(6, 16, kernel_size=5, bias=False)  # 输出: 16×12×12
        self.pool2 = nn.MaxPool2d(kernel_size=2, stride=2)  # 输出: 16×6×6

        self.conv3 = nn.Conv2d(16, 32, kernel_size=3, padding=1, bias=False)  # 输出: 32×6×6
        self.pool3 = nn.MaxPool2d(kernel_size=2, stride=2)  # 输出: 32×3×3

        # 计算全连接层输入尺寸: 32 * 3 * 3 = 288
        self.fc1 = nn.Linear(32 * 3 * 3, 120, bias=False)
        self.fc2 = nn.Linear(120, 120, bias=False)
        self.fc3 = nn.Linear(120, 84, bias=False)
        self.fc4 = nn.Linear(84, num_classes, bias=False)
        self.dropout = nn.Dropout(0.5)

    def forward(self, x):
        # 卷积层1
        x = torch.relu(self.conv1(x))  # 6×32×32
        x = self.pool1(x)  # 6×16×16

        # 卷积层2
        x = torch.relu(self.conv2(x))  # 16×12×12
        x = self.pool2(x)  # 16×6×6

        # 卷积层3
        x = torch.relu(self.conv3(x))  # 32×6×6
        x = self.pool3(x)  # 32×3×3

        # 展平
        x = x.view(x.size(0), -1)  # 32×288

        # 全连接层
        x = torch.relu(self.fc1(x))
        x = self.dropout(x)
        x = torch.relu(self.fc2(x))  # 新增的120->120层
        x = self.dropout(x)
        x = torch.relu(self.fc3(x))
        x = self.fc4(x)
        return x


class ResNetTeacher(nn.Module):
    def __init__(self, num_classes=10):
        super(ResNetTeacher, self).__init__()
        # 输入: 1×32×32
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, stride=1, padding=1)  # 32×32×32
        self.bn1 = nn.BatchNorm2d(32)

        # Residual blocks
        self.resblock1 = self._make_residual_block(32, 64)  # 64×32×32
        self.resblock2 = self._make_residual_block(64, 128)  # 128×32×32
        self.resblock3 = self._make_residual_block(128, 256)  # 256×32×32

        # 全局最大池化
        self.global_avg_pool = nn.AdaptiveAvgPool2d((1, 1))  # 256×1×1
        self.fc = nn.Linear(256, num_classes)

    def _make_residual_block(self, in_channels, out_channels):
        # 如果输入输出通道数不同，需要1×1卷积来调整维度
        downsample = None
        if in_channels != out_channels:
            downsample = nn.Sequential(
                nn.Conv2d(in_channels, out_channels, kernel_size=1, stride=1),
                nn.BatchNorm2d(out_channels)
            )

        return nn.ModuleDict({
            'conv1': nn.Conv2d(in_channels, out_channels, kernel_size=3, padding=1),
            'bn1': nn.BatchNorm2d(out_channels),
            'conv2': nn.Conv2d(out_channels, out_channels, kernel_size=3, padding=1),
            'bn2': nn.BatchNorm2d(out_channels),
            'downsample': downsample,
            'relu': nn.ReLU()
        })

    def _forward_residual_block(self, x, block):
        identity = x

        out = block['conv1'](x)
        out = block['bn1'](out)
        out = block['relu'](out)

        out = block['conv2'](out)
        out = block['bn2'](out)

        # 如果需要调整维度
        if block['downsample'] is not None:
            identity = block['downsample'](x)

        out += identity
        out = block['relu'](out)
        return out

    def forward(self, x):
        # 初始卷积
        x = torch.relu(self.bn1(self.conv1(x)))  # 32×32×32

        # 残差块1
        x = self._forward_residual_block(x, self.resblock1)  # 64×32×32

        # 残差块2
        x = self._forward_residual_block(x, self.resblock2)  # 128×32×32

        # 残差块3
        x = self._forward_residual_block(x, self.resblock3)  # 256×32×32

        # 全局平均池化和全连接
        x = self.global_avg_pool(x)  # 256×1×1
        x = x.view(x.size(0), -1)  # 256
        x = self.fc(x)
        return x


class SimpleResNetTeacher(nn.Module):
    def __init__(self, num_classes=10):
        super(SimpleResNetTeacher, self).__init__()
        # 输入: 1×32×32
        # 初始卷积层
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(32)

        # 卷积块1
        self.conv_block1 = nn.Sequential(
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.Conv2d(64, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU()
        )

        # 下采样1
        self.downsample1 = nn.Sequential(
            nn.Conv2d(32, 64, kernel_size=1),
            nn.BatchNorm2d(64)
        )

        # 卷积块2
        self.conv_block2 = nn.Sequential(
            nn.Conv2d(64, 128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(),
            nn.Conv2d(128, 128, kernel_size=3, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU()
        )

        # 下采样2
        self.downsample2 = nn.Sequential(
            nn.Conv2d(64, 128, kernel_size=1),
            nn.BatchNorm2d(128)
        )

        # 全局最大池化
        self.global_avg_pool = nn.AdaptiveMaxPool2d((1, 1))
        self.fc = nn.Linear(128, num_classes)

    def forward(self, x):
        # 初始卷积
        x = torch.relu(self.bn1(self.conv1(x)))  # 32×32×32

        # 第一个残差块
        identity = x
        out = self.conv_block1(x)
        if identity.size(1) != out.size(1):
            identity = self.downsample1(identity)
        x = out + identity
        x = torch.relu(x)  # 64×32×32

        # 第二个残差块
        identity = x
        out = self.conv_block2(x)
        if identity.size(1) != out.size(1):
            identity = self.downsample2(identity)
        x = out + identity
        x = torch.relu(x)  # 128×32×32

        # 全局池化和全连接
        x = self.global_avg_pool(x)  # 128×1×1
        x = x.view(x.size(0), -1)  # 128
        x = self.fc(x)
        return x


# Test the model
if __name__ == "__main__":
    # Test LeNet-5
    print("Testing LeNet-5...")
    model = LeNet5()
    x = torch.randn(32, 1, 32, 32)
    print(f"Input shape: {x.shape}")

    output = model(x)
    print(f"LeNet-5 output shape: {output.shape}")

    total_params = sum(p.numel() for p in model.parameters())
    print(f"LeNet-5 total parameters: {total_params:,}")


    # Test Simple ResNet Teacher
    print("Testing Simple ResNet Teacher...")
    teacher = SimpleResNetTeacher()
    output = teacher(x)
    print(f"Simple ResNet Teacher output shape: {output.shape}")

    total_params = sum(p.numel() for p in teacher.parameters())
    print(f"Simple ResNet Teacher total parameters: {total_params:,}")

    print("All models working correctly!")