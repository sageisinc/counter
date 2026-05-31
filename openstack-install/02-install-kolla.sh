#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 2: Kolla-Ansible
# ============================================================
set -e

echo "=== Step 2: Install Kolla-Ansible ==="

# Install kolla-ansible in a venv
python3 -m venv ~/kolla-venv
source ~/kolla-venv/bin/activate
pip install -U pip
pip install 'ansible-core>=2.16,<2.17'
pip install kolla-ansible==22.0.0

# Install Ansible dependencies
kolla-ansible install-deps

# Create config directory
mkdir -p ~/openstack
cp ~/kolla-venv/share/kolla-ansible/etc_examples/kolla/globals.yml ~/openstack/
cp ~/kolla-venv/share/kolla-ansible/etc_examples/kolla/passwords.yml ~/openstack/
cp ~/kolla-venv/share/kolla-ansible/ansible/inventory/multinode ~/openstack/

# Generate passwords
python3 << 'PYEOF'
import secrets, string, yaml

with open('/home/sage/openstack/passwords.yml', 'r') as f:
    passwords = yaml.safe_load(f)

chars = string.ascii_letters + string.digits
for key, value in passwords.items():
    if value is None or value == '':
        passwords[key] = ''.join(secrets.choice(chars) for _ in range(40))

with open('/home/sage/openstack/passwords.yml', 'w') as f:
    yaml.dump(passwords, f, default_flow_style=False)
print("Passwords generated")
PYEOF

echo ""
echo "=== Step 2 Complete ==="
echo "Next: Run 03-configure.sh"
