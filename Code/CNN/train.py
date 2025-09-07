import torch
import torch.optim as optim
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader
import numpy as np
from tqdm import tqdm
import math
import random
import matplotlib.pyplot as plt
from model import LeNet5, SimpleResNetTeacher
from data_loader import get_data_loaders
from loss import DistillationLoss, AttentionTransferLoss


class Trainer:
    def __init__(self, device='cuda' if torch.cuda.is_available() else 'cpu'):
        self.device = device
        self.student_model = LeNet5().to(device)
        self.teacher_model = SimpleResNetTeacher().to(device)

    # ----------------- 轻量增强（Tensor级） -----------------
    def rand_augment(self, x):
        # x: (B,1,H,W) float in [0,1] or normalized
        if not x.requires_grad:
            # 随机平移/裁剪: pad=2 后随机裁32×32
            x = F.pad(x, (2,2,2,2), mode='reflect')
            H, W = x.shape[-2:]
            top = random.randint(0, H-32)
            left = random.randint(0, W-32)
            x = x[..., top:top+32, left:left+32]
            # 小角度旋转（-10°~10°）
            if random.random() < 0.5:
                angle = (random.random()*20 - 10.0) * math.pi/180.0
                theta = torch.tensor([[math.cos(angle), -math.sin(angle), 0.0],
                                      [math.sin(angle),  math.cos(angle), 0.0]],
                                     device=x.device, dtype=x.dtype).unsqueeze(0).repeat(x.size(0),1,1)
                grid = F.affine_grid(theta, x.size(), align_corners=False)
                x = F.grid_sample(x, grid, mode='bilinear', padding_mode='border', align_corners=False)
        return x

    # ----------------- 评估 -----------------
    def evaluate(self, model, test_loader, device):
        model.eval()
        correct = total = 0
        with torch.no_grad():
            for images, labels in test_loader:
                images, labels = images.to(device), labels.to(device)
                outputs = model(images)
                _, predicted = outputs.max(1)
                correct += (predicted == labels).sum().item()
                total   += labels.size(0)
        return 100.0 * correct / total

    # ----------------- 教师训练（稳健设置） -----------------
    def train_teacher(self, train_loader, test_loader, device, epochs=30):
        teacher = SimpleResNetTeacher().to(device)
        opt = optim.SGD(teacher.parameters(), lr=0.05, momentum=0.9, weight_decay=5e-4, nesterov=True)
        # 线性warmup 3 epoch + 余弦退火
        def lr_schedule(ep):
            if ep < 3:
                return (ep+1)/3.0
            t = (ep-3)/(epochs-3)
            return 0.5*(1+math.cos(math.pi*t))
        criterion = nn.CrossEntropyLoss(label_smoothing=0.05)

        best = 0.0
        for ep in range(epochs):
            teacher.train()
            total_loss = correct = total = 0
            for images, labels in tqdm(train_loader, desc=f"Teacher {ep+1}/{epochs}"):
                images, labels = images.to(device), labels.to(device)
                images = self.rand_augment(images)

                opt.zero_grad(set_to_none=True)
                logits = teacher(images)
                loss = criterion(logits, labels)
                loss.backward()
                opt.step()

                total_loss += loss.item()
                pred = logits.argmax(1)
                correct += (pred==labels).sum().item()
                total   += labels.size(0)
            for g in opt.param_groups:
                g['lr'] = 0.05 * lr_schedule(ep)

            test_acc = self.evaluate(teacher, test_loader, device)
            print(f"Teacher Epoch {ep+1}: train_loss={total_loss/len(train_loader):.4f} | test_acc={test_acc:.2f}%")
            if test_acc > best:
                best = test_acc
                torch.save(teacher.state_dict(), 'best_teacher.pth')
        return teacher, best

    # ----------------- 在线蒸馏（α/T 调度 + 置信度加权） -----------------
    def train_student_kd(self, train_loader, test_loader, teacher, device, epochs=60, alpha_start=0.3, alpha_end=0.9, T_start=8.0, T_end=3.0):
        student = LeNet5().to(device)
        opt = optim.AdamW(student.parameters(), lr=2e-3, weight_decay=1e-4)
        def lr_schedule(ep):
            if ep < 3:
                return (ep+1)/3.0
            t = (ep-3)/(epochs-3)
            return 0.5*(1+math.cos(math.pi*t))
        kd = DistillationLoss(temperature=T_start, alpha=alpha_start, label_smoothing=0.05)

        best = 0.0
        for ep in range(epochs):
            progress = ep/(epochs-1) if epochs > 1 else 1.0
            alpha = alpha_start + (alpha_end-alpha_start)*progress
            T     = T_start - (T_start - T_end)*progress

            for g in opt.param_groups:
                g['lr'] = 2e-3 * lr_schedule(ep)

            student.train(); teacher.eval()
            tot=hard=soft=0.0; correct=total=0
            for images, labels in tqdm(train_loader, desc=f"KD {ep+1}/{epochs} (α={alpha:.2f},T={T:.1f})"):
                images, labels = images.to(device), labels.to(device)
                images = self.rand_augment(images)

                with torch.no_grad():
                    t_logits = teacher(images)
                    t_probs = torch.softmax(t_logits / T, dim=1)
                    t_conf, _ = t_probs.max(dim=1)

                s_logits = student(images)
                loss, hard_loss, soft_loss = kd(s_logits, labels, t_logits,
                                                alpha=alpha, temperature=T)

                opt.zero_grad(set_to_none=True)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(student.parameters(), 1.0)
                opt.step()

                tot  += loss.item()
                hard += hard_loss.item()
                soft += soft_loss.item()

                pred = s_logits.argmax(1)
                correct += (pred==labels).sum().item()
                total   += labels.size(0)

            test_acc = self.evaluate(student, test_loader, device)
            print(f"KD Epoch {ep+1}: total={tot/len(train_loader):.4f} | hard={hard/len(train_loader):.4f} "
                  f"| soft={soft/len(train_loader):.4f} | test_acc={test_acc:.2f}%")

            if test_acc > best:
                best = test_acc
                torch.save(student.state_dict(), 'best_student.pth')
        return best

    def train_student_normal(self, train_loader, test_loader, device, epochs=6):
        student = LeNet5().to(device)
        opt = optim.AdamW(student.parameters(), lr=1.5e-3, weight_decay=1e-4)
        def lr_schedule(ep):
            if ep < 3:
                return (ep+1)/3.0
            t = (ep-3)/(epochs-3)
            return 0.5*(1+math.cos(math.pi*t))
        criterion = nn.CrossEntropyLoss(label_smoothing=0.05)

        best=0.0
        for ep in range(epochs):
            for g in opt.param_groups:
                g['lr'] = 1.5e-3 * lr_schedule(ep)

            student.train()
            total_loss=correct=total=0
            for images, labels in tqdm(train_loader, desc=f"Normal {ep+1}/{epochs}"):
                images, labels = images.to(device), labels.to(device)
                images = self.rand_augment(images)

                logits = student(images)
                loss = criterion(logits, labels)

                opt.zero_grad(set_to_none=True)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(student.parameters(), 1.0)
                opt.step()

                total_loss += loss.item()
                pred = logits.argmax(1)
                correct += (pred==labels).sum().item()
                total   += labels.size(0)
            test_acc = self.evaluate(student, test_loader, device)
            print(f"Normal Epoch {ep+1}: loss={total_loss/len(train_loader):.4f} | test_acc={test_acc:.2f}%")
            if test_acc > best:
                best = test_acc
                torch.save(student.state_dict(), 'best_student_normal.pth')
        return best

# ----------------- 主流程 -----------------
def main():
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")

    train_loader, test_loader = get_data_loaders(batch_size=128)

    trainer = Trainer(device)  # ← 实例化

    # 调用成员函数
    teacher, teacher_acc = trainer.train_teacher(train_loader, test_loader, device, epochs=30)
    kd_acc = trainer.train_student_kd(train_loader, test_loader, teacher, device,epochs=60, alpha_start=0.3, alpha_end=0.9, T_start=8.0, T_end=3.0)
    normal_acc = trainer.train_student_normal(train_loader, test_loader, device, epochs=60)

    print(f"Teacher Model (ResNet) Accuracy:          {teacher_acc:6.2f}%")
    print(f"Student with Optimized Distillation:      {kd_acc:6.2f}%")
    print(f"Student Normal Training:                  {normal_acc:6.2f}%")
    print(f"DISTILLATION IMPROVEMENT:                 {kd_acc - normal_acc:+6.2f}%")



if __name__ == "__main__":
    main()
