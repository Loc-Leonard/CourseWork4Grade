#!/usr/bin/env bash
set -e

ISSABEL_IP="192.168.88.12"
NET_IF="eth1"

PROFILE_101="/home/vagrant/.baresip-101"
PROFILE_102="/home/vagrant/.baresip-102"

CFG101="${PROFILE_101}/config"
CFG102="${PROFILE_102}/config"

sudo apt-get update
sudo apt-get install -y baresip

sudo -u vagrant mkdir -p "${PROFILE_101}" "${PROFILE_102}"

# accounts (по одному на профиль)
cat <<EOF | sudo -u vagrant tee "${PROFILE_101}/accounts" >/dev/null
<sip:101@${ISSABEL_IP}>;auth_pass=pass101;regint=300;outbound=sip:${ISSABEL_IP};transport=udp
EOF

cat <<EOF | sudo -u vagrant tee "${PROFILE_102}/accounts" >/dev/null
<sip:102@${ISSABEL_IP}>;auth_pass=pass102;regint=60;outbound=sip:${ISSABEL_IP};transport=udp
EOF

# Сгенерировать дефолтный config (один раз на профиль)
if [ ! -f "${CFG101}" ]; then
  sudo -u vagrant baresip -f "${PROFILE_101}" -d >/tmp/baresip-init-101.log 2>&1 || true
  sudo -u vagrant pkill -u vagrant -x baresip 2>/dev/null || true
fi

if [ ! -f "${CFG102}" ]; then
  sudo -u vagrant baresip -f "${PROFILE_102}" -d >/tmp/baresip-init-102.log 2>&1 || true
  sudo -u vagrant pkill -u vagrant -x baresip 2>/dev/null || true
fi

# Функция: заменить/добавить параметр в config без очистки
set_cfg_kv () {
  local file="$1"
  local key="$2"
  local val="$3"

  sudo -u vagrant sed -i "/^${key}[[:space:]]/d" "$file" || true
  echo "${key}                 ${val}" | sudo -u vagrant tee -a "$file" >/dev/null
}

# Важно: отключаем суффикс в Contact user
# (иначе появляется user вида 101-0x..., и Asterisk может не найти AOR)
set_cfg_kv "${CFG101}" "cuser_random" "no"
set_cfg_kv "${CFG102}" "cuser_random" "no"

# Фиксируем интерфейс и локальные порты
set_cfg_kv "${CFG101}" "net_interface" "${NET_IF}"
set_cfg_kv "${CFG101}" "sip_listen" "0.0.0.0:5101"

set_cfg_kv "${CFG102}" "net_interface" "${NET_IF}"
set_cfg_kv "${CFG102}" "sip_listen" "0.0.0.0:5105"