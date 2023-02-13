#!/usr/bin/env bash

sudo wget -O ~/padd.sh -N https://raw.githubusercontent.com/jpmck/PADD/master/padd.sh \
&& sudo chmod +x ~/padd.sh \
&& sudo cp ~/padd.sh /usr/local/bin/padd \
&& sudo cp ~/padd.sh /home/pihole/padd.sh \
&& sudo chown pihole:pihole /home/pihole/padd.sh
