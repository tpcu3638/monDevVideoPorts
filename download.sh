#!/usr/bin/env bash
set -euo pipefail

REPO="tpcu3638/monDevVideoPorts"
INSTALL_DIR="${INSTALL_DIR:-/opt/mondevvideoports/dist}"
WORK_DIR="${WORK_DIR:-$(dirname "$INSTALL_DIR")}"
TAG="${TAG:-latest}"

INSTALL_SERVICE="${INSTALL_SERVICE:-1}"
START_SERVICE="${START_SERVICE:-0}"
SERVICE_NAME="mondevvideoports.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
SERVICE_USER="${SERVICE_USER:-root}"

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

echo "Installed binary to ${INSTALL_DIR}/build"

if [ "$INSTALL_SERVICE" != "1" ]; then
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Need root to install systemd unit. Re-run with sudo, or set INSTALL_SERVICE=0." >&2
  exit 1
fi

if [ -n "${EXEC_ARGS:-}" ]; then
  :
elif [ -n "${NTFY_SLUG:-}" ] && [ -n "${PORTS:-}" ]; then
  EXEC_ARGS="-s ${NTFY_SLUG} -p ${PORTS}"
  [ -n "${NTFY_ENDPOINT:-}" ] && EXEC_ARGS="${EXEC_ARGS} -u ${NTFY_ENDPOINT}"
else
  EXEC_ARGS="-s YOUR_NTFY_SLUG -p video0,video1"
  echo "Warning: NTFY_SLUG/PORTS not set; installing unit with placeholder args." >&2
  echo "         Edit ${SERVICE_PATH} before starting the service." >&2
fi

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Monitor /dev/video* ports and notify via ntfy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${WORK_DIR}
ExecStart=${INSTALL_DIR}/build ${EXEC_ARGS}
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SupplementaryGroups=video

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
echo "Installed systemd unit at ${SERVICE_PATH} (enabled)"

if [ "$START_SERVICE" = "1" ]; then
  systemctl restart "${SERVICE_NAME}"
  echo "Service started. Status: $(systemctl is-active ${SERVICE_NAME})"
else
  echo "Run 'sudo systemctl start ${SERVICE_NAME}' to start it."
fi
