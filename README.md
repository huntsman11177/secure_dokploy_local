# secure-dokploy-local

**Hardened Dokploy Installer: Local-Only Admin UI (SSH Tunnel Access)**  
Designed for VPS deployments where you want public apps with a private admin UI.

***

## Features

- `install_dokploy.sh`: Fully hardened installer for Ubuntu 24.04.
- `tunnel_to_dokploy.sh`: Helper for Linux/macOS to create SSH tunnel.
- `tunnel_to_dokploy.ps1`: PowerShell helper for Windows to create SSH tunnel.

***

## Security Model

- Dokploy admin UI binds only to `127.0.0.1:3000` on the VPS.
- **UFW** blocks public access to port `3000`.
- **Fail2Ban** rate-limits SSH login attempts.
- **SSH** is hardened for key-based authentication (password auth disabled).

***

## Quick Start (VPS)

1. **SSH into your VPS** (as root or sudo-capable user):

    ```bash
    ssh root@
    ```

2. **Upload or clone the repo on the VPS, then run:**

    ```bash
    chmod +x install_dokploy.sh
    ./install_dokploy.sh
    ```

3. The installer starts Docker, pulls Dokploy and Traefik, and binds the admin UI to `127.0.0.1:3000`.

***

## Accessing Dokploy (Locally via SSH Tunnel)

**Linux / macOS:**

```bash
./tunnel_to_dokploy.sh -k ~/.ssh/ssh_private_key -u root -h 
# Then open http://localhost:3000 in your browser
```

**Windows (PowerShell):**

```powershell
.\tunnel_to_dokploy.ps1 -KeyPath C:\Users\\.ssh\ssh_private_key -User root -Host 
# Then open http://localhost:3000 in your browser
```

***

## Optional: Make Dokploy Public (Not Recommended)

Only make the admin UI public if you add extra protections.

- Set up DNS for your domain to point to VPS.
- Edit `docker-compose.yml` and remove the `127.0.0.1:` prefix on app service ports.
- Add Traefik labels to the app service and enable Let’s Encrypt in Traefik.

***

## Troubleshooting

- If tunnel fails, check your SSH key, port forwarding settings, and local port availability.
- View container logs via `docker compose logs -f`.
- Check firewall rules with `ufw status verbose`.

***

## Notes

- The installer attempts to download an official Dokploy `docker-compose.yml`. If unavailable, it uses a minimal file binding to `127.0.0.1:3000`.

***

## Monitoring (Optional)

Dokploy’s monitoring stack is not installed by default. You can enable it for CPU, RAM, container, and disk usage metrics—all locally bound to `127.0.0.1`.

### Enable Monitoring via UI

1. Start your SSH tunnel:

    ```bash
    ssh -i ~/.ssh/your-key -L 3000:localhost:3000 root@YOUR_SERVER_IP
    ```

2. Visit `http://localhost:3000` in your browser.
3. Go to **Settings → Monitoring**, then click **Enable Monitoring**.

Dokploy sets up Prometheus, Grafana, cAdvisor, and Node Exporter.

### Manual Installation

Run these on the VPS if UI option is unavailable, each container bound to localhost only:


Prometheus

```bash
docker network create monitoring 2>/dev/null || true

docker run -d \
  --name prometheus \
  --network dokploy-network \
  --network monitoring \
  -p 127.0.0.1:9090:9090 \
  -v prometheus_data:/prometheus \
  prom/prometheus:latest
```



Grafana

```bash
docker run -d \
  --name grafana \
  --network dokploy-network \
  --network monitoring \
  -p 127.0.0.1:3001:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:latest
```



cAdvisor

```bash
docker run -d \
  --name cadvisor \
  --network monitoring \
  -p 127.0.0.1:8080:8080 \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  gcr.io/cadvisor/cadvisor:latest
```


**Restart Dokploy:**

```bash
docker restart dokploy
```

***

## Accessing Monitoring Services

Once tunnel and containers are running:

- **Dokploy:** `http://localhost:3000`
- **Grafana:** `http://localhost:3001` (user: `admin`, pass: `admin`)
- **Prometheus:** `http://localhost:9090`
- **cAdvisor:** `http://localhost:8080`

Extend your SSH tunnel with `-L` for additional ports as needed.

***

**secure-dokploy-local** offers robust local-only admin access for your Dokploy installation, with strong out-of-the-box hardening, optional monitoring stack, and easy SSH tunnel helpers for all platforms.