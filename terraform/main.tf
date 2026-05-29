terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "openstack" {
  auth_url    = var.os_auth_url
  user_name   = var.os_username
  password    = var.os_password
  tenant_name = var.os_project_name
  domain_name = var.os_domain_name
  region      = var.os_region
}

# Security Groups
resource "openstack_networking_secgroup_v2" "counter_sg" {
  name        = "counter-sg"
  description = "Counter app security group"
  lifecycle {
    ignore_changes = all
  }
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = openstack_networking_secgroup_v2.counter_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  security_group_id = openstack_networking_secgroup_v2.counter_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "app" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5000
  port_range_max    = 5000
  security_group_id = openstack_networking_secgroup_v2.counter_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  security_group_id = openstack_networking_secgroup_v2.counter_sg.id
}

# SSH Keypair
resource "openstack_compute_keypair_v2" "counter_keypair" {
  name       = "counter-key"
  public_key = var.ssh_public_key
  lifecycle {
    ignore_changes = [public_key]
  }
}

# Use existing network (created by the demo terraform)
data "openstack_networking_network_v2" "app_network" {
  name = var.network_name
}

data "openstack_networking_subnet_v2" "app_subnet" {
  name = var.subnet_name
}

data "openstack_networking_network_v2" "external" {
  external = true
}

# App Server
resource "openstack_compute_instance_v2" "app_server" {
  name            = "counter"
  image_name      = var.image_name
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.counter_keypair.name
  security_groups = [openstack_networking_secgroup_v2.counter_sg.name]

  network {
    uuid = data.openstack_networking_network_v2.app_network.id
  }

  user_data = <<-USERDATA
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx git
  USERDATA
}

# Floating IP for app server
resource "openstack_networking_floatingip_v2" "app_fip" {
  pool = data.openstack_networking_network_v2.external.name
}

resource "openstack_networking_floatingip_associate_v2" "app_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.app_fip.address
  port_id     = openstack_compute_instance_v2.app_server.network[0].port
}

output "app_server_ip" {
  value       = openstack_networking_floatingip_v2.app_fip.address
  description = "Public IP of the counter app server"
}

output "app_server_id" {
  value = openstack_compute_instance_v2.app_server.id
}
