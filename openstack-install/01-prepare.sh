#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 1: Prepare
# Ubuntu 24.04 LTS on VMware with 2 NICs
# ens33 = NAT (management/SSH) 
# ens37 = Host-only (OpenStack provider network)
# ============================================================
set -e

echo "=== Step 1: System Preparation ==="

# Variables - EDIT THESE
MGMT_IFACE="ens33"
MGMT_IP="192.168.131.10"
MGMT_GW="192.168.131.2"
PROVIDER_IFACE="ens37"
PROVIDER_IP="192.168.56.10"     # VMware VMnet1 subnet
PROVIDER_NETWORK="192.168.56.0/24"
VIP="192.168.56.100"            # OpenStack VIP (on provider network)
FLOATING_START="192.168.56.200"
FLOATING_END="192.168.56.250"
HOSTNAME="openstack-node"

echo "Management interface:  $MGMT_IFACE ($MGMT_IP)"
echo "Provider interface:    $PROVIDER_IFACE ($PROVIDER_IP)"
echo "VIP:                   $VIP"
echo "Floating IPs:          $FLOATING_START - $FLOATING_END"
echo ""

# 1. Set hostname
sudo hostnamectl set-hostname $HOSTNAME
echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts

# 2. Configure static IPs with netplan - PROTECT ens33 from OVS
sudo tee /etc/netplan/50-cloud-init.yaml << EOF
network:
  version: 2
  ethernets:
    ${MGMT_IFACE}:
      dhcp4: false
      addresses:
        - ${MGMT_IP}/24
      routes:
        - to: default
          via: ${MGMT_GW}
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    ${PROVIDER_IFACE}:
      dhcp4: false
      addresses:
        - ${PROVIDER_IP}/24
EOF
sudo chmod 600 /etc/netplan/50-cloud-init.yaml
sudo netplan apply

# 3. Install prerequisites
sudo apt-get update
sudo apt-get install -y \
  python3-pip python3-venv git curl \
  openssh-server docker.io

# 4. Configure SSH
sudo systemctl enable ssh
sudo systemctl start ssh
echo "sage ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/sage
sudo chmod 440 /etc/sudoers.d/sage

# 5. Configure Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# 6. Generate SSH key for kolla-ansible
ssh-keygen -t ed25519 -f ~/.ssh/openstack_key -N "" -q
cat ~/.ssh/openstack_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 7. Fix DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

echo ""
echo "=== Step 1 Complete ==="
echo "IMPORTANT: Check VMware Virtual Network Editor"
echo "VMnet1 (Host-only) subnet should be: 192.168.56.0/24"
echo "If different, update PROVIDER_IP, VIP, and FLOATING range above"
echo ""
echo "Next: Run 02-install-kolla.sh"
