# Install Addon Services to Pi-hole server

A set of install scripts for installing addons to Pi-hole server.  These can be run then
independently or you can run the base setup script and be prompted for each application.

## Applications

* [PADD](https://github.com/pi-hole/PADD)
* [Nginx Proxy Manager](https://nginxproxymanager.com/)
* [Heimdall](https://heimdall.site/)
* [Speedtest CLI](https://www.speedtest.net/apps/cli)

## Instructions

```sh
curl -sSL https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/setup.sh --output addon_setup.sh
chmod +x addon_setup.sh
./addon_setup.sh
```
