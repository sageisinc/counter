# OpenStack Single-Node Installation Guide
## Ubuntu 24.04 LTS + VMware Workstation + Kolla-Ansible 22

---

## Prerequisites

### VMware VM Specs
| Resource | Value |
|----------|-------|
| vCPUs | 6 |
| RAM | 20 GB |
| Disk | 150 GB |
| Network Adapter 1 | NAT → `ens33` (management/SSH) |
| Network Adapter 2 | Host-only → `ens37` (OpenStack provider) |

### Critical VMware Setting
In **Edit → Virtual Network Editor**:
- **VMnet8 (NAT)**: Note the subnet (e.g., `192.168.131.0/24`)
- **VMnet1 (Host-only)**: Note the subnet (e.g., `192.168.56.0/24`)

⚠️ **NEVER use `ens33` (NAT) as `neutron_external_interface`** — OVS will take over the interface and break SSH!

---

## Installation Steps

### Step 1 — Prepare the system
```bash
# Edit variables at top of script first!
nano 01-prepare.sh

chmod +x *.sh
./01-prepare.sh
```

**Edit these variables to match your VMware setup:**
```bash
MGMT_IP="192.168.131.10"      # Your ens33 IP
MGMT_GW="192.168.131.2"       # VMware NAT gateway
PROVIDER_IP="192.168.56.10"   # Your ens37 IP (VMnet1 subnet)
VIP="192.168.56.100"          # OpenStack VIP (on ens37 subnet)
FLOATING_START="192.168.56.200"
FLOATING_END="192.168.56.250"
```

### Step 2 — Install Kolla-Ansible
```bash
./02-install-kolla.sh
source ~/kolla-venv/bin/activate
```

### Step 3 — Configure OpenStack
```bash
./03-configure.sh
```
This creates `globals.yml` and `multinode` inventory.

### Step 4 — Apply Patches
```bash
./04-patches.sh
```
Fixes known issues with kolla-ansible 22 on Ubuntu 24.04.

### Step 5 — Build Docker Images
```bash
./05-build-images.sh
```
Installs uwsgi in kolla venv for all services that need it.
Takes 10-15 minutes.

### Step 6 — Deploy OpenStack
```bash
./06-deploy.sh
```
Takes 20-40 minutes. If it fails, just re-run — kolla-ansible is idempotent.

### Step 7 — Post-Deploy Fixes
```bash
./07-post-deploy.sh
```
Fixes wsgi paths, log permissions, libvirt auth.

### Step 8 — Setup Networking
```bash
./08-setup-network.sh
```
Creates external network, tenant network, router, uploads Ubuntu image.

---

## Known Issues & Fixes

### SSH Breaks After OVS Deploy
**Problem**: OVS takes over `ens33` and breaks SSH  
**Fix**: Always use `ens37` as `neutron_external_interface`  
**Recovery**:
```bash
sudo ip addr add 192.168.131.10/24 dev ens33
sudo ip link set ens33 up
sudo ip route add default via 192.168.131.2
sudo systemctl start ssh
```

### MariaDB Container Exits
**Problem**: `mariadbd-safe` daemonizes outside container  
**Fix**: Change config.json to use foreground mode:
```bash
sudo python3 -c "
import json
cfg = json.load(open('/etc/kolla/mariadb/config.json'))
cfg['command'] = '/usr/sbin/mariadbd --user=mysql'
json.dump(cfg, open('/etc/kolla/mariadb/config.json','w'), indent=4)
"
docker restart mariadb
```

### ansible-runner Not Found in kolla_toolbox
**Fix**: Already handled in `05-build-images.sh`  
**Manual fix**:
```bash
sudo docker exec -u root kolla_toolbox bash -c \
  "pip install ansible-runner && \
   chmod +x /opt/ansible/bin/ansible-runner"
```

### Placement Returns 500
**Problem**: Wrong wsgi module path  
**Fix**:
```bash
sudo sed -i 's|module = placement.wsgi.api:application|mount = /=placement.wsgi:init_application()\nmanage-script-name = true|' \
  /etc/kolla/placement-api/placement-api-uwsgi.ini
docker restart placement_api
```

### Nova-compute Can't Connect to Libvirt
**Problem**: SASL auth enabled  
**Fix**:
```bash
sudo sed -i 's/auth_tcp = "sasl"/auth_tcp = "none"/' \
  /etc/kolla/nova-libvirt/libvirtd.conf
docker restart nova_libvirt nova_compute
```

### Floating IPs Not Reachable
**Problem**: Floating IPs are on `ens33` subnet but OVN routes through `ens37`  
**Fix**: Use `ens37` subnet for floating IPs (VMnet1 range)

---

## After Installation

### Access Horizon Dashboard
```
http://<VIP>
Username: admin
Password: $(grep keystone_admin_password ~/openstack/passwords.yml | awk '{print $2}')
```

### OpenStack CLI
```bash
source ~/kolla-venv/bin/activate
source ~/openstack/admin-openrc.sh
openstack service list
openstack compute service list
openstack network agent list
```

### Restart After Reboot
```bash
source ~/kolla-venv/bin/activate
cd ~/openstack
kolla-ansible deploy -i multinode --configdir . -e ansible_forks=2
```

### Auto-Start Script
```bash
# Add to crontab for auto-start after reboot
(crontab -l 2>/dev/null; echo "@reboot sleep 60 && source ~/kolla-venv/bin/activate && cd ~/openstack && kolla-ansible deploy -i multinode --configdir . >> ~/openstack/autostart.log 2>&1") | crontab -
```

---

## Architecture

```
Windows 11
└── VMware Workstation
    └── Ubuntu 24.04 VM
        ├── ens33 (NAT) ─────────── 192.168.131.10 (SSH/Management)
        │   └── NEVER touched by OVS
        └── ens37 (Host-only) ───── 192.168.56.10 (OpenStack Provider)
            └── br-ex (OVS bridge)
                └── Floating IPs: 192.168.56.200-250
                
OpenStack Services (all on 192.168.56.100 VIP):
├── Keystone    :5000
├── Glance      :9292
├── Nova        :8774
├── Neutron     :9696
├── Placement   :8780
├── Heat        :8004/:8000
└── Horizon     :80
```
