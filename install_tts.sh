#!/bin/bash
# GB10: VoxCPM2 TTS venv. NOTE: uses the known-good DGX Spark stack (py3.12, torch 2.12 cu130, prebuilt flash-attn 2.8.3); falls back to a source build.
set -euxo pipefail
pip3 install -q uv 2>/dev/null || pip3 install -q --break-system-packages uv
uv venv /opt/tts --python 3.12
P="uv pip install --python /opt/tts/bin/python"
$P --extra-index-url https://download.pytorch.org/whl/cu130 torch==2.12.0+cu130 torchaudio triton==3.7.0 packaging ninja psutil
$P https://huggingface.co/N8Programs/dgx-flash-attn-wheel/resolve/main/flash_attn-2.8.3.post1-cp312-cp312-linux_aarch64.whl \
  || TORCH_CUDA_ARCH_LIST="12.0" MAX_JOBS=${MAX_JOBS:-8} $P --no-build-isolation "flash-attn==2.8.3.post1"
$P nano-vllm-voxcpm "fastapi[standard]" soundfile "numpy<2"
# NOTE: libcuda comes from the driver; on a GPU-less CI runner the stub lets the import check load
S=/usr/local/cuda/lib64/stubs; [ -e /usr/lib/aarch64-linux-gnu/libcuda.so.1 ] || { [ -e $S/libcuda.so.1 ] || ln -sf $S/libcuda.so $S/libcuda.so.1; export LD_LIBRARY_PATH=$S:${LD_LIBRARY_PATH:-}; }
/opt/tts/bin/python -c "import torch, flash_attn, nanovllm_voxcpm; print('tts ok', torch.__version__, flash_attn.__version__)"
