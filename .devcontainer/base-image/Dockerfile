# Prebuilt devcontainer image for ghcr.io/momsdish-corp/devcontainer-public.
#
# Bakes in the tools that .devcontainer/inc/update-content-base.sh used to
# install on every container create. Built and released by
# .github/workflows/devcontainer-image.yml (nightly, when upstream versions
# change). When changing the tool set, also update
# .github/scripts/devcontainer-image-versions.sh and
# .github/scripts/devcontainer-image-smoke.sh.
#
# Each tool is installed the way its vendor officially recommends:
#   tmux, ripgrep -> Debian apt (refreshed on every rebuild, not version-tracked)
#   pandoc        -> official .deb from jgm/pandoc GitHub releases
#   dolt          -> official installer script from dolthub/dolt releases
#   beads (bd)    -> official release tarball, checksum-verified (mirrors the
#                    project's scripts/install.sh but resolves the version via
#                    the release redirect instead of api.github.com, which is
#                    rate-limited from shared CI runner IPs)
#   Claude Code   -> Anthropic's native installer (claude.ai/install.sh)
#   Codex         -> official static binary from openai/codex releases
#   htmlq         -> cargo install (upstream publishes no Linux binaries)
#   node LTS      -> devcontainers node feature (see devcontainer.json)

# htmlq's documented install method is cargo; build it in a throwaway stage so
# the final image carries no rust toolchain.
FROM rust:1 AS htmlq-builder
RUN cargo install --locked htmlq --root /opt/htmlq

FROM mcr.microsoft.com/devcontainers/base:trixie
ARG TARGETARCH
ARG BUILDPLATFORM
ARG TARGETPLATFORM
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Telemetry opt-outs: ENV covers every container process; /etc/environment
# covers login shells that reset the environment.
# BUG @ref https://github.com/anthropics/claude-code/issues/76748
# ENV DISABLE_TELEMETRY=1 \
#     DO_NOT_TRACK=1 \
#     CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
#     CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1 \
#     CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1 \
    CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1

RUN printf '%s\n' \
      "DISABLE_TELEMETRY=1" \
      "DO_NOT_TRACK=1" \
      "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1" \
      "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1" \
      "CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1" \
      >> /etc/environment

# tmux and ripgrep (Codex uses rg) from Debian; pandoc from its official .deb
# (Debian's pandoc lags far behind upstream releases).
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends tmux ripgrep \
 && loc="$(curl -fsSI https://github.com/jgm/pandoc/releases/latest | awk 'tolower($1) == "location:" && !found { found = 1; sub(/\r$/, "", $2); print $2 }')" \
 && ver="${loc##*/}" \
 && [ -n "${ver}" ] && [ "${ver}" != "releases" ] \
 && curl -fsSLo /tmp/pandoc.deb "https://github.com/jgm/pandoc/releases/download/${ver}/pandoc-${ver}-1-${TARGETARCH}.deb" \
 && apt-get install -y --no-install-recommends /tmp/pandoc.deb \
 && rm -f /tmp/pandoc.deb \
 && rm -rf /var/lib/apt/lists/*

# Dolt — official installer (arch-aware, installs to /usr/local/bin, needs root)
RUN curl -fsSL https://github.com/dolthub/dolt/releases/latest/download/install.sh | bash

# beads (bd) — official release tarball with checksum verification, plus the
# 'beads' alias the official installer creates
# awk consumes the whole stream (no early exit): an early close SIGPIPEs curl,
# which `bash -o pipefail` turns into a spurious build failure
RUN loc="$(curl -fsSI https://github.com/gastownhall/beads/releases/latest | awk 'tolower($1) == "location:" && !found { found = 1; sub(/\r$/, "", $2); print $2 }')" \
 && tag="${loc##*/}" \
 && [ -n "${tag}" ] && [ "${tag}" != "releases" ] \
 && archive="beads_${tag#v}_linux_${TARGETARCH}.tar.gz" \
 && curl -fsSLo "/tmp/${archive}" "https://github.com/gastownhall/beads/releases/download/${tag}/${archive}" \
 && curl -fsSLo /tmp/checksums.txt "https://github.com/gastownhall/beads/releases/download/${tag}/checksums.txt" \
 && expected="$(awk -v t="${archive}" '{ n = $2; sub(/^\*/, "", n); if (n == t) { print $1; exit } }' /tmp/checksums.txt)" \
 && actual="$(sha256sum "/tmp/${archive}" | cut -d' ' -f1)" \
 && [ -n "${expected}" ] && [ "${expected}" = "${actual}" ] \
 && tar -xzf "/tmp/${archive}" -C /tmp bd \
 && install -m 755 /tmp/bd /usr/local/bin/bd \
 && ln -sf bd /usr/local/bin/beads \
 && rm -f "/tmp/${archive}" /tmp/checksums.txt /tmp/bd

# Claude Code — Anthropic's native installer; 'latest' matches the release
# channel the previous claude-code@latest setup tracked. Installs into
# /root/.local (the container runs as root); the /usr/local/bin symlink puts
# it on PATH for all shells.
#
# The installer finishes by EXECUTING the freshly downloaded claude binary
# (`claude install`), which is unreliable under QEMU emulation. On
# cross-platform builds, reproduce the installer's own steps — same release
# feed, same manifest checksum verification, same on-disk layout — without
# running the binary.
RUN if [ "${BUILDPLATFORM}" = "${TARGETPLATFORM}" ]; then \
      curl -fsSL https://claude.ai/install.sh | bash -s latest; \
    else \
      case "${TARGETARCH}" in \
        amd64) platform="linux-x64" ;; \
        arm64) platform="linux-arm64" ;; \
        *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
      esac \
      && base_url="https://downloads.claude.ai/claude-code-releases" \
      && version="$(curl -fsSL "${base_url}/latest")" \
      && [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] \
      && checksum="$(curl -fsSL "${base_url}/${version}/manifest.json" \
           | jq -re ".platforms[\"${platform}\"].checksum")" \
      && [[ "${checksum}" =~ ^[a-f0-9]{64}$ ]] \
      && curl -fsSLo /tmp/claude "${base_url}/${version}/${platform}/claude" \
      && echo "${checksum}  /tmp/claude" | sha256sum -c - \
      && install -D -m 755 /tmp/claude "/root/.local/share/claude/versions/${version}" \
      && mkdir -p /root/.local/bin \
      && ln -sf "/root/.local/share/claude/versions/${version}" /root/.local/bin/claude \
      && rm -f /tmp/claude; \
    fi \
 && ln -sf /root/.local/bin/claude /usr/local/bin/claude \
 && rm -rf /root/.claude/downloads

# Codex — official prebuilt static binary (musl)
RUN case "${TARGETARCH}" in \
      amd64) triple="x86_64-unknown-linux-musl" ;; \
      arm64) triple="aarch64-unknown-linux-musl" ;; \
      *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /tmp/codex.tar.gz "https://github.com/openai/codex/releases/latest/download/codex-${triple}.tar.gz" \
 && tar -xzf /tmp/codex.tar.gz -C /tmp "codex-${triple}" \
 && install -m 755 "/tmp/codex-${triple}" /usr/local/bin/codex \
 && rm -f /tmp/codex.tar.gz "/tmp/codex-${triple}"

COPY --from=htmlq-builder /opt/htmlq/bin/htmlq /usr/local/bin/htmlq

# Mouse scrolling in tmux, for both users the container may run as
RUN printf 'set -g mouse on\n' >> /root/.tmux.conf \
 && printf 'set -g mouse on\n' >> /home/vscode/.tmux.conf \
 && chown vscode:vscode /home/vscode/.tmux.conf
