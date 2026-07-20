# AGENTS.md

GitHub Actions configuration.

- `workflows/devcontainer-image.yml` — builds and releases the prebuilt
  devcontainer image (source: `.devcontainer/base-image/`) to
  `ghcr.io/momsdish-corp/devcontainer-public`. Runs nightly at 03:17 UTC and
  rebuilds only when the computed upstream version manifest differs from the
  `versions.json` asset of the newest GitHub release; also rebuilds on pushes
  to main that touch the image definition, and on workflow_dispatch
  (force=true rebuilds unconditionally). Multi-platform builds are exported
  to an OCI archive by devcontainers/ci and pushed with skopeo; the `latest`
  tag is only moved after the smoke test passes.
- `scripts/devcontainer-image-versions.sh` — computes the upstream version
  manifest (base image digest, node feature digest, node LTS, and tool
  versions from GitHub releases, crates.io, and Anthropic's release feed)
  with curl + jq; runnable locally. GitHub versions come from the
  `releases/latest` redirect, never rate-limited `api.github.com`.
- `scripts/devcontainer-image-smoke.sh` — smoke test executed inside the
  freshly built image before it is tagged `latest` and released.

Tool-set changes must update both scripts and
`.devcontainer/base-image/Dockerfile` together.
