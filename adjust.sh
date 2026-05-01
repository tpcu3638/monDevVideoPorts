#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="mondevvideoports.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Need root. Re-run with sudo." >&2
  exit 1
fi
if [ ! -f "$SERVICE_PATH" ]; then
  echo "${SERVICE_PATH} not found. Run install.sh first." >&2
  exit 1
fi

current_user=$(awk -F= '/^User=/{print $2; exit}' "$SERVICE_PATH")
exec_line=$(awk '/^ExecStart=/{sub(/^ExecStart=/,""); print; exit}' "$SERVICE_PATH")
binary_path=$(awk '{print $1}' <<<"$exec_line")

current_slug=$(grep -oE -- '-s [^ ]+' <<<"$exec_line" | awk '{print $2}' || true)
current_ports=$(grep -oE -- '-p [^ ]+' <<<"$exec_line" | awk '{print $2}' || true)
current_endpoint=$(grep -oE -- '-u [^ ]+' <<<"$exec_line" | awk '{print $2}' || true)
current_endpoint="${current_endpoint:-https://ntfy.sh}"

echo "=== Adjusting ${SERVICE_PATH} ==="
echo "Press Enter to keep the current value shown in [brackets]."
echo

read -r -p "ntfy slug [${current_slug}]: " NTFY_SLUG
NTFY_SLUG="${NTFY_SLUG:-$current_slug}"

read -r -p "ntfy endpoint [${current_endpoint}]: " NTFY_ENDPOINT
NTFY_ENDPOINT="${NTFY_ENDPOINT:-$current_endpoint}"

read -r -p "ports [${current_ports}]: " PORTS
PORTS="${PORTS:-$current_ports}"

read -r -p "user [${current_user}]: " SERVICE_USER
SERVICE_USER="${SERVICE_USER:-$current_user}"

NEW_EXEC="${binary_path} -s ${NTFY_SLUG} -p ${PORTS}"
if [ -n "$NTFY_ENDPOINT" ] && [ "$NTFY_ENDPOINT" != "https://ntfy.sh" ]; then
  NEW_EXEC="${NEW_EXEC} -u ${NTFY_ENDPOINT}"
fi

tmp=$(mktemp)
awk -v new_user="$SERVICE_USER" -v new_exec="$NEW_EXEC" '
  /^User=/      { print "User=" new_user; next }
  /^ExecStart=/ { print "ExecStart=" new_exec; next }
                { print }
' "$SERVICE_PATH" > "$tmp"
mv "$tmp" "$SERVICE_PATH"
chmod 644 "$SERVICE_PATH"

systemctl daemon-reload
echo "Updated ${SERVICE_PATH}."

read -r -p "Restart service now? [Y/n]: " RESTART
case "${RESTART:-Y}" in
  [Nn]*) echo "Skipped restart. Run 'sudo systemctl restart ${SERVICE_NAME}' to apply." ;;
  *) systemctl restart "${SERVICE_NAME}"
     echo "Restarted. Status: $(systemctl is-active "${SERVICE_NAME}")" ;;
esac
