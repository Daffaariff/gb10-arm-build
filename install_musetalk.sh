#!/bin/bash
# GB10: MuseTalk runtime for avatar-stage (no face-prep tools: avatars are prepared on the x86 box and copied).
set -euxo pipefail
pip3 install -q uv 2>/dev/null || pip3 install -q --break-system-packages uv
uv venv /opt/musetalk --python 3.11
P="uv pip install --python /opt/musetalk/bin/python"
$P --index-url https://download.pytorch.org/whl/cu130 torch==2.12.0 torchvision torchaudio
$P "diffusers==0.30.2" "accelerate==0.28.0" "transformers==4.39.2" einops omegaconf opencv-python-headless soundfile librosa \
  ffmpeg-python imageio av "mediapipe==0.10.18" fastapi uvicorn python-multipart "numpy<2" gdown
$P "huggingface_hub==0.30.2"
# NOTE: NVENC zero-copy path; optional, avatar-stage falls back to ffmpeg encode without it
$P "PyNvVideoCodec==2.2.3" || echo "WARN no PyNvVideoCodec for this platform"
[ -d /opt/MuseTalk ] || git clone -q --depth 1 https://github.com/TMElyralab/MuseTalk.git /opt/MuseTalk
cd /opt/MuseTalk && /opt/musetalk/bin/python -c "
import torch, diffusers, transformers, cv2, av, soundfile, librosa
from diffusers import AutoencoderKL
from transformers import WhisperModel
from musetalk.models.unet import UNet
from musetalk.models.vae import VAE
try:
    import PyNvVideoCodec; nv = 'yes'
except Exception as e: nv = 'no (' + type(e).__name__ + ')'
print('musetalk ok', torch.__version__, 'diffusers', diffusers.__version__, '| PyNvVideoCodec:', nv)"
