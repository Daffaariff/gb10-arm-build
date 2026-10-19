#!/bin/bash
# GB10: VoxCPM2 TTS venv. NOTE: no aarch64 flash-attn wheel; built from source (slow, MAX_JOBS bounds RAM).
set -euxo pipefail
pip3 install -q uv 2>/dev/null || pip3 install -q --break-system-packages uv
uv venv /opt/tts --python 3.11
uv pip install --python /opt/tts/bin/python --index-url https://download.pytorch.org/whl/cu128 torch torchaudio
uv pip install --python /opt/tts/bin/python packaging ninja wheel setuptools psutil
TORCH_CUDA_ARCH_LIST="12.0" MAX_JOBS=1 NVCC_THREADS=1 uv pip install --python /opt/tts/bin/python --no-build-isolation "flash-attn==2.7.4.post1"
uv pip install --python /opt/tts/bin/python nano-vllm-voxcpm "fastapi[standard]" soundfile "numpy<2"
/opt/tts/bin/python -c "import torch, flash_attn, nanovllm_voxcpm; print('tts ok', torch.__version__)"
