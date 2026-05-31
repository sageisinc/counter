#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 3: Configure
# ============================================================
set -e

source ~/kolla-venv/bin/activate

echo "=== Step 3: Configure OpenStack ==="

# Variables - must match Step 1
MGMT_IFACE="ens33"
MGMT_IP="192.168.131.10"
PROVIDER_IFACE="ens37"
VIP="192.168.56.100"

# Create globals.yml
cat > ~/openstack/globals.yml << EOF
# ── Core ──────────────────────────────────────────────────
kolla_base_distro: "ubuntu"
openstack_release: "2024.2"

# ── Network ───────────────────────────────────────────────
# IMPORTANT: ens33 = management (SSH), ens37 = provider (OVN)
# NEVER use ens33 as neutron_external_interface
kolla_internal_vip_address: "${VIP}"
kolla_external_vip_address: "${VIP}"
network_interface: "${MGMT_IFACE}"
neutron_external_interface: "${PROVIDER_IFACE}"

# ── Neutron/OVN ───────────────────────────────────────────
neutron_plugin_agent: "ovn"
enable_neutron_provider_networks: "yes"

# ── Nova ──────────────────────────────────────────────────
nova_compute_virt_type: "qemu"
enable_nova_libvirt_container: "yes"
libvirt_enable_sasl: "no"

# ── Services ──────────────────────────────────────────────
enable_cinder: "no"
enable_heat: "yes"
enable_horizon: "yes"
enable_haproxy: "yes"
enable_prometheus: "no"
enable_grafana: "no"
enable_proxysql: "no"

# ── Docker ────────────────────────────────────────────────
docker_registry: "quay.io"
docker_namespace: "openstack.kolla"
use_test_images: "yes"

# ── Database ──────────────────────────────────────────────
database_address: "${MGMT_IP}"

# ── Workers ───────────────────────────────────────────────
openstack_service_workers: 2

# ── Nova cell transport ────────────────────────────────────
nova_cell_rpc_transport_url: "rabbit://openstack:{{ rabbitmq_password }}@${MGMT_IP}:5672//"
nova_cell_notify_transport_url: "rabbit://openstack:{{ rabbitmq_password }}@${MGMT_IP}:5672//"
EOF

# Create inventory
cat > ~/openstack/multinode << EOF
[baremetal]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[control]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[network]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[compute]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[monitoring]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[storage]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[deployment]
localhost ansible_connection=local

[loadbalancer]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[rabbitmq]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[mariadb]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[keystone]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[glance-api]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-api]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-conductor]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-scheduler]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-compute]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-novncproxy]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-metadata]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-spicehtml5proxy]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-serialproxy]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[nova-ssh]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-server]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-rpc-server]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-l3-agent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-dhcp-agent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-metadata-agent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-ovn-metadata-agent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-ovn-agent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-ovn-maintenance-worker]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-bgp-dragent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-metering-agent]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[neutron-periodic-worker]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[placement-api]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[heat-api]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[heat-api-cfn]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[heat-engine]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[horizon]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[memcached]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[openvswitch]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[ovn-controller]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[ovn-nb-db]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[ovn-sb-db]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[ovn-northd]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[ovn-controller-network]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[ovn-controller-compute]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[kolla_toolbox]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[cron]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[fluentd]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

[kolla_logs]
${MGMT_IP} ansible_user=sage ansible_private_key_file=~/.ssh/openstack_key ansible_become=true

# Empty groups required by kolla-ansible
[bifrost]
[tls-backend]
[ovn-sb-db-relay]
[etcd]
[valkey]
[tacker]
[manila-share]
[ironic-conductor]
[ironic-neutron-agent]
[neutron-infoblox-ipam-agent]
[neutron-ovn-vpn-agent]
EOF

echo ""
echo "=== Step 3 Complete ==="
echo "Next: Run 04-patches.sh"
