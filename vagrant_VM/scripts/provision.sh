apt-get update
apt-get -y upgrade
apt-add-repository ppa:ondrej/php -y
apt-get update
apt-get install -y software-properties-common curl zip

#!/usr/bin/env bash
set -e
HOSTS=(
    "192.168.88.10  course-1"
    "192.168.88.11  course-2"
    "192.168.88.12 issabel"
)

for LINE in "${HOSTS[@]}"; do
  if ! grep -qF "$LINE" /etc/hosts; then
    echo "$LINE" | sudo tee -a /etc/hosts > /dev/null
  fi
done