#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 8: Setup Network
# IMPORTANT: Uses ens37 (host-only) for provider network
# Floating IPs are on VMware VMnet1 subnet (e.g. 192.168.56.x)
# ============================================================
set -e

source ~/kolla-venv/bin/activate
source ~/openstack/admin-openrc.sh

# Variables - must match VMware VMnet1 (host-only) subnet
PROVIDER_NETWORK="192.168.56.0/24"
PROVIDER_GW="192.168.56.2"        # VMware VMnet1 gateway
FLOATING_START="192.168.56.200"
FLOATING_END="192.168.56.250"
TENANT_NETWORK="10.0.0.0/24"
TENANT_GW="10.0.0.1"
DNS="8.8.8.8"

echo "=== Step 8: Configure OpenStack Networking ==="

# Create external/provider network on ens37 subnet
echo "Creating external network..."
openstack network create \
  --provider-network-type flat \
  --provider-physical-network physnet1 \
  --external --share \
  public 2>/dev/null || echo "public network already exists"

openstack subnet create \
  --network public \
  --subnet-range $PROVIDER_NETWORK \
  --gateway $PROVIDER_GW \
  --dns-nameserver $DNS \
  --allocation-pool start=$FLOATING_START,end=$FLOATING_END \
  --no-dhcp \
  public-subnet 2>/dev/null || echo "public-subnet already exists"

# Create tenant network
echo "Creating tenant network..."
openstack network create demo-network 2>/dev/null || echo "demo-network already exists"

openstack subnet create \
  --network demo-network \
  --subnet-range $TENANT_NETWORK \
  --gateway $TENANT_GW \
  --dns-nameserver $DNS \
  demo-subnet 2>/dev/null || echo "demo-subnet already exists"

# Create router
echo "Creating router..."
openstack router create demo-router 2>/dev/null || echo "demo-router already exists"
openstack router set --external-gateway public demo-router 2>/dev/null || true
openstack router add subnet demo-router demo-subnet 2>/dev/null || true

# Upload Ubuntu image
echo "Uploading Ubuntu 24.04 image..."
if ! openstack image show ubuntu-24.04 &>/dev/null; then
  wget -q https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img \
    -O /tmp/ubuntu-24.04.img
  openstack image create \
    --disk-format qcow2 --container-format bare \
    --public --file /tmp/ubuntu-24.04.img \
    ubuntu-24.04
  rm /tmp/ubuntu-24.04.img
  echo "  ✓ Ubuntu 24.04 image uploaded"
else
  echo "  ✓ Ubuntu 24.04 image already exists"
fi

# Create flavor
echo "Creating flavors..."
openstack flavor create --ram 512  --disk 5  --vcpus 1 m1.tiny   2>/dev/null || true
openstack flavor create --ram 1024 --disk 10 --vcpus 1 m1.small  2>/dev/null || true
openstack flavor create --ram 2048 --disk 20 --vcpus 2 m1.medium 2>/dev/null || true

# Create default security group rules
echo "Adding security group rules..."
openstack security group rule create default \
  --protocol icmp --ingress 2>/dev/null || true
openstack security group rule create default \
  --protocol tcp --dst-port 22 --ingress 2>/dev/null || true
openstack security group rule create default \
  --protocol tcp --dst-port 80 --ingress 2>/dev/null || true

# Enable nova-compute
openstack compute service set --enable $(hostname) nova-compute 2>/dev/null || true

echo ""
echo "=== Networking Setup Complete ==="
echo ""
echo "Networks:"
openstack network list
echo ""
echo "Flavors:"
openstack flavor list
echo ""
echo "Images:"
openstack image list
echo ""
echo "=== OpenStack is ready! ==="
echo "Horizon: http://$(grep kolla_internal_vip ~/openstack/globals.yml | awk '{print $2}' | tr -d '\"')"
echo "Username: admin"
echo "Password: $(grep keystone_admin_password ~/openstack/passwords.yml | awk '{print $2}')"
