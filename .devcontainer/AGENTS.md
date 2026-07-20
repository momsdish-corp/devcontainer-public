# AGENTS.md

Devcontainer configuration for this repository.

## Structure

- `devcontainer.json` — runtime config. Pulls the prebuilt image
  `ghcr.io/momsdish-corp/devcontainer-public:latest`, which has the tool set
  baked in (htmlq, pandoc, tmux, ripgrep, dolt, beads, Claude Code, Codex,
  node LTS), each installed via its vendor's official method.
- `base-image/` — source of that prebuilt image (Dockerfile + build-only
  devcontainer.json). Built and released by
  `.github/workflows/devcontainer-image.yml`.
- `update-content.sh` → `inc/update-content-base.sh` — runtime-only
  provisioning that must re-run per container/workspace: git config, beads
  (bd) init for /workspace, Claude/Codex MCP registration. Keep it fast and
  idempotent.
- `post-start.sh` → `inc/post-start-base.sh` — post-start hooks (warm up the
  beads Dolt server; host Chrome debugging hint).

## Rules

- Do NOT add package/tool installation to the update-content or post-start
  scripts — bake new tools into `base-image/Dockerfile` instead.
- The tool set is listed in three places that must change together:
  `base-image/Dockerfile`, `.github/scripts/devcontainer-image-versions.sh`
  (the `tools` manifest object), and
  `.github/scripts/devcontainer-image-smoke.sh`.
- `inc/*-base.sh` files are the shared template layer; repo-specific additions
  belong in `update-content.sh` / `post-start.sh`.
