Hi GPUwerk team,

We're evaluating a 1x DGX Spark instance to run a real-time AI avatar (an LLM, text-to-speech and speech-to-text on the GPU, plus a WebSocket video server). Before we deploy:

1. Inbound ports: which TCP ports on the instance's public IPv4 are reachable from the internet? We need 2 ports (e.g. 8000 HTTP and 8180 WebSocket). Are WebSocket upgrades passed through?
2. Which NVIDIA driver version and maximum CUDA version does the host provide? We plan to use CUDA 12.8 userspace (PyTorch cu128 aarch64 wheels).
3. How much disk is in /workspace, and can it be enlarged? We need about 80 GB for model weights.
4. Is anything outside /workspace (e.g. /opt, /usr/local, apt installs) kept across a stop/start, or only /workspace?
5. Is NVENC (hardware H.264 encode) available to the container?

Thanks!
