#!/usr/bin/env bash
set -e

# 1) Конфиг endpoint'ов: матч по username (из REGISTER) + запасной матч по IP
cat > /etc/asterisk/pjsip_custom.conf <<'EOCFG'
[101]
type=aor
max_contacts=1
remove_existing=yes

[auth101]
type=auth
auth_type=userpass
username=101
password=pass101

[101]
type=endpoint
context=from-internal
disallow=all
allow=ulaw,alaw
auth=auth101
aors=101
identify_by=username,ip


[102]
type=aor
max_contacts=1
remove_existing=yes

[auth102]
type=auth
auth_type=userpass
username=102
password=pass102

[102]
type=endpoint
context=from-internal
disallow=all
allow=ulaw,alaw
auth=auth102
aors=102
identify_by=username,ip


[103]
type=aor
max_contacts=1
remove_existing=yes

[auth103]
type=auth
auth_type=userpass
username=103
password=pass103

[103]
type=endpoint
context=from-internal
disallow=all
allow=ulaw,alaw
auth=auth103
aors=103
identify_by=username,ip
EOCFG

# 2) Убедиться, что модуль идентификации по user загружен
asterisk -rx "module show like res_pjsip_endpoint_identifier_user.so" | grep -q "Running" \
  || asterisk -rx "module load res_pjsip_endpoint_identifier_user.so" || true

cat > /etc/asterisk/queues_custom.conf << 'EOCFG'
[200]
musicclass=default
strategy=rrmemory
timeout=30
retry=5
wrapuptime=0
maxlen=0
member => PJSIP/101-endpoint
member => PJSIP/102-endpoint
member => PJSIP/103-endpoint
EOCFG

cat > /etc/asterisk/extensions_custom.conf << 'EOCFG'
[from-internal-custom]
exten => 7000,1,Answer()
 same => n,Queue(200,t)
 same => n,Hangup()
EOCFG

# Отключаем firewall на Issabel (firewalld или iptables)
if systemctl list-unit-files | grep -q firewalld.service; then
  systemctl stop firewalld || true
  systemctl disable firewalld || true
fi

if systemctl list-unit-files | grep -q iptables.service; then
  systemctl stop iptables || true
  systemctl disable iptables || true
fi

# На старых системах может быть service/chkconfig
if command -v service >/dev/null 2>&1; then
  service iptables stop 2>/dev/null || true
fi
if command -v chkconfig >/dev/null 2>&1; then
  chkconfig iptables off 2>/dev/null || true
fi

asterisk -rx "pjsip reload"
asterisk -rx "dialplan reload"