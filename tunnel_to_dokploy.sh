#!/usr/bin/env bash
# Linux/macOS helper: creates an SSH tunnel to Dokploy and optionally opens a browser.
# Usage: ./tunnel_to_dokploy.sh -k /path/to/key -u root -h 89.58.38.192

KEY_PATH="${KEY_PATH:-$HOME/.ssh/ssh_private_key}"
USER="${USER:-root}"
HOST="${HOST:-ip.ip.ip.ip}"
LOCAL_PORT=3000

while getopts "k:u:h:p:b" opt; do
  case $opt in
    k) KEY_PATH="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    h) HOST="$OPTARG" ;;
    p) LOCAL_PORT="$OPTARG" ;;
    b) OPEN_BROWSER=true ;;
    *) echo "Usage: $0 [-k key] [-u user] [-h host] [-p local_port] [-b open-browser]"; exit 1 ;;
  esac
done

echo "Opening SSH tunnel: localhost:${LOCAL_PORT} -> ${HOST}:3000"
ssh -i "$KEY_PATH" -L ${LOCAL_PORT}:localhost:3000 ${USER}@${HOST}

# To open a browser automatically (uncomment below if desired):
# if [ "${OPEN_BROWSER:-}" = true ]; then
#   if command -v xdg-open >/dev/null 2>&1; then
#     xdg-open "http://localhost:${LOCAL_PORT}"
#   elif command -v open >/dev/null 2>&1; then
#     open "http://localhost:${LOCAL_PORT}"
#   fi
# fi