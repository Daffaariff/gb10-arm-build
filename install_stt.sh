#!/bin/bash
# GB10: STT venv (faster-whisper + SenseVoice). NOTE: ctranslate2 aarch64 wheels may be CPU-only; check prints the device count.
set -euxo pipefail
pip3 install -q uv 2>/dev/null || pip3 install -q --break-system-packages uv
uv venv /opt/stt --python 3.11
uv pip install --python /opt/stt/bin/python --index-url https://download.pytorch.org/whl/cu128 torch torchaudio
uv pip install --python /opt/stt/bin/python faster-whisper==1.1.1 funasr==1.2.6 "fastapi[standard]" python-multipart huggingface_hub opencc-python-reimplemented setuptools
/opt/stt/bin/python -c "import ctranslate2, funasr, torch; print('stt ok ct2 cuda devices', ctranslate2.get_cuda_device_count(), 'torch', torch.__version__)"
