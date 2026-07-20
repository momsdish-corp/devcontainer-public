#!/usr/bin/env bash
# Smoke test for the prebuilt devcontainer image. Run inside the image:
#
#   docker run --rm -v "$PWD/.github/scripts:/smoke:ro" <image> \
#     bash /smoke/devcontainer-image-smoke.sh [full|binaries]
#
# "binaries" only proves the tools are present plus runs the cheap native
# ones — used for the emulated arm64 leg, where executing the heavyweight
# CLIs under QEMU is slow and flaky.
#
# When changing the tool set, update this script AND
# .devcontainer/base-image/Dockerfile AND devcontainer-image-versions.sh.
set -Eeuxo pipefail

mode="${1:-full}"

# One tool per check: multi-arg `command -v` succeeds if ANY name resolves,
# which would let a missing tool slip through.
for tool in bd dolt htmlq pandoc tmux rg claude codex; do
  command -v "${tool}" > /dev/null || { echo "missing: ${tool}" >&2; exit 1; }
done

bd version
dolt version
htmlq --version
tmux -V
rg --version

if [[ "${mode}" == "full" ]]; then
  pandoc --version
  claude --version
  codex --version

  # node comes from the baked devcontainers node feature (nvm-managed); plain
  # docker run doesn't load the feature's profile hooks, so source nvm.
  if ! command -v node > /dev/null; then
    export NVM_DIR=/usr/local/share/nvm
    if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
      set +ux
      # shellcheck disable=SC1091
      . "${NVM_DIR}/nvm.sh"
      set -ux
    fi
  fi
  node --version
fi

echo "smoke test passed (${mode})"
