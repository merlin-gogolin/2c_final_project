import torch
import torch.nn as nn
import onnx
import pandas as pd

print(f"PyTorch Version: {torch.__version__}")
print(f"CUDA Available: {torch.cuda.is_available()}")

# Test the weight_norm used in networks.py
try:
    from torch.nn.utils import weight_norm
    test_layer = weight_norm(nn.Linear(10, 10))
    print("Environment check passed: weight_norm and dependencies are ready.")
except Exception as e:
    print(f"Environment check failed: {e}")