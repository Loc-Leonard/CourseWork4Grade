#!/usr/bin/env bash
set -e

sudo apt-get update
sudo apt-get install -y baresip

# Конфиг для пользователя vagrant
sudo -u vagrant mkdir -p /home/vagrant/.baresip

# Один аккаунт 103 на Issabel 192.168.88.12
cat << 'EOF' | sudo -u vagrant tee /home/vagrant/.baresip/accounts >/dev/null
<sip:103@192.168.88.12>;auth_pass=pass103;regint=60;outbound=sip:192.168.88.12;transport=udp
EOF

if ! grep -q '^net_interface' /home/vagrant/.baresip/config 2>/dev/null; then
  echo "net_interface            eth1" | sudo -u vagrant tee -a /home/vagrant/.baresip/config >/dev/null
fi