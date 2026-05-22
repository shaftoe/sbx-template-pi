# sbx-template-pi

Pre-baked custom template image for running [Pi](https://pi.dev) inside [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) (`sbx`).

Pi is baked into the image along with its Node.js runtime and tools — sandboxes start instantly with no install step.

## Published Tags

Images are pushed to GitHub Container Registry on every merge to `main`, weekly via cron, and on manual dispatch.

| Tag | Base | Description |
|-----|------|-------------|
| `latest` | `shell-docker` | Full variant with Docker-in-Docker |
| `latest-slim` | `shell` | Lighter, no Docker daemon |

## Quick Start

```bash
# Run a sandbox using the pre-built image from GHCR:
sbx run -t ghcr.io/shaftoe/sbx-template-pi:latest shell
```

Once inside the sandbox, run `pi` to start the coding agent.

### Build & Run Locally

```bash
# Using [just](https://just.systems):
just deploy          # build + load into sbx
just run             # sbx run --template sbx-template-pi shell

# Or manually:
docker build -t sbx-template-pi .
docker save sbx-template-pi -o sbx-template-pi.tar
sbx template load sbx-template-pi.tar
sbx run --template sbx-template-pi shell
```

## Credentials

```bash
# Anthropic (default provider)
sbx secret set ANTHROPIC_API_KEY=sk-ant-...

# Other providers
sbx secret set OPENAI_API_KEY=sk-...
sbx secret set GOOGLE_API_KEY=...
```

## What's in the Image

- **Node.js 22 LTS** — installed via NodeSource (pi requires `>=22.19.0`)
- **fd-find** — pre-installed so pi doesn't download it at first boot
- **Pi** — `@earendil-works/pi-coding-agent` installed globally for the `agent` user

## Build Locally

```bash
# Default variant (with Docker-in-Docker)
just build

# Slim variant (no Docker)
just build-slim

# Pin a specific pi version
just build shell-docker 0.7.0
```

All recipes accept `base_variant` and `pi_version` parameters — see `just --list`.

## CI/CD

A single [workflow](.github/workflows/build.yml) handles everything:

| Trigger | Behavior |
|---------|----------|
| PR to `main` | Build + smoke test (no push) |
| Push to `main` | Build multi-arch + push to GHCR + version-pinned tag |
| Weekly schedule | Same as push — picks up latest pi & base image |
| Manual dispatch | Same as push, with optional `pi_version` override |

### Renovate

[Renovate](renovate.json) watches the pi npm package and opens PRs to bump the default `PI_VERSION` in the Dockerfile. Runs on a weekly schedule.

## Kit vs Template

| | [sbx-kits-contrib/pi](https://github.com/docker/sbx-kits-contrib/tree/main/pi) (Kit) | This project (Template) |
|---|---|---|
| Install time | Every sandbox creation | Once at image build |
| Startup speed | Slow (~30-60s npm install) | Instant |
| Network needs at create | registry.npmjs.org | None |
| Updates | Always latest | Rebuild image |
| Network policy | Via `spec.yaml` | Via `sbx policy` CLI |

## Project Structure

```
.
├── Dockerfile                   # Multi-variant image definition
├── justfile                     # Task runner for common workflows
├── renovate.json                # Renovate config for pi version bumps
├── test/
│   └── smoke-test.sh           # Basic image validation
└── .github/workflows/
    └── build.yml               # Build, test, publish pipeline
```

## License

MIT
