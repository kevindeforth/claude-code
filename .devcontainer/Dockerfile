FROM node:20

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  make \
  curl \
  libssl-dev \
  pkg-config \
  clang \
  llvm \
  libclang-dev \
  libudev-dev \
  libdbus-1-dev \
  liblz4-dev \
  libzstd-dev \
  libbz2-dev \
  libsnappy-dev \
  zlib1g-dev \
  binaryen \
  python3 \
  python3-pip \
  python3-keyring \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history.
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.bash_history \
  && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# --- Rust toolchain (global install) ---
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path \
        --default-toolchain 1.87.0 \
        --component rustfmt,clippy,rust-analyzer,rust-src \
        --target wasm32-unknown-unknown && \
    /usr/local/cargo/bin/rustup toolchain install 1.86.0 \
        --component rustfmt,clippy,rust-analyzer,rust-src \
        --target wasm32-unknown-unknown && \
    chown -R node:node /usr/local/rustup /usr/local/cargo

# Bake NEAR/Rust build env vars into the image using detected clang paths
RUN CLANG_RESOURCE_DIR=$(clang -print-resource-dir) && \
    LLVM_LIB=$(dirname "$CLANG_RESOURCE_DIR") && \
    cat >> /etc/zsh/zshenv <<EOF
# NEAR/Rust build environment
export LIBCLANG_PATH=${LLVM_LIB}
export CC_wasm32_unknown_unknown=/usr/bin/clang
export AR_wasm32_unknown_unknown=/usr/bin/llvm-ar
export CFLAGS_wasm32_unknown_unknown="-I${CLANG_RESOURCE_DIR}/include"
export BINDGEN_EXTRA_CLANG_ARGS="-I${CLANG_RESOURCE_DIR}/include -I/usr/include"
export OPENSSL_NO_VENDOR=1
export CXXFLAGS="-include cstdint -msse4.2 -mpclmul"
EOF

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Default powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# --- Cargo tools via cargo-binstall (pre-built binaries, falls back to source) ---
RUN curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

RUN cargo binstall -y \
    cargo-nextest \
    cargo-insta \
    cargo-make@0.37.24 \
    cargo-deny@0.19.0 \
    cargo-shear@1.9.1 \
    cargo-sort@2.0.2 \
    cargo-about@0.8.4 \
    git-cliff@2.12.0 \
    zizmor@1.22.0 \
    lychee@0.23.0 \
    near-cli-rs@0.23.6

# cargo-near has no pre-built binary; use --locked to pin deps to its published Cargo.lock
RUN cargo install --locked cargo-near@0.19.1

# Python linter
RUN pip3 install --break-system-packages ruff

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node
