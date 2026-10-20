#!/bin/bash
# GB10: CTranslate2 with CUDA 13 + cuDNN for sm_121 (PyPI arm64 wheels are CPU-only), installed into /opt/stt.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive C=/usr/local/cuda-13.0; export PATH=$C/bin:$PATH CUDA_HOME=$C
# NOTE: torch cu130 in /opt/stt ships cuDNN 9 for CUDA 13; CT2 builds and runs against that copy
uv pip install --python /opt/stt/bin/python --index-url https://download.pytorch.org/whl/cu130 torch==2.12.0
uv pip install --python /opt/stt/bin/python --reinstall-package torchaudio --index-url https://download.pytorch.org/whl/cu130 torchaudio==2.11.0
D=$(/opt/stt/bin/python -c "import nvidia.cudnn; print(list(nvidia.cudnn.__path__)[0])")
ln -sf $D/lib/libcudnn.so.9 $D/lib/libcudnn.so
echo "$D/lib" > /etc/ld.so.conf.d/stt-cudnn.conf && ldconfig
if [ -f /root/up/gb10_built.tgz ]; then
  tar xzf /root/up/gb10_built.tgz -C / && ldconfig
  uv pip install --python /opt/stt/bin/python --force-reinstall --no-deps /tmp/ct2/python/dist/*.whl
else
V=$(/opt/stt/bin/python -c "import ctranslate2;print(ctranslate2.__version__)")
rm -rf /tmp/ct2 && git clone -q --recursive --depth 1 --branch v$V https://github.com/OpenNMT/CTranslate2.git /tmp/ct2 && cd /tmp/ct2
cmake -B build -DWITH_CUDA=ON -DWITH_CUDNN=ON -DCUDA_ARCH_LIST="9.0+PTX" -DWITH_MKL=OFF -DOPENMP_RUNTIME=COMP -DCMAKE_BUILD_TYPE=Release \
  -DCUDA_TOOLKIT_ROOT_DIR=$C -DCUDNN_INCLUDE_DIR=$D/include -DCUDNN_LIBRARIES=$D/lib/libcudnn.so -DCMAKE_CUDA_COMPILER=$C/bin/nvcc
cmake --build build -j"$(nproc)" && cmake --install build && ldconfig
cd python && uv pip install --python /opt/stt/bin/python -r install_requirements.txt && /opt/stt/bin/python setup.py bdist_wheel -q
uv pip install --python /opt/stt/bin/python --force-reinstall --no-deps dist/*.whl
fi
cd / && /opt/stt/bin/python -c "import ctranslate2; print('ct2 gpu devices', ctranslate2.get_cuda_device_count())"
