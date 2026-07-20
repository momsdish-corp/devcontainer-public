#!/usr/bin/env bash
# Computes the upstream version manifest for the prebuilt devcontainer image
# (.devcontainer/base-image/) and prints it as canonical JSON on stdout.
#
# The devcontainer-image workflow compares this output against the
# versions.json asset attached to the newest GitHub release to decide whether
# the image needs a rebuild. Pure curl + jq, so it runs anywhere — no docker.
# GitHub versions are resolved via the releases/latest redirect on github.com,
# never api.github.com (rate-limited from shared CI runner IPs).
#
# apt-installed tools (tmux, ripgrep) are intentionally not tracked: they are
# pinned by Debian trixie and refresh on every rebuild.
#
# When changing the tool set, update this script AND
# .devcontainer/base-image/Dockerfile AND devcontainer-image-smoke.sh.
set -Eeuo pipefail

CURL=(curl -fsSL --retry 3 --retry-delay 2 --max-time 60)
ACCEPT='application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.list.v2+json'
# crates.io rejects requests without a User-Agent
USER_AGENT='devcontainer-image-ci (github.com/momsdish-corp/devcontainer-public)'

fail() {
  echo "error: $*" >&2
  exit 1
}

# HEAD a registry manifest and print its digest. Args: host repo tag [token]
manifest_digest() {
  local host="$1" repo="$2" tag="$3" token="${4-}" args
  args=(-fsSI --retry 3 --retry-delay 2 --max-time 60 -H "Accept: ${ACCEPT}")
  if [[ -n "${token}" ]]; then
    args+=(-H "Authorization: Bearer ${token}")
  fi
  curl "${args[@]}" "https://${host}/v2/${repo}/manifests/${tag}" \
    | tr -d '\r' | awk 'tolower($1) == "docker-content-digest:" { print $2; exit }'
}

# Anonymous pull token for a public GHCR repository. Args: repo
ghcr_token() {
  "${CURL[@]}" "https://ghcr.io/token?scope=repository:$1:pull" | jq -re '.token'
}

# Tag of a repository's newest GitHub release, via the redirect. Args: owner/repo
github_latest_tag() {
  local loc tag
  loc="$(curl -fsSI --retry 3 --retry-delay 2 --max-time 60 "https://github.com/$1/releases/latest" \
    | tr -d '\r' | awk 'tolower($1) == "location:" { print $2; exit }')" || return 1
  tag="${loc##*/}"
  [[ -n "${tag}" && "${tag}" != "releases" && "${tag}" != "latest" ]] || return 1
  printf '%s\n' "${tag}"
}

base_digest="$(manifest_digest mcr.microsoft.com devcontainers/base trixie)" \
  || fail "could not resolve base image digest"
[[ -n "${base_digest}" ]] || fail "base image digest came back empty"

node_feature_digest="$(manifest_digest ghcr.io devcontainers/features/node 1 \
  "$(ghcr_token devcontainers/features/node)")" \
  || fail "could not resolve node feature digest"
[[ -n "${node_feature_digest}" ]] || fail "node feature digest came back empty"

node_lts="$("${CURL[@]}" https://nodejs.org/dist/index.json \
  | jq -re '[.[] | select(.lts != false)][0].version')" \
  || fail "could not resolve latest node LTS version"

pandoc="$(github_latest_tag jgm/pandoc)" || fail "could not resolve pandoc version"
dolt="$(github_latest_tag dolthub/dolt)" || fail "could not resolve dolt version"
beads="$(github_latest_tag gastownhall/beads)" || fail "could not resolve beads version"
codex="$(github_latest_tag openai/codex)" || fail "could not resolve codex version"

# Anthropic's release feed for the Claude Code native installer's 'latest' channel
claude="$("${CURL[@]}" https://downloads.claude.ai/claude-code-releases/latest)" \
  || fail "could not resolve claude-code version"
[[ "${claude}" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] \
  || fail "unexpected claude-code version: ${claude}"

htmlq="$("${CURL[@]}" -A "${USER_AGENT}" https://crates.io/api/v1/crates/htmlq \
  | jq -re '.crate.max_stable_version')" \
  || fail "could not resolve htmlq version"

jq -nS \
  --arg base_image "mcr.microsoft.com/devcontainers/base:trixie@${base_digest}" \
  --arg node_feature "${node_feature_digest}" \
  --arg node_lts "${node_lts}" \
  --arg beads "${beads}" \
  --arg claude "${claude}" \
  --arg codex "${codex}" \
  --arg dolt "${dolt}" \
  --arg htmlq "${htmlq}" \
  --arg pandoc "${pandoc}" \
  '{
    base_image: $base_image,
    features: { "ghcr.io/devcontainers/features/node:1": $node_feature },
    node_lts: $node_lts,
    tools: {
      "beads": $beads,
      "claude-code": $claude,
      "codex": $codex,
      "dolt": $dolt,
      "htmlq": $htmlq,
      "pandoc": $pandoc
    }
  }'
