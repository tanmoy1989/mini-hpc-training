#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

NODE01_IP=$(vagrant ssh node01 -c "hostname -I" 2>/dev/null | awk '{print $1}')
NODE02_IP=$(vagrant ssh node02 -c "hostname -I" 2>/dev/null | awk '{print $1}')

if [[ -z "$NODE01_IP" || -z "$NODE02_IP" ]]; then
    echo "[ERROR] Could not determine the IP addresses of both nodes."
    exit 1
fi

cat > inventory.ini <<EOF_INVENTORY
[cluster]
node01 ansible_host=$NODE01_IP ansible_user=vagrant ansible_ssh_private_key_file=$ROOT_DIR/.vagrant/machines/node01/vmware_desktop/private_key
node02 ansible_host=$NODE02_IP ansible_user=vagrant ansible_ssh_private_key_file=$ROOT_DIR/.vagrant/machines/node02/vmware_desktop/private_key
EOF_INVENTORY

echo "[OK] Ansible inventory generated:"
cat inventory.ini
