#!/usr/bin/env bash
set -euo pipefail

IMAGE=claude-dev-sandbox
BUILD=false
CONTAINER_NAME="claude-sandbox-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$//')"

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

# ------------------------------------------------------------------
# Seed the .local volume from the image if claude is missing.
# Docker only auto-populates named volumes on their very first mount;
# if the volume predates the Claude install step in the Dockerfile
# (or a rebuild changed the contents), it stays stale forever.
# cp -an copies missing files only, so auto-updated Claude versions
# already on the volume are never overwritten.
# ------------------------------------------------------------------
if ! docker run --rm -v claude-code-local-test:/target "$IMAGE" \
    test -e /target/bin/claude >/dev/null 2>&1; then
    echo "Seeding claude-code-local-test volume from image..."
    docker run --rm -v claude-code-local-test:/target "$IMAGE" \
        sh -c 'cp -an /home/node/.local/. /target/'
fi

# Same pitfall for the /nix store volume: only seed when there is no working
# store (no nix db), e.g. the volume was created by a pre-nix image. Runs as
# root because such a volume's mountpoint is root-owned; cp -a preserves the
# node ownership baked into the image's store.
NIX_VOLUME="${CONTAINER_NAME}-nix"
if ! docker run --rm -v "$NIX_VOLUME":/target "$IMAGE" \
    test -e /target/var/nix/db/db.sqlite >/dev/null 2>&1; then
    echo "Seeding $NIX_VOLUME volume from image..."
    docker run --rm -u root -v "$NIX_VOLUME":/target "$IMAGE" \
        sh -c 'cp -an /nix/. /target/ && chown node:node /target'
fi

# --privileged is required for docker-in-docker (dockerd inside the sandbox)
docker run --rm -it \
    --name "$CONTAINER_NAME" \
    --privileged \
    -e DEVCONTAINER=true \
    -e NODE_OPTIONS="--max-old-space-size=4096" \
    -e CLAUDE_CONFIG_DIR="/home/node/.claude" \
    -e POWERLEVEL9K_DISABLE_GITSTATUS="true" \
    -e GH_TOKEN="$(cat ~/.config/claude-sandbox/gh-token 2>/dev/null || true)" \
    -v "$PWD":/workspace \
    -v claude-code-config-test:/home/node/.claude \
    -v claude-code-local-test:/home/node/.local \
    -v claude-code-bashhistory-test:/commandhistory \
    -v "${CONTAINER_NAME}-claude-docker":/var/lib/docker \
    -v "${CONTAINER_NAME}-nix":/nix \
    -w /workspace \
    "$IMAGE" \
    zsh -c 'sudo /usr/local/bin/init-firewall.sh && sudo /usr/local/bin/init-docker.sh; exec zsh'
