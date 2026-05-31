#!/bin/bash
# ============================================================
# OpenStack Single-Node Install Script - Step 5: Build Images
# Fix broken kolla images - install uwsgi in kolla venv
# ============================================================
set -e

echo "=== Step 5: Build Fixed Docker Images ==="

# Install uwsgi in kolla-toolbox (for ansible-runner)
echo "Building kolla-toolbox with ansible-runner..."
docker build --network=host \
  -t quay.io/openstack.kolla/kolla-toolbox:2024.2-ubuntu-noble - << 'EOF'
FROM quay.io/openstack.kolla/kolla-toolbox:2024.2-ubuntu-noble
USER root
RUN pip install ansible-runner && \
    chmod +x /opt/ansible/bin/ansible-runner
EOF
echo "  ✓ kolla-toolbox built"

# Fix services that need uwsgi installed in kolla venv
for svc in keystone glance-api heat-api heat-api-cfn heat-engine \
           horizon neutron-server nova-api nova-conductor nova-scheduler \
           nova-compute placement-api; do
  echo "Building $svc with uwsgi..."
  docker build --network=host \
    -t quay.io/openstack.kolla/${svc}:2024.2-ubuntu-noble - << DOCKERFILE
FROM quay.io/openstack.kolla/${svc}:2024.2-ubuntu-noble
USER root
RUN apt-get update -qq && \
    apt-get install -y -qq gcc python3-dev libpcre3-dev && \
    /var/lib/kolla/venv/bin/pip install uwsgi && \
    rm -f /usr/bin/uwsgi* && \
    ln -sf /var/lib/kolla/venv/bin/uwsgi /usr/bin/uwsgi && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
DOCKERFILE
  echo "  ✓ $svc built"
done

echo ""
echo "=== Step 5 Complete ==="
echo "Next: Run 06-deploy.sh"
