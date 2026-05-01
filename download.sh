#!/usr/bin/env bash
set -euo pipefail

REPO="tpcu3638/monDevVideoPorts"
INSTALL_DIR="${INSTALL_DIR:-/opt/mondevvideoports/dist}"
TAG="${TAG:-latest}"

case "$(uname -m)" in
  x86_64|amd64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

ASSET="mondevvideoports-linux-${ARCH}"

if [ "$TAG" = "latest" ]; then
  API_URL="https://api.github.com/repos/${REPO}/releases/latest"
else
  API_URL="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"
fi

AUTH_HEADER=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

echo "Fetching release info from ${API_URL}..."
DOWNLOAD_URL=$(
  curl -fsSL "${AUTH_HEADER[@]}" \
    -H "Accept: application/vnd.github+json" \
    "$API_URL" \
  | grep -oE "\"browser_download_url\": *\"[^\"]*${ASSET}\"" \
  | head -n1 \
  | sed -E 's/.*"(https:[^"]+)".*/\1/'
)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Could not find asset ${ASSET} in release ${TAG}." >&2
  exit 1
fi

echo "Downloading ${DOWNLOAD_URL}..."
mkdir -p "$INSTALL_DIR"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl -fSL "${AUTH_HEADER[@]}" -o "$TMP" "$DOWNLOAD_URL"
chmod +x "$TMP"
mv "$TMP" "${INSTALL_DIR}/build"
trap - EXIT

echo "Installed to ${INSTALL_DIR}/build"
