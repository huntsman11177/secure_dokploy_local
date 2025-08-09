#!/usr/bin/env bash
# Linux/macOS helper: creates an SSH tunnel for Dokploy + Monitoring stack
# Usage: ./tunnel_to_dokploy.sh -k /path/to/key -u root -h <VPS_IP>

KEY_PATH="${KEY_PATH:-$HOME/.ssh/id_rsa}"
USER="${USER:-root}"
HOST="${HOST:-89.58.38.192}"
LOCAL_PORT=3000

while getopts "k:u:h:p:" opt; do
  case $opt in
    k) KEY_PATH="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    h) HOST="$OPTARG" ;;
    p) LOCAL_PORT="$OPTARG" ;;
    *) echo "Usage: $0 [-k key] [-u user] [-h host] [-p dokploy_port]"; exit 1 ;;
  esac
done

echo "Opening SSH tunnel:"
echo " - Dokploy UI  (http://localhost:${LOCAL_PORT})"
echo " - Grafana     (http://localhost:3001)"
echo " - Prometheus  (http://localhost:9090)"
echo " - cAdvisor    (http://localhost:8080)"

ssh -i "$KEY_PATH" \
    -L ${LOCAL_PORT}:localhost:3000 \
    -L 3001:localhost:3001 \
    -L 9090:localhost:9090 \
    -L 8080:localhost:8080 \
    ${USER}@${HOST}
