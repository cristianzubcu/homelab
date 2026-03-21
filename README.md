# Homelab

My media server setup running on Docker with Ansible automation. Everything routes torrent traffic through a Mullvad VPN, streams via Jellyfin, and is accessible remotely through Tailscale.

## Stack

- **Radarr / Sonarr / Prowlarr / Bazarr** — media management
- **qBittorrent** — torrents (routed through WireGuard VPN)
- **Jellyfin** — media streaming
- **Prometheus / Grafana / cAdvisor / Node Exporter** — monitoring
- **Portainer** — Docker management
- **Homepage** — dashboard for all services
- **Tailscale** — remote access
- **FlareSolverr** — Cloudflare bypass for indexers

## How it works

Prowlarr finds releases → Radarr/Sonarr grab them → qBittorrent downloads through VPN → files land in `_incoming/` → Radarr/Sonarr import and rename → Jellyfin picks them up.

## Requirements

- Linux or WSL2
- Docker + Docker Compose
- Ansible
- Mullvad VPN subscription
- Tailscale account

## Setup

Clone the repo and run:

```
ansible-playbook -i ansible/inventory.yml ansible/playbooks/setup.yml
```

It'll ask for your paths and credentials. After containers are up, configure each service through its web UI — the playbook handles infrastructure, not app-level settings.

### Service configuration

**qBittorrent** (`:8080`) — create categories `radarr` → `/data/movies/_incoming` and `sonarr` → `/data/tvshows/_incoming`. Check `docker logs qbittorrent` for the initial password.

**Radarr** (`:7878`) — root folder `/data/movies`, download client qBittorrent at host `wireguard:8080`, category `radarr`.

**Sonarr** (`:8989`) — root folder `/data/tvshows`, download client qBittorrent at host `wireguard:8080`, category `sonarr`.

**Prowlarr** (`:9696`) — add indexers, connect FlareSolverr at `http://flaresolverr:8191`, add Radarr and Sonarr under Apps.

**Jellyfin** (`:8096`) — add libraries: Movies → `/data/movies`, TV Shows → `/data/tvshows`.

**Bazarr** (`:6767`) — connect to Radarr and Sonarr using their API keys.

**Grafana** (`:3001`) — login `admin/admin`, add Prometheus datasource at `http://prometheus:9090`, import dashboards `1860` and `193`.

**Tailscale** — approve the subnet route in the admin console.

### Verify VPN

```
docker exec qbittorrent curl -s https://am.i.mullvad.net/connected
```

## Other playbooks

```
# deploy after making changes
ansible-playbook -i ansible/inventory.yml ansible/playbooks/deploy.yml

# backup configs
ansible-playbook -i ansible/inventory.yml ansible/playbooks/backup.yml
```

## Notes

- qBittorrent shares WireGuard's network, so Radarr/Sonarr reach it via hostname `wireguard`, not `qbittorrent`
- If Docker image pulls fail with credential errors: `echo '{}' > ~/.docker/config.json`
- WSL/NTFS can be weird with nested directory creation — the Ansible playbooks handle this
