#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 6: Deploy
# ============================================================
set -e

source ~/kolla-venv/bin/activate
cd ~/openstack

echo "=== Step 6: Deploy OpenStack ==="

# Bootstrap servers
echo "Running bootstrap-servers..."
kolla-ansible bootstrap-servers -i multinode --configdir .

# Deploy
echo "Running deploy..."
kolla-ansible deploy -i multinode --configdir . -e ansible_forks=2 \
  2>&1 | tee ~/openstack/deploy.log

echo ""
echo "=== Step 6 Complete ==="
echo "Next: Run 07-post-deploy.sh"
