#!/bin/bash
set -euo pipefail

readonly VERSION_TO_CONVERT="$1"

# Let’s verify the converted image does not already exist
docker pull "happn/swift:$VERSION_TO_CONVERT" >/dev/null 2>&1 && { echo "Converted image already exist; bailing out" >/dev/null; exit 1; } || true

cat Dockerfile.base | sed -E "s&__HPN_IMAGE_NAME__&happn/swift-builder:$VERSION_TO_CONVERT&g" | docker build -f - -t "happn/swift:$VERSION_TO_CONVERT" .
