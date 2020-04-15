#!/bin/bash
set -euo pipefail

readonly SKIP_GCP_PULL=0
readonly SKIP_DOCKER_PULL=0
readonly OUTPUT_FILE="images_versions.csv"


cd "$(dirname "$0")/.."

test ! -e "$OUTPUT_FILE" || { echo "$OUTPUT_FILE already exist, please delete before running this script"; exit 1; }
touch "$OUTPUT_FILE"


readonly GCP_BASE_REGISTRY="$(cat "$HOME/.config/swift-docker/gcp-base-registry.txt")"
test -n "$GCP_BASE_REGISTRY"; # readonly shadows the error, if any, so let’s check if we got a value…


readonly GCR_REPOS=("$GCP_BASE_REGISTRY/swift" "$GCP_BASE_REGISTRY/swift-builder")
readonly DOCKER_REPOS=("happn/swift" "happn/swift-builder")


if [ "$SKIP_GCP_PULL" = "0" ]; then
	for repo in "${GCR_REPOS[@]}"; do
		gcloud container images list-tags "$repo" --format json | jq '[.[].tags[]]' | jq -r .[] | \
			while read t; do
				docker pull "$repo:$t"
			done
	done
fi

if [ "$SKIP_DOCKER_PULL" = "0" ]; then
	readonly DOCKER_CREDS="$(cat "$HOME/.config/swift-docker/docker-creds.txt")"
	test -n "$DOCKER_CREDS"; # readonly shadows the error, if any, so let’s check if we got a value…
	
	for repo in "${DOCKER_REPOS[@]}"; do
		DOCKER_ACCESS_TOKEN="$(curl -sL -H"Basic: $DOCKER_CREDS" \
			"https://auth.docker.io/token?service=registry.docker.io&scope=repository:$repo:pull" | \
			jq -r .token
		)"
		test "$DOCKER_ACCESS_TOKEN" != "null" -a -n "$DOCKER_ACCESS_TOKEN"
	
		curl -sL -H"Authorization: Bearer $DOCKER_ACCESS_TOKEN" "https://registry.hub.docker.com/v2/$repo/tags/list" | \
			jq -r .tags[] | \
			while read t; do
				docker pull "$repo:$t"
			done
	done
fi


echo "Digest,Repository,Tag,Swift Version,Cmd,Entrypoint" >>"$OUTPUT_FILE"
for repo in "${DOCKER_REPOS[@]}" "${GCR_REPOS[@]}"; do
	# We assume (and are pretty sure) the pipe character is invalid in a tag name
	# and always will be.
	for tag_and_digest in $(docker images --format "{{.Tag}}|{{.Digest}}" "$repo"); do
		tag=${tag_and_digest%|*}
		digest=${tag_and_digest##*|}
		cmd="\"$(docker inspect "$repo:$tag" | jq -r ".[0].Config.Cmd"               | sed -E -e 's/"/""/g' -e 's/$/   /g' | tr -d '\n' | tr -d '\r')\""
		version="\"$(docker run -it --rm --entrypoint swift "$repo:$tag" --version   | sed -E -e 's/"/""/g' -e 's/$/   /g' | tr -d '\n' | tr -d '\r')\""
		entrypoint="\"$(docker inspect "$repo:$tag" | jq -r ".[0].Config.Entrypoint" | sed -E -e 's/"/""/g' -e 's/$/   /g' | tr -d '\n' | tr -d '\r')\""
		echo "$digest,$repo,$tag,$version,$cmd,$entrypoint" >>"$OUTPUT_FILE"
	done
done
