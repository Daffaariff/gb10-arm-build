#!/bin/bash
# GB10: LiveKit publisher (lkpub, Go) for avatar-stage's WebRTC path.
set -euxo pipefail
[ -x /usr/local/bin/lkpub ] && exit 0
[ -x /usr/local/go/bin/go ] || curl -sfL https://go.dev/dl/go1.23.4.linux-arm64.tar.gz | tar -C /usr/local -xz
D=$(cd "$(dirname "$0")" && pwd)/lkpub; cd "$D"
[ -f go.mod ] || /usr/local/go/bin/go mod init lkpub
/usr/local/go/bin/go mod tidy && /usr/local/go/bin/go build -o /usr/local/bin/lkpub .
file /usr/local/bin/lkpub; echo "lkpub ok"
