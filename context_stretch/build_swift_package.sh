#!/bin/bash

set -euo pipefail

usage() {
	echo "usage: $0 [--static] git_url[=treeish_object] [build_dependency1, build_dependency2, ...]" >/dev/stderr
	echo "note: The static option might not work on Linux." >/dev/stderr
	exit 1
}

readonly REPO_FOLDER_NAME="built_repo"
readonly REPO_FOLDER_PATH="${OUTPUT_PATH}/${REPO_FOLDER_NAME}"
readonly BUILD_FOLDER_NAME=".build"

# Parse the arguments
static=0
static_option="--no-static-swift-stdlib"
if [ "${1:-}" = "--static" ]; then
	static=1
	static_option="--static-swift-stdlib"
	echo "warning: Statically linking the Swift stdlibs might not work on Linux." >/dev/stderr
	shift
fi

url_and_treeish="${1:-}"
if [ -z "$url_and_treeish" ]; then
	usage
fi
shift

# Parse the URL/Treeish argument
url=${url_and_treeish%=*}
treeish=${url_and_treeish##*=}
# Previous way of parsing the arguments (working but not elegant, and not efficient)
#url="$(cut -d= -f1 <<<"$url_and_treeish")"
#treeish="$(cut -d= -f2 <<<"$url_and_treeish")"
if [ "$treeish" = "$url" ]; then treeish=; fi; # If there are no "=" in the string, bash (or cut) will return the full string instead of an empty string…

# Install the required build dependencies
if [ -n "${1:-}" ]; then
	apt-get update
	apt-get install -y --no-install-recommends "$@"
fi

# Clone the project and checkout the requested treeish object
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
if [ ! -e "$REPO_FOLDER_PATH" ]; then
	git clone "$url" "$REPO_FOLDER_PATH"
	cd "$REPO_FOLDER_PATH"
else
	# If the repo already exists, we assume it’s the one we want
	cd "$REPO_FOLDER_PATH"
	git remote update
	git merge || true; # If the repo is currently on a branch that has an upstream, merge it
fi
if [ -n "$treeish" ]; then
	git fetch --tags
	git checkout "$treeish"
fi
git submodule update --init --recursive

# Compile the project
swift build $static_option -c release --build-path "${BUILD_FOLDER_NAME}"

# Copying the Swift debs
mkdir -p "${OUTPUT_PATH}/products/swift_debs"
cp -f "${DEBS_FOLDER}"/* "${OUTPUT_PATH}/products/swift_debs/"
# Creating a link to the release folder in the output path
rm -f "${OUTPUT_PATH}/products/release"
ln -sf "../${REPO_FOLDER_NAME}/${BUILD_FOLDER_NAME}/release" "${OUTPUT_PATH}/products/release"
# Creating an archive of the release folder in the output path
rm -f "${OUTPUT_PATH}/products/release.tar.bz2"
tar --transform 's:^release/::g' -C "${BUILD_FOLDER_NAME}" -czhf "${OUTPUT_PATH}/products/release.tar.gz" release/

echo
echo "***** ALL DONE"
echo "Path to Swift debs (you should only need the libs one): <OUTPUT_PATH>/products/swift_debs/"
echo "Path to built product folder: <OUTPUT_PATH>/products/release/"
echo "Path to built product archive: <OUTPUT_PATH>/products/release.tar.gz"
