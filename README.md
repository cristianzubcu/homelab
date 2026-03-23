# Homelab

Homelab setup using Docker Compose and Ansible.

It includes Jellyfin, qBittorrent, Prometheus, Grafana, Portainer, and WireGuard. Tailscale can also be enabled for private remote access.

## Contents
- [Install](#install)
- [Setup](#setup)
- [Service Configuration](#service-configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## Install

This setup is intended to be installed on WSL2.

### Dependencies

**Windows users:** Install WSL2 first. Open PowerShell as Administrator and run:
```
wsl --install
```
Restart your computer. On first boot, WSL will ask you to create a username and password. All commands below must be run inside the WSL terminal.

**Install Docker**
```
sudo apt update
sudo apt install docker.io docker-compose-v2 -y
sudo usermod -aG docker $USER
```
Log out and log back in for group changes to take effect.

**Install Ansible**
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
- Your Mullvad WireGuard private key

Non-secret defaults now live in `ansible/group_vars/all.yml`. Adjust that file to change:

- deployment path
- timezone
- whether Tailscale should be installed
- optional hostname override for generated service URLs
- Tailscale hostname and advertised routes

Once done, all containers are running. Verify the VPN:
```
docker exec wireguard curl -s https://am.i.mullvad.net/connected
```

## Service Configuration

After deployment, configure each service through its web UI at `http://YOUR_IP:PORT`.

**Homepage** (`:3000`) — Dashboard for the services in this stack.

**Jellyfin** (`:8096`) — Media server. Add libraries such as Movies -> `/data/movies` and TV Shows -> `/data/tvshows`.

**Grafana** (`:3001`) — Login `admin` / `admin`. Add Prometheus data source at `http://prometheus:9090`. Import dashboards `1860` (system) and `193` (containers).

**Portainer** (`:9443`) — Container management UI.

**qBittorrent** (`:8080`) — The temporary password is shown at the end of setup.

**Prowlarr** (`:9696`) — Add indexers. Add FlareSolverr proxy at `http://flaresolverr:8191`. Connect Radarr and Sonarr under Settings -> Apps.

**Radarr** (`:7878`) — Root folder: `/data/movies`. Download client: qBittorrent at host `wireguard`, port `8080`.

**Sonarr** (`:8989`) — Root folder: `/data/tvshows`. Download client: qBittorrent at host `wireguard`, port `8080`.

**Bazarr** (`:6767`) — Connect to Radarr and Sonarr using their API keys.

**Tailscale** — If installed, approve the subnet route in the [admin console](https://login.tailscale.com/admin/machines).

## Homelab API

A separate management dashboard is available at [homelab-api](https://github.com/cristianzubcu/homelab-api). Deploy it after configuring your services if you want it.

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
- **Jellyfin not showing new media**: Dashboard -> Scheduled Tasks -> Scan All Libraries.
- **WSL mkdir errors**: Known NTFS issue. The playbooks handle this.
