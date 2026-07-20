# AGENTS.md

Source of the prebuilt devcontainer image published to
`ghcr.io/momsdish-corp/devcontainer-public` (linux/amd64 + linux/arm64).

- `Dockerfile` — extends `mcr.microsoft.com/devcontainers/base:trixie`. Each
  tool is installed via its vendor's officially recommended method (no
  Homebrew): tmux and ripgrep from Debian apt; pandoc from its official
  GitHub-release .deb; dolt via its official installer script; beads (bd)
  from its checksum-verified release tarball; Claude Code via Anthropic's
  native installer (`claude.ai/install.sh`, `latest` channel, installed for
  root and symlinked into /usr/local/bin); Codex from its official static
  musl binary; htmlq compiled with cargo in a throwaway build stage (upstream
  ships no Linux binaries). Telemetry opt-outs are baked into the image ENV
  and `/etc/environment`.
- `devcontainer.json` — build-only config consumed by `devcontainer build` in
  CI; bakes the node feature into the image. Not used to open a workspace
  (that is `../devcontainer.json`).

Built by `.github/workflows/devcontainer-image.yml`: nightly upstream-version
check → multi-arch build → smoke test → push to GHCR → GitHub release with the
`versions.json` manifest (which the next nightly check compares against).
GitHub versions are resolved via the `releases/latest` redirect on github.com,
never `api.github.com` (rate-limited from shared CI runner IPs). apt packages
are not version-tracked; they refresh on every rebuild.

When changing the tool set, update `Dockerfile`,
`.github/scripts/devcontainer-image-versions.sh`, and
`.github/scripts/devcontainer-image-smoke.sh` together.
