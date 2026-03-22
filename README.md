# Homelab

Automated media server stack with VPN-protected downloads, streaming, monitoring, and remote access.

qBittorrent downloads through a Mullvad WireGuard tunnel. Radarr and Sonarr handle media management. Jellyfin for streaming. Prometheus and Grafana for monitoring. Tailscale provides optional remote access. 

## Contents
- [Install](#install)
- [Setup](#setup)
- [Service Configuration](#service-configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## Install

THis works best on WSL2 and Windows.

### Dependencies

Install Docker
```
sudo apt update
sudo apt install docker.io docker-compose-v2 -y
sudo usermod -aG docker $USER
```
Log out and log back in for group changes to take effect.

Install Ansible
```
sudo apt install ansible -y
```

### Credentials

You will need:
- A **Mullvad** WireGuard private key. Generate a Linux config at https://mullvad.net/en/account/wireguard-config and copy the `PrivateKey` value.
- (Optional) A **Tailscale** auth key for remote access. Generate one at https://login.tailscale.com/admin/settings/keys. Make it reusable.

## Setup

```
git clone https://github.com/cristianzubcu/homelab.git
cd homelab
./setup.sh
```

The script checks for Docker and Ansible, then runs the playbook. It will ask for:
- Where to deploy (default: `~/homelab-data`)
- Your Mullvad WireGuard private key
- Whether to install Tailscale
- Your server IP (auto-detected, confirm or override)

Once done, all containers are running. Verify the VPN:
```
docker exec qbittorrent curl -s https://am.i.mullvad.net/connected
```

## Service Configuration

After deployment, configure each service through its web UI at `http://YOUR_IP:PORT`.

**qBittorrent** (`:8080`) — The temporary password is shown at the end of setup. Create two categories: `radarr` with path `/data/movies/_incoming` and `sonarr` with path `/data/tvshows/_incoming`.

**Prowlarr** (`:9696`) — Add indexers. Add FlareSolverr proxy at `http://flaresolverr:8191`. Connect Radarr and Sonarr under Settings → Apps.

**Radarr** (`:7878`) — Root folder: `/data/movies`. Download client: qBittorrent at host `wireguard`, port `8080`, category `radarr`.

**Sonarr** (`:8989`) — Root folder: `/data/tvshows`. Download client: qBittorrent at host `wireguard`, port `8080`, category `sonarr`.

**Jellyfin** (`:8096`) — Add libraries: Movies → `/data/movies`, TV Shows → `/data/tvshows`.

**Bazarr** (`:6767`) — Connect to Radarr and Sonarr using their API keys (Settings → General in each app).

**Grafana** (`:3001`) — Login `admin` / `admin`. Add Prometheus data source at `http://prometheus:9090`. Import dashboards `1860` (system) and `193` (containers).

**Tailscale** — If installed, approve the subnet route in the [admin console](https://login.tailscale.com/admin/machines).

## Usage

Deploy changes:
```
ansible-playbook -i ansible/inventory.yml ansible/playbooks/deploy.yml
```

Backup configs:
```
ansible-playbook -i ansible/inventory.yml ansible/playbooks/backup.yml
```

Restore from backup:
```
ansible-playbook -i ansible/inventory.yml ansible/playbooks/restore.yml
```

## Troubleshooting

- **Docker pull fails with credential error**: `echo '{}' > ~/.docker/config.json`
- **qBittorrent unreachable from Radarr/Sonarr**: Use `wireguard` as hostname, not `qbittorrent`.
- **Jellyfin not showing new media**: Dashboard → Scheduled Tasks → Scan All Libraries.
- **WSL mkdir errors**: Known NTFS issue. The playbooks handle this.
