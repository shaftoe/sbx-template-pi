## What's happening

You're building a `linux/arm64` image on a `linux/amd64` GitHub Actions runner. Docker uses **QEMU** to emulate the ARM64 architecture, which is visible in the error:

```
process "/dev/.buildkit_qemu_emulator /bin/sh -c ..."
```

The `pi` CLI's security check is inspecting `argv[0]` (or `/proc/self/exe`) to verify the process name matches the expected executable. Under QEMU emulation, the process chain looks something like:

```
qemu-aarch64 → node → pi CLI
```

When `pi` checks its executable path, it sees something unexpected — likely `/dev/.buildkit_qemu_emulator` or a mangled `argv[0]` — rather than the actual `node` binary path, so its internal integrity check fires as a "security violation."

The `env` mismatch message (`Requested utility 'env' does not match executable name`) suggests `pi` is trying to resolve how it was invoked and the QEMU wrapper is confusing that lookup.

## Why it works natively

On a native ARM64 runner (or on x86 building x86), there's no emulation layer, so `argv[0]` / `/proc/self/exe` resolves cleanly to the real node binary.

## How to fix it

**Option 1 — Use a native ARM64 runner** (cleanest):
```yaml
runs-on: ubuntu-24.04-arm
```
GitHub now has native ARM64 runners. No QEMU, no emulation artifacts.

**Option 2 — Skip the `pi --version` check in the Dockerfile** if it's just a smoke test — run it outside the cross-compilation context instead (e.g., in a separate CI step on a native runner).

**Option 3 — Use `--platform` to build only for the host arch** during CI and save multi-arch builds for a dedicated job with native runners per platform.

**Option 4 — Check if `pi` has an env var to disable the security check** — some CLIs expose something like `PI_SKIP_INTEGRITY_CHECK=1` or similar for CI/container contexts. Worth checking the Pi SDK docs.

The root cause is that QEMU's process wrapping breaks assumptions that the `pi` CLI makes about its own execution environment.
