#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This installer needs root. Re-run with sudo." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_SH="${SCRIPT_DIR}/download.sh"
if [ ! -x "$DOWNLOAD_SH" ]; then
  echo "Cannot find executable download.sh next to install.sh (${DOWNLOAD_SH})." >&2
  exit 1
fi

echo "=== mondevvideoports interactive installer ==="
echo

read -r -p "ntfy slug (required): " NTFY_SLUG
while [ -z "$NTFY_SLUG" ]; do
  read -r -p "ntfy slug cannot be empty: " NTFY_SLUG
done

read -r -p "ntfy endpoint [https://ntfy.sh]: " NTFY_ENDPOINT
NTFY_ENDPOINT="${NTFY_ENDPOINT:-https://ntfy.sh}"

read -r -p "ports to monitor (comma-separated) [video0,video1]: " PORTS
PORTS="${PORTS:-video0,video1}"

read -r -p "user to run service as [root]: " SERVICE_USER
SERVICE_USER="${SERVICE_USER:-root}"

read -r -p "release tag [latest]: " TAG
TAG="${TAG:-latest}"

read -r -p "start service after install? [Y/n]: " START
case "${START:-Y}" in
  [Nn]*) START_SERVICE=0 ;;
  *) START_SERVICE=1 ;;
esac

echo
echo "Summary:"
echo "  slug:     ${NTFY_SLUG}"
echo "  endpoint: ${NTFY_ENDPOINT}"
echo "  ports:    ${PORTS}"
echo "  user:     ${SERVICE_USER}"
echo "  tag:      ${TAG}"
echo "  start:    ${START_SERVICE}"
read -r -p "Proceed? [Y/n]: " GO
case "${GO:-Y}" in
  [Nn]*) echo "Aborted."; exit 1 ;;
esac

export NTFY_SLUG NTFY_ENDPOINT PORTS SERVICE_USER TAG START_SERVICE
exec "$DOWNLOAD_SH"
