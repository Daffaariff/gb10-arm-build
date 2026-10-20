#!/bin/bash
# GB10: avatar-stage (MuseTalk live avatar) + MuseTalk weights + avatars prepared on the x86 box (uploaded to /root/up).
set -euxo pipefail
P="uv pip install --python /opt/musetalk/bin/python"
$P fastapi uvicorn python-multipart livekit livekit-api "huggingface_hub[cli]" gdown
mkdir -p /opt/avatar-stage-src && tar xzf /root/up/avatar-stage.tgz -C /opt/avatar-stage-src && ln -sfn /opt/avatar-stage-src/avatar-stage /opt/avatar-stage
M=/opt/MuseTalk/models; mkdir -p /workspace/musetalk-models && rm -rf $M && ln -sfn /workspace/musetalk-models $M
H=/opt/musetalk/bin/huggingface-cli
[ -f $M/musetalkV15/unet.pth ] || $H download TMElyralab/MuseTalk --local-dir $M --include "musetalk/musetalk.json" "musetalk/pytorch_model.bin" "musetalkV15/musetalk.json" "musetalkV15/unet.pth" >/dev/null
[ -f $M/sd-vae/diffusion_pytorch_model.bin ] || $H download stabilityai/sd-vae-ft-mse --local-dir $M/sd-vae --include config.json diffusion_pytorch_model.bin >/dev/null
[ -f $M/whisper/pytorch_model.bin ] || $H download openai/whisper-tiny --local-dir $M/whisper --include config.json pytorch_model.bin preprocessor_config.json >/dev/null
mkdir -p $M/face-parse-bisent
[ -f $M/face-parse-bisent/79999_iter.pth ] || /opt/musetalk/bin/gdown -q 154JgKpzCPW82qINcVieuPH3fZ2e0P812 -O $M/face-parse-bisent/79999_iter.pth
[ -f $M/face-parse-bisent/resnet18-5c106cde.pth ] || curl -sL https://download.pytorch.org/models/resnet18-5c106cde.pth -o $M/face-parse-bisent/resnet18-5c106cde.pth
# prepared avatars (frames, latents, masks) from the box; media paths rewritten to the GB10 layout
mkdir -p /workspace/avatar-media /workspace/zc-cache && cd /workspace/avatar-media && tar xf /root/up/rex_avatar.tar
mkdir -p /opt/MuseTalk/results/v15/avatars && cp -rn /workspace/avatar-media/MuseTalk/results/v15/avatars/. /opt/MuseTalk/results/v15/avatars/
cp -n /workspace/avatar-media/zc-cache/* /workspace/zc-cache/ 2>/dev/null || cp -rn /workspace/avatar-media/zc-cache/. /workspace/zc-cache/
sed 's#~/daffa/musetalk-test/#/workspace/avatar-media/#g' /root/up/avatars_gb10.json > /workspace/avatars.json
mkdir -p /models/voices && cp /root/up/*.wav /models/voices/ 2>/dev/null || true
cd /opt/MuseTalk && /opt/musetalk/bin/python -c "
import sys; sys.path.insert(0, '/opt/avatar-stage')
import avatar_stage, fastapi
try:
    import PyNvVideoCodec; print('zero-copy available')
except Exception as e: print('zero-copy NOT available:', type(e).__name__)
print('avatar-stage ok')"
