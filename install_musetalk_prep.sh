#!/bin/bash
# GB10: MuseTalk face-prep tools (mmcv built from source for CUDA 13 / arm64, mmpose for DWPose). Needs install_musetalk.sh first.
set -euxo pipefail
C=${CUDA_HOME:-$(ls -d /usr/local/cuda-13* 2>/dev/null | tail -1)}; C=${C:-/usr/local/cuda}; export CUDA_HOME=$C PATH=$C/bin:$PATH
P="uv pip install --python /opt/musetalk/bin/python"
$P openmim mmengine ninja psutil "setuptools<70" wheel packaging
# NOTE: no arm64/CUDA 13 mmcv wheel exists; MMCV_WITH_OPS=1 builds mmcv._ext (a plain pip install misses it on arm64)
rm -rf /tmp/mmcv && git clone -q --depth 1 --branch v2.1.0 https://github.com/open-mmlab/mmcv.git /tmp/mmcv && cd /tmp/mmcv
MMCV_WITH_OPS=1 FORCE_CUDA=1 TORCH_CUDA_ARCH_LIST="${ARCH:-12.0}" MAX_JOBS=${MAX_JOBS:-3} $P --no-build-isolation -e .
# NOTE: chumpy (mmpose dep) builds with pip but does not declare it
$P pip && $P --no-build-isolation chumpy
# NOTE: xtcocotools (mmpose dep) imports numpy at build time
$P --no-build-isolation xtcocotools
$P "mmpose==1.3.2" "mmdet==3.3.0" face-alignment
cd /opt/MuseTalk && /opt/musetalk/bin/python -c "
import mmcv, mmcv.ops, mmpose
from mmcv import _ext
from mmpose.apis import inference_topdown, init_model
print('musetalk prep ok', 'mmcv', mmcv.__version__, 'mmpose', mmpose.__version__)"
