#!/bin/bash
# GB10: llama.cpp server with CUDA for sm_120 (runs on GB10 sm_121).
set -euxo pipefail
[ -x /usr/local/bin/llama-server ] && exit 0
S=/usr/local/cuda/lib64/stubs; [ -e $S/libcuda.so.1 ] || ln -sf $S/libcuda.so $S/libcuda.so.1
git clone -q --depth 1 https://github.com/ggml-org/llama.cpp /tmp/llama && cd /tmp/llama
cmake -B b -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=120 -DLLAMA_CURL=OFF \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link,/usr/local/cuda/lib64/stubs -L/usr/local/cuda/lib64/stubs"
cmake --build b -j"${JOBS:-4}" --target llama-server
cp b/bin/llama-server /usr/local/bin/ && cp b/bin/*.so* /usr/local/lib/ && ldconfig && rm -rf /tmp/llama
llama-server --version || true
