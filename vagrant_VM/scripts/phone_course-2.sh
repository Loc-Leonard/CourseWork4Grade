#!/usr/bin/env bash
set -e

ISSABEL_IP="192.168.88.12"
NET_IF="eth1"
PROFILE="/home/vagrant/.baresip-103"
CFG="${PROFILE}/config"

sudo apt-get update
sudo apt-get install -y baresip

sudo -u vagrant mkdir -p "${PROFILE}"

cat <<EOF | sudo -u vagrant tee "${PROFILE}/accounts" >/dev/null
<sip:103@${ISSABEL_IP}>;auth_pass=pass103;regint=60;outbound=sip:${ISSABEL_IP};transport=udp
EOF

if [ ! -f "${CFG}" ]; then
  sudo -u vagrant baresip -f "${PROFILE}" -d >/tmp/baresip-init-103.log 2>&1 || true
  sudo -u vagrant pkill -u vagrant -x baresip 2>/dev/null || true
fi

sudo -u vagrant sed -i '/^cuser_random[[:space:]]/d' "${CFG}" || true
echo "cuser_random            no" | sudo -u vagrant tee -a "${CFG}" >/dev/null

sudo -u vagrant sed -i '/^net_interface[[:space:]]/d' "${CFG}" || true
echo "net_interface           ${NET_IF}" | sudo -u vagrant tee -a "${CFG}" >/dev/null

sudo -u vagrant sed -i '/^sip_listen[[:space:]]/d' "${CFG}" || true
echo "sip_listen              0.0.0.0:5103" | sudo -u vagrant tee -a "${CFG}" >/dev/null