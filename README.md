# secure-dokploy-local

Hardened Dokploy installer: local-only admin UI (SSH-tunnel access). Designed for VPS deployments where you want public apps but a private admin UI.

## What you get

- `install_dokploy.sh` — fully hardened VPS installer (Ubuntu 24.04 tested).
- `tunnel_to_dokploy.sh` — Linux/macOS helper to create SSH tunnel.
- `tunnel_to_dokploy.ps1` — Windows PowerShell helper to create SSH tunnel.

## Security model

- Dokploy admin UI binds only to `127.0.0.1:3000` on the VPS.
- UFW blocks port `3000` publicly.
- Fail2Ban rate-limits SSH attempts.
- SSH is hardened to use key-based auth (password auth disabled).

## Quick start (VPS)

1. SSH into your VPS (as root or sudo-capable user):

```bash
ssh root@<VPS_IP>

2. Upload or clone this repo on the VPS, then run as root:

    chmod +x install_dokploy.sh
    ./install_dokploy.sh

3. The installer will start Docker, pull Dokploy and Traefik, and bind the admin UI to 127.0.0.1:3000.

Accessing Dokploy (locally via SSH tunnel)

Linux / macOS

./tunnel_to_dokploy.sh -k ~/.ssh/(ssh_private_key) -u root -h <VPS_IP>
# Then open http://localhost:3000 in your browser

Windows (PowerShell)

.	unnel_to_dokploy.ps1 -KeyPath C:\Users\<you>\.ssh\ssh_private_key -User root -Host <VPS_IP>
# Then open http://localhost:3000 in your browser

Making Dokploy public (optional, NOT recommended by default)

If you want the admin UI public (only do this with additional protections):

Configure DNS for the domain to point to your VPS.

Edit docker-compose.yml and remove 127.0.0.1: prefix on the ports mapping for the app service.

Add Traefik labels to the app service to proxy it and enable a certificates resolver (Let's Encrypt) in Traefik.

Troubleshooting

If you can't connect via tunnel, ensure your SSH key is accepted, port forwarding is allowed, and your local port is free.

Use docker compose logs -f to see container logs.

Use ufw status verbose to verify firewall rules.


---

# Notes

- The `install_dokploy.sh` script tries to obtain an official `docker-compose.yml` from the Dokploy upstream; if it can't, it falls back to a minimal compose file with `127.0.0.1:3000:3000` binding.

