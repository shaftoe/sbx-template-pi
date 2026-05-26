# sbx-template-pi

Pre-baked custom template image for running [Pi](https://pi.dev) inside [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) (`sbx`).

Pi is baked into the image along with its Node.js runtime and tools — sandboxes start instantly with no install step.

## Published Tags

Images are pushed to GitHub Container Registry on every push to `master` that changes the Dockerfile, weekly via cron, and on manual dispatch.

| Tag | Base | Description |
|-----|------|-------------|
| `latest` | `shell-docker` | Full variant with Docker-in-Docker |
| `latest-slim` | `shell` | Lighter, no Docker daemon |

## Quick Start

### Using the Generic Kit (pre-baked GHCR image, most providers)

The [`sbx-kit/`](sbx-kit/) directory provides a **generic agent kit** that works with Anthropic, OpenAI, DeepSeek, Kimi, Mistral, z.ai, and more. Pi is installed at sandbox creation via npm.

```bash
# Set at least one provider key on your host
export ANTHROPIC_API_KEY=sk-ant-...

# Run from a local clone
sbx run --kit ./sbx-kit/ sbx-template-pi

# ...or directly from the GitHub repo
sbx run --kit "git+https://github.com/shaftoe/sbx-template-pi.git#dir=sbx-kit" sbx-template-pi
```

### Using the z.ai Kit

The [`sbx-kits/pi-zai/`](sbx-kits/pi-zai/) kit uses the pre-baked GHCR image with `ZAI_API_KEY` passthrough and installs pi extensions.

```bash
# Set your z.ai key
export ZAI_API_KEY=zai-...

# Run from a local clone
sbx run --kit ./sbx-kits/pi-zai/ pi

# ...or directly from the GitHub repo
sbx run --kit "git+https://github.com/shaftoe/sbx-template-pi.git#dir=sbx-kits/pi-zai" pi
```

### Stacking the Extras Mixin

The [`sbx-kits/pi-extras/`](sbx-kits/pi-extras/) mixin adds `fd`, `gh`, git defaults, and sandbox tips on top of any Pi agent kit:

```bash
# Generic kit + extras
sbx run --kit ./sbx-kit/ --kit ./sbx-kits/pi-extras/ sbx-template-pi

# z.ai kit + extras
sbx run --kit ./sbx-kits/pi-zai/ --kit ./sbx-kits/pi-extras/ pi-zai
```

### Run the Pre-baked Image Directly

```bash
sbx run -t ghcr.io/shaftoe/sbx-template-pi:latest shell
```

Once inside the sandbox, run `pi` to start the coding agent.

## Kits Overview

| Kit | Kind | Image | Providers | Extensions |
|-----|------|-------|-----------|------------|
| `sbx-kit/` (generic) | agent | `shell-docker` (npm install) | Anthropic, OpenAI, DeepSeek, Mistral, Kimi, z.ai | — |
| `sbx-kits/pi-zai/` | agent | `ghcr.io/shaftoe/sbx-template-pi` (pre-baked) | z.ai | npm + git extensions |
| `sbx-kits/pi-extras/` | mixin | *(inherits from agent kit)* | *(inherits)* | fd, gh CLI, git config |

### Build & Run Locally

```bash
# Using [just](https://just.systems):
just deploy          # build + load into sbx
just run             # sbx run --template sbx-template-pi shell
just kit-run         # generic kit (npm install)
just kit-run-zai     # z.ai kit (pre-baked image)
just kit-run-full    # generic kit + extras mixin
just kit-run-zai-full # z.ai kit + extras mixin
just kit-validate    # validate all kits
just kit-inspect     # inspect all kits

# Or manually:
docker build -t sbx-template-pi .
docker save sbx-template-pi -o sbx-template-pi.tar
sbx template load sbx-template-pi.tar
sbx run --template sbx-template-pi shell
```

## Credentials

```bash
# ZAI provider (used by pi-zai kit, also supported by generic kit)
export ZAI_API_KEY=zai-...

# Anthropic
sbx secret set ANTHROPIC_API_KEY=sk-ant-...

# Other providers supported by the generic kit
sbx secret set OPENAI_API_KEY=sk-...
sbx secret set DEEPSEEK_API_KEY=sk-...
sbx secret set MISTRAL_API_KEY=...
sbx secret set MOONSHOT_API_KEY=...
```

## What's in the Image

- **Node.js 22 LTS** — installed via NodeSource (pi requires `>=22.19.0`)
- **fd-find** — pre-installed so pi doesn't download it at first boot
- **Pi** — `@earendil-works/pi-coding-agent` installed globally for the `agent` user

## CI/CD

A single [workflow](.github/workflows/build-and-publish.yml) handles everything:

| Trigger | Behavior |
|---------|----------|
| Push to `master` (Dockerfile changes) | Build multi-arch + push to GHCR |
| Weekly schedule | Same as push — picks up latest pi & base image |
| Manual dispatch | Same as push, with optional `pi_version` override |

### Renovate

[Renovate](renovate.json) watches the pi npm package and opens PRs to bump the default `PI_VERSION` in the Dockerfile. Runs on a weekly schedule.

## License

MIT
