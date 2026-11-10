
#!/bin/bash

set -euo pipefail

# Identify the repository directory
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "=============================================================="
echo " Mini-HPC Training Environment Deployment"
echo "=============================================================="
echo
echo " Designed by:"
echo " Dr. Tanmoy Chakraborty"
echo " Research Software Specialist"
echo " Scientific Computing Research Technology Platform"
echo " University of Warwick"
echo
echo "=============================================================="
echo

INSTALL_GUIDE="docs/installation-guide.md"

# Check required commands
check_command() {
    local cmd="$1"

    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[OK] $cmd is installed"
    else
        echo "[ERROR] $cmd is not installed"
        echo

        case "$cmd" in
            ansible|ansible-galaxy)
                echo "Install Ansible on Ubuntu using:"
                echo "  sudo apt update"
                echo "  sudo apt install -y ansible"
                echo
                echo "Note: ansible-galaxy is included with Ansible."
                ;;
            vagrant)
                echo "Install Vagrant using the official HashiCorp instructions."
                ;;
            *)
                echo "Please install $cmd before continuing."
                ;;
        esac

        echo
        echo "For detailed instructions, see: $INSTALL_GUIDE"
        exit 1
    fi
}

echo "Checking host prerequisites..."

check_command vagrant
check_command ansible
check_command ansible-galaxy
check_command python3

echo
echo "Checking Vagrant VMware provider..."

if vagrant plugin list | grep -q '^vagrant-vmware-desktop '; then
    echo "[OK] Vagrant VMware Desktop plugin is installed"
else
    echo "[ERROR] Vagrant VMware Desktop plugin is missing"
    echo "Install it using:"
    echo "  vagrant plugin install vagrant-vmware-desktop"
    echo
    echo "The Vagrant VMware Utility is also required."
    echo "For instructions, see: $INSTALL_GUIDE"
    exit 1
fi

echo
echo "Installing required Ansible collections..."

ansible-galaxy collection install -r ansible/requirements.yml

echo
echo "All prerequisite checks passed."

echo
echo "=========================================="
echo " Creating the mini-HPC virtual machines"
echo "=========================================="

vagrant up --provider=vmware_desktop

echo
echo "Checking virtual machine status..."
vagrant status

echo
echo "Virtual machine provisioning completed."

echo
echo "=========================================="
echo " Discovering mini-HPC node IP addresses"
echo "=========================================="

bash "$ROOT_DIR/get-ips.sh"

echo
echo "Node IP discovery completed."

echo
echo "=========================================="
echo " Configuring the mini-HPC cluster"
echo "=========================================="

ansible-playbook -i "$ROOT_DIR/inventory.ini" \
    "$ROOT_DIR/ansible/site.yml"

echo
echo "=========================================="
echo " Mini-HPC deployment completed!"
echo "=========================================="
