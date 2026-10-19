#!/bin/bash
# GB10 (aarch64, sm_121): Leo's live avatar env, same packages as akool-recipe Dockerfile. Run as root.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y --no-install-recommends python3 python3-dev python3-venv python3-pip git wget curl ffmpeg \
  libgl1 libglib2.0-0 libsndfile1 ninja-build build-essential nginx cmake
python3 -m venv /opt/avatar && P=/opt/avatar/bin/pip
$P install --upgrade pip "setuptools<70" wheel
$P install torch==2.11.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
$P install --no-build-isolation git+https://github.com/NVlabs/nvdiffrast.git@v0.3.3
$P install "numpy<2.3" scipy opencv-python-headless kornia trimesh scikit-image "mediapipe==0.10.21" librosa praat-parselmouth \
  pyworld pyloudnorm einops "transformers==4.46.3" webrtcvad-wheels "moviepy==1.0.3" python_speech_features resampy imageio-ffmpeg \
  textgrid pyfacer websockets av tensorboard "huggingface_hub[cli]"
mkdir -p /content /ffbin && ln -sf /usr/bin/ffmpeg /ffbin/ffmpeg && ln -sf /usr/bin/ffprobe /ffbin/ffprobe
cd /content
[ -d Deep3DFaceRecon_pytorch ] || git clone -q --depth 1 https://github.com/sicxu/Deep3DFaceRecon_pytorch
[ -d Deep3DFaceRecon_pytorch/models/arcface_torch ] || { git clone -q --depth 1 https://github.com/deepinsight/insightface /tmp/insightface \
  && cp -r /tmp/insightface/recognition/arcface_torch Deep3DFaceRecon_pytorch/models/ && rm -rf /tmp/insightface; }
[ -d Real3DPortrait ] || git clone -q --depth 1 https://github.com/yerfor/Real3DPortrait
/opt/avatar/bin/python -c "import torch, nvdiffrast.torch, av, websockets, facer, kornia, mediapipe, transformers, parselmouth; print('avatar ok', torch.__version__)"
