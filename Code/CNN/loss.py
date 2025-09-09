import torch
import torch.nn as nn
import torch.nn.functional as F

class DistillationLoss(nn.Module):
    def __init__(self, temperature=4.0, alpha=0.5, label_smoothing=0.05):
        super().__init__()
        self.temperature = float(temperature)
        self.alpha = float(alpha)
        self.label_smoothing = float(label_smoothing)

    def forward(self, student_logits, hard_labels, teacher_logits,
                alpha=None, temperature=None, sample_weights=None):
        T = float(temperature) if temperature is not None else self.temperature
        a = float(alpha) if alpha is not None else self.alpha

        # ----- Hard loss (per-sample) -----
        ce = F.cross_entropy(student_logits, hard_labels,
                             reduction='none',
                             label_smoothing=self.label_smoothing)  # (B,)

        # ----- Soft loss (per-sample KL) -----
        log_p_s = F.log_softmax(student_logits / T, dim=1)            # (B,C)
        with torch.no_grad():
            p_t = F.softmax(teacher_logits / T, dim=1)                # (B,C)
        kl_per_class = F.kl_div(log_p_s, p_t, reduction='none')       # (B,C)
        kl = kl_per_class.sum(dim=1) * (T * T)                        # (B,)

        # ----- weighting & reduction -----
        if sample_weights is not None:
            w = sample_weights.detach().float()
            w = w / (w.mean() + 1e-8)  # 归一到约1的尺度，稳定优化
            ce = (ce * w).mean()
            kl = (kl * w).mean()
        else:
            ce = ce.mean()
            kl = kl.mean()

        total = a * ce + (1.0 - a) * kl
        return total, ce, kl


class AttentionTransferLoss(nn.Module):
    def __init__(self, eps: float = 1e-8):
        super().__init__()
        self.eps = eps
        self.mse = nn.MSELoss()

    def spatial_attention(self, feat: torch.Tensor) -> torch.Tensor:
        # feat: B×C×H×W -> B×1×H×W
        att = (feat ** 2).sum(dim=1, keepdim=True)
        # 归一化到 [0,1]
        norm = torch.norm(att.flatten(1), p=2, dim=1, keepdim=True) + self.eps
        att = att / norm.view(-1, 1, 1, 1)
        return att

    def forward(self, student_feat: torch.Tensor, teacher_feat: torch.Tensor) -> torch.Tensor:
        As = self.spatial_attention(student_feat)
        At = self.spatial_attention(teacher_feat)
        # 自适应池化到学生的空间大小
        if As.shape[-2:] != At.shape[-2:]:
            At = F.adaptive_avg_pool2d(At, As.shape[-2:])
        return self.mse(As, At)
