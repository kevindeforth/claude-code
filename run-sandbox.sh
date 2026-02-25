#!/usr/bin/env bash
set -euo pipefail

IMAGE=claude-dev-sandbox
BUILD=false

for arg in "$@"; do
  if [[ "$arg" == "--build" ]]; then
    BUILD=true
  fi
done

if [[ "$BUILD" == true ]]; then
  docker build \
      -f ~/personal-repositories/claude-code/.devcontainer/Dockerfile \
      -t "$IMAGE" \
      --build-arg TZ="${TZ:-Asia/Dubai}" \
      --build-arg CLAUDE_CODE_VERSION=latest \
      --build-arg GIT_DELTA_VERSION=0.18.2 \
      --build-arg ZSH_IN_DOCKER_VERSION=1.2.0 \
      ~/personal-repositories/claude-code/.devcontainer
fi

docker run --rm -it \
    --name claude-sandbox-test \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    -e DEVCONTAINER=true \
    -e NODE_OPTIONS="--max-old-space-size=4096" \
    -e CLAUDE_CONFIG_DIR="/home/node/.claude" \
    -e POWERLEVEL9K_DISABLE_GITSTATUS="true" \
    -v "$PWD":/workspace \
    -v claude-code-config-test:/home/node/.claude \
    -v claude-code-bashhistory-test:/commandhistory \
    -w /workspace \
    "$IMAGE" \
    zsh
