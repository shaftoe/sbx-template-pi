# sbx-template-pi — Pre-baked Docker Sandbox template for Pi coding agent
#
# Build args:
#   BASE_VARIANT  – shell | shell-docker  (default: shell-docker)
#   PI_VERSION    – npm version spec      (default: latest)
#
# Examples:
#   docker build -t sbx-template-pi .
#   docker build --build-arg BASE_VARIANT=shell -t sbx-template-pi:slim .
#   docker build --build-arg PI_VERSION=0.7.0 -t sbx-template-pi:pi-0.7.0 .

ARG BASE_VARIANT=shell-docker
ARG NODE_VERSION=22

# ---------------------------------------------------------------------------
# Stage 1: Install pi on the BUILD platform (no QEMU emulation).
# npm install runs natively — pi's node_modules are pure JS, so they're
# safe to copy into any target platform.
# ---------------------------------------------------------------------------

FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-bookworm-slim AS builder

ARG PI_VERSION=latest
ARG CACHE_BUST
RUN echo "cache bust: ${CACHE_BUST}" \
    && npm install -g "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

# ---------------------------------------------------------------------------
# Stage 2: Node runtime for the TARGET platform
# ---------------------------------------------------------------------------

FROM node:${NODE_VERSION}-bookworm-slim AS node-bin

# ---------------------------------------------------------------------------
# Stage 3: The actual sandbox image
# ---------------------------------------------------------------------------

FROM docker/sandbox-templates:${BASE_VARIANT}

ARG PI_VERSION=latest # renovate: datasource=npm depName=@earendil-works/pi-coding-agent

USER root

# Remove old Node.js bundled with the base image
RUN apt-get purge -y nodejs && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Upgrade all distro packages so we ship an up-to-date image
RUN apt-get update \
    && apt-get dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Copy Node runtime for the TARGET platform
COPY --from=node-bin /usr/local/bin/node /usr/bin/node
COPY --from=node-bin /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/npm
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Copy pi
COPY --from=builder /usr/local/lib/node_modules/@earendil-works /usr/local/lib/node_modules/@earendil-works
RUN ln -sf /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js /usr/local/bin/pi

RUN node --version && node /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --version

# Install fd-find so pi doesn't have to download it at first boot
RUN apt-get update \
    && apt-get install -y fd-find \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh) from the official apt repo
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Stamp the installed version for downstream tooling
RUN node /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --version > /home/agent/.pi-image-version \
    && chown agent:agent /home/agent/.pi-image-version

# Suppress Node.js UNDICI-EHPA experimental warning caused by sandbox proxy
# env vars (HTTP_PROXY / HTTPS_PROXY). EnvHttpProxyAgent works fine — it's just
# flagged as experimental in Node v22.
ENV NODE_OPTIONS="--disable-warning=UNDICI-EHPA"

USER agent
