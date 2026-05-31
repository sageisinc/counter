#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 7: Post-Deploy
# Fix wsgi issues and configure post-deploy
# ============================================================
set -e

source ~/kolla-venv/bin/activate

echo "=== Step 7: Post-Deploy Configuration ==="

# Fix libvirt auth (must be none for QEMU)
sudo sed -i 's/auth_tcp = "sasl"/auth_tcp = "none"/' \
  /etc/kolla/nova-libvirt/libvirtd.conf 2>/dev/null || true

# Fix nova-compute libvirt connection
docker restart nova_libvirt nova_compute 2>/dev/null || true
sleep 15

# Fix placement wsgi
sudo sed -i 's|module = placement.wsgi.api:application|mount = /=placement.wsgi:init_application()\nmanage-script-name = true|' \
  /etc/kolla/placement-api/placement-api-uwsgi.ini 2>/dev/null || true

# Fix glance wsgi
sudo sed -i 's|module = glance.wsgi.api:application|mount = /=glance.common.wsgi_app:init_app()\nmanage-script-name = true|' \
  /etc/kolla/glance-api/glance-api-uwsgi.ini 2>/dev/null || true

# Fix heat wsgi
sudo tee /etc/kolla/heat-api/heat-api-uwsgi.ini << 'INIEOF'
[uwsgi]
add-header = Connection: close
buffer-size = 65535
die-on-term = true
enable-threads = true
exit-on-reload = false
hook-master-start = unix_signal:15 gracefully_kill_them_all
http = $(grep -o '[0-9.]*' /etc/kolla/heat-api/heat.conf | head -1):8004
http-auto-chunked = true
http-chunked-input = true
http-raw-body = true
lazy-apps = true
logto2 = /var/log/kolla/heat/heat-api-uwsgi.log
master = true
mount = /=heat.httpd.heat_api:init_application()
manage-script-name = true
processes = 2
socket-timeout = 30
thunder-lock = true
uid = heat
worker-reload-mercy = 80
INIEOF

# Fix log permissions
sudo mkdir -p /var/log/kolla/horizon /var/log/kolla/heat
sudo chown -R 42420:42420 /var/log/kolla/horizon 2>/dev/null || true
sudo chown -R 42418:42418 /var/log/kolla/heat 2>/dev/null || true

# Restart services
docker restart placement_api glance_api heat_api heat_api_cfn horizon 2>/dev/null || true
sleep 15

# Run post-deploy
cd ~/openstack
kolla-ansible post-deploy -i multinode --configdir .

# Install OpenStack client
pip install python-openstackclient

# Source credentials
source ~/openstack/admin-openrc.sh

echo ""
echo "=== Verifying deployment ==="
openstack service list
openstack compute service list

echo ""
echo "=== Step 7 Complete ==="
echo "Next: Run 08-setup-network.sh to configure networking"
