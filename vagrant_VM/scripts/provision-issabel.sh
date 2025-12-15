#!/usr/bin/env bash
set -e

sudo -i << 'EOF'


cat > /etc/asterisk/pjsip_custom.conf << 'EOCFG'
[101-endpoint]
type=endpoint
context=from-internal
disallow=all
allow=ulaw,alaw
auth=auth101
aors=101-aor

[auth101]
type=auth
auth_type=userpass
username=101
password=pass101

[101-aor]
type=aor
max_contacts=5

[102-endpoint]
type=endpoint
context=from-internal
disallow=all
allow=ulaw,alaw
auth=auth102
aors=102-aor

[auth102]
type=auth
auth_type=userpass
username=102
password=pass102

[102-aor]
type=aor
max_contacts=5

[103-endpoint]
type=endpoint
context=from-internal
disallow=all
allow=ulaw,alaw
auth=auth103
aors=103-aor

[auth103]
type=auth
auth_type=userpass
username=103
password=pass103

[103-aor]
type=aor
max_contacts=5
EOCFG


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


asterisk -rx "pjsip reload"
asterisk -rx "dialplan reload"

EOF
