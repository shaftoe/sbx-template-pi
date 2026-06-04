# Docker sbx template image for Pi coding agent

Pre-baked custom template image for running [Pi](https://pi.dev) inside [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) (`sbx`).

Pi is baked into the image along with its Node.js runtime and tools — sandboxes start with no install step required.

This is meant as a temporary workaround while Pi coding agent gets (hopefully) supported natively. You could also consider joining the lobbying effort at <https://github.com/docker/sbx-releases/issues/34>

## Published Tags

Images are pushed to GitHub Container Registry on every push to `master` that changes the Dockerfile, [daily via cron](.github/workflows/build-and-publish.yml), and on manual dispatch.

| Tag | Base | Description |
|-----|------|-------------|
| `latest` | `shell-docker` | Full variant with Docker-in-Docker |
| `latest-slim` | `shell` | Lighter, no Docker daemon |

## Quick Start

### Run the Pre-baked Image Directly

```bash
sbx run -t ghcr.io/shaftoe/sbx-template-pi:latest shell

# or

sbx run -t ghcr.io/shaftoe/sbx-template-pi:latest-slim shell
```

Once inside the sandbox, run `pi` to start the coding agent.

### Using the Generic Kit (most providers)

The [`sbx-kits/pi/`](sbx-kits/pi/) directory provides a **generic agent kit** that works with Anthropic, OpenAI, DeepSeek, Kimi, Mistral, z.ai, and more. Pi is installed at sandbox creation via npm.

```bash
# Set at least one provider key on your host
export ANTHROPIC_API_KEY=sk-ant-...

# Run from a local clone
sbx run --kit ./sbx-kits/pi pi

# ...or directly from the GitHub repo
sbx run --kit "git+https://github.com/shaftoe/sbx-template-pi.git#dir=sbx-kits/pi" pi
```

> **Known limitation:** `sbx` currently requires `--kit` to be specified on **every** run for custom agents ([docker/sbx-kits-contrib#55](https://github.com/docker/sbx-kits-contrib/issues/55)).
> 
> **Workarounds for re-running an existing sandbox:**
> ```bash
> # Option 1: Run pi directly inside the existing sandbox
> sbx ls # list running sandboxes
> sbx exec -it <sandbox-name> pi
>
> # Option 2: Always pass --kit when re-running
> sbx run --kit ./sbx-kits/pi/ pi
> ```

### Stacking the Extras Mixin

The [`sbx-kits/pi-extras/`](sbx-kits/pi-extras/) mixin adds a couple of Pi extensions to provide an example on how to use mixin kits, you can add it to any agent kit just adding another `--kit` flag:

```bash
# Generic kit + extras
sbx run --kit ./sbx-kits/pi --kit ./sbx-kits/pi-extras/ pi

# With GitHub urls
sbx run --kit "git+https://github.com/shaftoe/sbx-template-pi.git#dir=sbx-kits/pi" --kit "git+https://github.com/shaftoe/sbx-template-pi.git#dir=sbx-kits/pi-extras" pi
```

Refer to <https://docs.docker.com/ai/sandboxes/customize/kits/> for more details.

## What's in the Image

- **Node.js 22 LTS** — installed via NodeSource (pi requires `>=22.19.0`)
- **GitHub CLI** — `gh` is available for GitHub operations
- **fd-find** — pre-installed so pi doesn't download it at first boot
- **Pi** — latest `@earendil-works/pi-coding-agent` installed globally for the `agent` user

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
