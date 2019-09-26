#!/bin/bash

set -e
readonly VERSION="${1:-5.1-RELEASE}"

cd "$(dirname "$0")"

# Compiling Swift requires the SYS_PTRACE capability because Swift’s REPL uses
# it, and some tests run the REPL. Docker needs to support seccomp to be able to
# add this capability to the containers.
test "$(grep CONFIG_SECCOMP= /boot/config-$(uname -r))" = "CONFIG_SECCOMP=y" || { echo "System does not support seccomp; cannot build Swift."; exit 1; }

docker pull debian:stretch-slim
docker build --build-arg SWIFT_TAG="$VERSION" -t "swift-builder:$VERSION" context_stretch

echo
echo
echo
echo "All done. You can manually tag the temporary image (e.g. name it “swift-built:$VERSION”) or delete it."
echo "To use the REPL inside a container based from the image, you’ll have to run it with --security-opt=seccomp:unconfined"
