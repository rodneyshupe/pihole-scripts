# Install Nginx Proxy Manager on Pi-hole server

This script will install a docker container for [Heimdall](https://heimdall.site/) on the same
server you are running Pi-hole.

## Install

To execute this script you can either [download](https://raw.githubusercontent.com/rodneyshupe/pihole-addons/heimdall/main/install.sh)
and execute the script. or just execute the following:

```sh
curl -sSL https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/heimdall/install.sh | bash
```

### Notes

* This implementation uses `docker-compose` so if it is not installed when you run the script
  it will prompt you to install it first, then reboot.  Once that is complete you will need to
  execute the script again.
