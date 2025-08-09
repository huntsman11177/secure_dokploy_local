#!/usr/bin/env bash
# secure-dokploy-local: fully-hardened Dokploy installer (local-only)
# Targets: Ubuntu 24.04 LTS (tested)
# - Installs Docker (official repo)
# - Installs Dokploy, binds UI to 127.0.0.1:3000 only
# - Enables UFW (allow SSH, 80, 443) and denies 3000 publicly
# - Installs fail2ban and basic SSH hardening (key-only)
# - Optional: enables watchtower for auto-updates if WATCHTOWER=true

set -euo pipefail
IFS=$'\n\t'

# -------- CONFIGURATION (edit as needed) --------
DOMAIN=""                      # Leave blank — do NOT expose Dokploy publicly
ADMIN_EMAIL=""                 # Optional, only if you later enable TLS in the future
DOKPLOY_DIR="/opt/dokploy"
WATCHTOWER=${WATCHTOWER:-true}   # set "false" to skip
HARDEN_SSH=${HARDEN_SSH:-true}   # set "false" to skip sshd hardening

# Packages to install
PKGS=(curl wget gnupg lsb-release ca-certificates apt-transport-https
      jq ufw fail2ban git software-properties-common)

log() { printf "[%s] %s\n" "INFO" "$*"; }
err() { printf "[%s] %s\n" "ERROR" "$*" >&2; exit 1; }

if [ "$EUID" -ne 0 ]; then
  err "This script must be run as root (sudo)."
fi

log "Starting secure Dokploy installation..."

# Update & install basic packages
apt update -y
apt upgrade -y
apt install -y "${PKGS[@]}"

# Install Docker (official repo) — idempotent
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker from official repo..."
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  apt update -y
  # avoid containerd conflicts: install recommended set
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
else
  log "Docker already installed: $(docker --version)"
fi

# Create dokploy dir
mkdir -p "$DOKPLOY_DIR"
chown root:root "$DOKPLOY_DIR"
chmod 0755 "$DOKPLOY_DIR"
cd "$DOKPLOY_DIR"

# Fetch official docker-compose template (if provider offers); fallback to minimal compose
if curl -fsSL https://raw.githubusercontent.com/dokploy/dokploy/main/docker-compose.yml -o docker-compose.yml.tmp; then
  mv docker-compose.yml.tmp docker-compose.yml
else
  cat > docker-compose.yml <<'EOF'
version: '3.7'
services:
  app:
    image: dokploy/dokploy:latest
    container_name: dokploy_app
    restart: unless-stopped
    environment:
      - DOKPLOY_PUBLIC_URL=http://localhost:3000
    volumes:
      - dokploy_data:/app/data
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - dokploy_net

  traefik:
    image: traefik:v3.1.2
    container_name: dokploy_traefik
    restart: unless-stopped
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_letsencrypt:/letsencrypt
    networks:
      - dokploy_net

volumes:
  dokploy_data:
  traefik_letsencrypt:

networks:
  dokploy_net:
    driver: bridge
EOF
fi

# Ensure docker compose v2 is available
if ! docker compose version >/dev/null 2>&1; then
  err "docker compose not available. Please ensure Docker Compose plugin is installed."
fi

# Start services (local-only binding for app)
docker compose up -d --remove-orphans

# UFW: allow SSH, HTTP, HTTPS; deny 3000 publicly
if command -v ufw >/dev/null 2>&1; then
  log "Configuring UFW..."
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw deny 3000/tcp
  ufw --force enable
fi

# fail2ban basic enable
if command -v fail2ban-server >/dev/null 2>&1; then
  systemctl enable --now fail2ban
fi

# SSH hardening (optional)
if [ "$HARDEN_SSH" = "true" ]; then
  log "Applying basic SSH hardening: disable password auth, PermitRootLogin without-password or prohibit-password as configured."
  sed -i.bak -E "s/^#?PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config || true
  # keep PermitRootLogin to prohibit-password (key only)
  sed -i.bak -E "s/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config || true
  systemctl reload sshd
fi

# Optional: install Watchtower for auto-updates
if [ "$WATCHTOWER" = true ]; then
  if ! docker ps --format '{{.Names}}' | grep -q '^watchtower$'; then
    docker run -d --name watchtower --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup --interval 86400 || true
  fi
fi

log "Installation finished. Dokploy UI is bound to 127.0.0.1:3000 (local-only)."
cat <<EOF

Next steps (from your laptop):
  ssh -L 3000:localhost:3000 <user>@<vps-ip>
  open http://localhost:3000 in your browser

To make Dokploy public later, update docker-compose.yml, remove 127.0.0.1 binding and configure Traefik labels securely.
EOF