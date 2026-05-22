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
RUN npm install -g "@earendil-works/pi-coding-agent@${PI_VERSION}" \
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

# Copy Node runtime for the TARGET platform
COPY --from=node-bin /usr/local/bin/node /usr/bin/node

# Copy pi (npm not needed at runtime)
COPY --from=builder /usr/local/lib/node_modules/@earendil-works /usr/local/lib/node_modules/@earendil-works
RUN ln -sf /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js /usr/local/bin/pi

RUN node --version && node /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --version

# Install fd-find so pi doesn't have to download it at first boot
RUN apt-get update \
    && apt-get install -y fd-find \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Stamp the installed version for downstream tooling
RUN node /usr/local/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js --version > /home/agent/.pi-image-version \
    && chown agent:agent /home/agent/.pi-image-version

USER agent
