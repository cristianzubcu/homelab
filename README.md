# Homelab Media Server

A fully automated, VPN-protected media server stack running on Docker, managed with Ansible. One command sets up everything from scratch.

## What's Included

| Service | Port | Purpose |
|---------|------|---------|
| Radarr | 7878 | Movie management |
| Sonarr | 8989 | TV show management |
| Prowlarr | 9696 | Indexer management |
| qBittorrent | 8080 | Torrent client (runs through VPN) |
| Jellyfin | 8096 | Media streaming server |
| Bazarr | 6767 | Subtitle management |
| WireGuard | - | VPN tunnel (Mullvad) |
| FlareSolverr | 8191 | Cloudflare bypass for indexers |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3001 | Monitoring dashboards |
| Node Exporter | - | System metrics |
| cAdvisor | - | Container metrics |
| Portainer | 9443 | Docker management UI |
| Homepage | 3000 | Service dashboard |
| Tailscale | - | Remote access VPN |

## Architecture

All torrent traffic is routed through a WireGuard VPN (Mullvad). qBittorrent shares the WireGuard container's network, so no traffic leaks outside the VPN. All other services communicate locally.

Download flow:
```
Prowlarr (finds) → Radarr/Sonarr (decides) → qBittorrent (downloads via VPN)
  → _incoming folder → Radarr/Sonarr (imports & renames) → Jellyfin (streams)
```

## Prerequisites

- A Linux machine (Ubuntu/Debian) or Windows with WSL2
- Docker and Docker Compose installed
- A [Mullvad VPN](https://mullvad.net) subscription (for WireGuard config)
- A [Tailscale](https://tailscale.com) account (for remote access)

### Install Docker (Ubuntu/WSL)

```bash
sudo apt update
sudo apt install docker.io docker-compose-v2 -y
sudo usermod -aG docker $USER
```

Log out and back in for the group change to take effect.

### Install Ansible

```bash
sudo apt update
sudo apt install ansible -y
```

### Get Your Credentials

1. **Mullvad WireGuard key**: Go to [mullvad.net](https://mullvad.net/en/account/wireguard-config), select Linux, generate a config, and copy the `PrivateKey` value.

2. **Tailscale auth key**: Go to [Tailscale admin console](https://login.tailscale.com/admin/settings/keys) → Settings → Keys → Generate auth key. Make it reusable.

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/cristianzubcu/homelab.git
cd homelab
```

### 2. Run the setup playbook

```bash
ansible-playbook -i ansible/inventory.yml ansible/playbooks/setup.yml
```

It will prompt you for:

| Prompt | Description | Default |
|--------|-------------|---------|
| Homelab root directory | Where all Docker data is stored | `/mnt/c/Dockers` |
| Tailscale auth key | Your Tailscale authentication key | (hidden input) |
| Mullvad WireGuard private key | Your Mullvad VPN private key | (hidden input) |

Your server IP is detected automatically.

### 3. Configure the services

After the containers are running, you need to configure each service through its web UI. Open a browser and go to `http://YOUR_SERVER_IP:PORT` for each service.

#### qBittorrent (port 8080)

1. Check initial password: `docker logs qbittorrent`
2. Log in and go to Settings → Downloads
3. Create two categories (right-click left sidebar → Create category):
   - `radarr` → save path: `/data/movies/_incoming`
   - `sonarr` → save path: `/data/tvshows/_incoming`

#### Prowlarr (port 9696)

1. Add indexers: Indexers → Add → choose public trackers
2. Add FlareSolverr: Settings → Indexers → Add proxy → FlareSolverr → host: `http://flaresolverr:8191`
3. Connect to Radarr: Settings → Apps → Add → Radarr
4. Connect to Sonarr: Settings → Apps → Add → Sonarr

#### Radarr (port 7878)

1. Settings → Media Management → Add Root Folder: `/data/movies`
2. Settings → Download Clients → Add → qBittorrent:
   - Host: `wireguard`
   - Port: `8080`
   - Category: `radarr`

#### Sonarr (port 8989)

1. Settings → Media Management → Add Root Folder: `/data/tvshows`
2. Settings → Download Clients → Add → qBittorrent:
   - Host: `wireguard`
   - Port: `8080`
   - Category: `sonarr`

#### Jellyfin (port 8096)

1. Complete the setup wizard
2. Add libraries:
   - Movies → `/data/movies`
   - TV Shows → `/data/tvshows`

#### Bazarr (port 6767)

1. Settings → Radarr → host: `radarr`, port: `7878`, API key from Radarr → Settings → General
2. Settings → Sonarr → host: `sonarr`, port: `8989`, API key from Sonarr → Settings → General

#### Radarr/Sonarr → Jellyfin connection

1. In Radarr/Sonarr: Settings → Connect → Add → Jellyfin
2. Host: `jellyfin`, Port: `8096`
3. Use your Jellyfin username and password or API key

#### Grafana (port 3001)

1. Log in with `admin` / `admin`
2. Connections → Data Sources → Add → Prometheus → URL: `http://prometheus:9090` → Save & Test
3. Dashboards → Import → ID `1860` → Load → select Prometheus → Import (system monitoring)
4. Dashboards → Import → ID `193` → Load → select Prometheus → Import (container monitoring)

#### Tailscale

1. Go to [Tailscale admin console](https://login.tailscale.com/admin/machines)
2. Find "mediaserver" → three dots → Edit route settings → approve `192.168.2.0/24`
3. Install Tailscale on your phone/other devices to access services remotely

### 4. Verify VPN is working

```bash
docker exec qbittorrent curl -s https://am.i.mullvad.net/connected
```

Should confirm you're connected through Mullvad.

## Day-to-Day Usage

### Deploy changes after editing configs

```bash
ansible-playbook -i ansible/inventory.yml ansible/playbooks/deploy.yml
```

### Backup all service configs

```bash
ansible-playbook -i ansible/inventory.yml ansible/playbooks/backup.yml
```

### Check container status

```bash
docker ps
```

### View logs for a specific container

```bash
docker logs <container_name>
```

## Folder Structure

```
On the server:
/your/docker/dir/
├── docker-compose.yml          # Generated from template
├── media/
│   ├── movies/                 # Movie library
│   │   └── _incoming/          # Download landing zone
│   └── tvshows/                # TV show library
│       └── _incoming/          # Download landing zone
├── radarr/config/
├── sonarr/config/
├── jellyfin/config/
├── prowlarr/data/
├── qbittorrent/appdata/
├── bazarr/config/
├── wireguard/config/
├── prometheus/config/
├── grafana/data/
├── homepage/config/
├── portainer/data/
└── tailscale/state/
```

## Repo Structure

```
homelab/
├── README.md
├── .gitignore
├── docker-compose.yml.j2       # Docker Compose template
├── prometheus/
│   └── prometheus.yml          # Prometheus scrape config
├── homepage/
│   └── services.yaml.j2       # Homepage dashboard template
├── wireguard/
│   └── wg0.conf.j2            # WireGuard VPN template
└── ansible/
    ├── inventory.yml           # Ansible host config
    └── playbooks/
        ├── setup.yml           # Full setup from scratch
        ├── deploy.yml          # Deploy latest changes
        └── backup.yml          # Backup service configs
```

## Customization

- **Change VPN provider**: Edit `wireguard/wg0.conf.j2` with your provider's config
- **Add new services**: Add them to `docker-compose.yml.j2` and `homepage/services.yaml.j2`
- **Change monitoring**: Edit `prometheus/prometheus.yml` to add new scrape targets

## Troubleshooting

**Docker credential errors when pulling images:**
```bash
echo '{}' > ~/.docker/config.json
docker compose up -d
```

**WSL/NTFS mkdir errors:**
Create directories one level at a time. The Ansible playbooks already handle this.

**qBittorrent not accessible:**
Since qBittorrent runs through WireGuard's network, use `wireguard` as the hostname in Radarr/Sonarr download client settings, not `qbittorrent`.

**Jellyfin not finding new media:**
Set up a scheduled library scan: Dashboard → Scheduled Tasks → Scan All Libraries.

## License

MIT
