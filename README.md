# gb10-arm-build

Install scripts for an NVIDIA GB10 (DGX Spark, arm64, sm_121) machine, tested on GitHub's arm64 runners (no GPU: install/compile only).

| Script | What |
|---|---|
| `install_avatar.sh` | PyTorch 2.11 cu128 + nvdiffrast + avatar server deps in `/opt/avatar` |
| `install_llm.sh` | llama.cpp server with CUDA |
| `install_stt.sh` | faster-whisper + SenseVoice venv in `/opt/stt` |
| `install_tts.sh` | VoxCPM2 (nano-vllm) + flash-attn built from source in `/opt/tts` |

Run as root on the machine: `bash install_<part>.sh`.
