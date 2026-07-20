# About
This is the devcontainer base image, preconfigured with tools like
node, claude code, codex, beads, htmlq, pandoc.

For more information, see https://devcontainers.github.io/

## Prebuilt image

The devcontainer runs `ghcr.io/momsdish-corp/devcontainer-public:latest`
(linux/amd64 + linux/arm64), prebuilt with htmlq, pandoc, tmux, ripgrep,
dolt, beads, Claude Code, Codex, and node LTS — so container creation no
longer installs anything heavy. Each tool is installed via its vendor's
officially recommended method (apt, official release artifacts and
installers — no Homebrew). Image source: `.devcontainer/base-image/`.

The `devcontainer-image` GitHub Actions workflow runs nightly: it compares
upstream versions against the `versions.json` manifest attached to the newest
GitHub release and, when something changed, rebuilds the image, smoke tests
it, pushes it to GHCR, and publishes a release recording the baked-in
versions. Pushes to `main` that touch the image definition rebuild
unconditionally, and the workflow can be dispatched manually (`force=true`
to rebuild regardless).

One-time setup after the first successful build: make the GHCR package
public (repo → Packages → `devcontainer-public` → Package settings → Change
visibility) so devcontainers can pull it without credentials.

Note that a devcontainer rebuild reuses the locally cached image — docker
only pulls `latest` when it is absent. To pick up a newer release, run
`docker pull ghcr.io/momsdish-corp/devcontainer-public:latest` on the
machine that runs the containers, then rebuild the devcontainer.
