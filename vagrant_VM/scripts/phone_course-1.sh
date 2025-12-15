#!/usr/bin/env bash
set -e

sudo apt-get update
sudo apt-get install -y baresip

sudo -u vagrant mkdir -p /home/vagrant/.baresip

# Два аккаунта: 101 и 102
cat << 'EOF' | sudo -u vagrant tee /home/vagrant/.baresip/accounts >/dev/null
<sip:101@192.168.88.12>;auth_pass=pass101;regint=60;outbound=sip:192.168.88.12;transport=udp
<sip:102@192.168.88.12>;auth_pass=pass102;regint=60;outbound=sip:192.168.88.12;transport=udp
EOF

# Настройки baresip (важно указать интерфейс с 192.168.88.10)
sudo -u vagrant mkdir -p /home/vagrant/.baresip
if ! grep -q '^net_interface' /home/vagrant/.baresip/config 2>/dev/null; then
  echo "net_interface            eth1" | sudo -u vagrant tee -a /home/vagrant/.baresip/config >/dev/null
fi