variable "os_auth_url" {
  description = "OpenStack auth URL"
  default     = "http://192.168.131.100:5000/v3"
}

variable "os_username" {
  description = "OpenStack username"
  default     = "admin"
}

variable "os_password" {
  description = "OpenStack password"
  sensitive   = true
}

variable "os_project_name" {
  description = "OpenStack project name"
  default     = "admin"
}

variable "os_domain_name" {
  description = "OpenStack domain name"
  default     = "Default"
}

variable "os_region" {
  description = "OpenStack region"
  default     = "RegionOne"
}

variable "ssh_public_key" {
  description = "SSH public key content"
}

variable "network_name" {
  description = "Existing network name"
  default     = "demo-network"
}

variable "subnet_name" {
  description = "Existing subnet name"
  default     = "demo-subnet"
}

variable "image_name" {
  description = "OS image name"
  default     = "ubuntu-24.04"
}

variable "flavor_name" {
  description = "Instance flavor"
  default     = "m1.small"
}

variable "db_password" {
  description = "PostgreSQL password"
  sensitive   = true
  default     = "Sage@2022"
}

variable "app_secret_key" {
  description = "Flask secret key"
  sensitive   = true
  default     = "flask-secret-2026-counter"
}
