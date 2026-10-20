#!/bin/bash
# GB10: cloudflared (arm64) for https/wss without inbound ports.
set -euxo pipefail
[ -x /usr/local/bin/cloudflared ] || { curl -sfL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /usr/local/bin/cloudflared && chmod +x /usr/local/bin/cloudflared; }
cloudflared --version
