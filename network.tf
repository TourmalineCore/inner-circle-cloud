resource "yandex_vpc_network" "network" {
  name = format("%s-network", local.resource_name_prefix)

  labels = {
    project = var.project
    environment = var.environment
  }
}

resource "yandex_vpc_subnet" "subnet" {
  name = format("%s-%s", local.resource_name_prefix, var.zone)
  // local ip addresses
  v4_cidr_blocks = ["10.129.0.0/24"]
  zone = var.zone
  network_id = yandex_vpc_network.network.id

  labels = {
    project = var.project
    environment = var.environment
  }
}

// Security group with configured incoming and outcoming connections
resource "yandex_vpc_security_group" "security_group" {
  name = format("%s-security-group", local.resource_name_prefix)
  network_id  = yandex_vpc_network.network.id

  labels = {
    project = var.project
    environment = var.environment
  }

  ingress {
    protocol = "TCP"
    description = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 80
  }

  ingress {
    protocol = "TCP"
    description = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port = 443
  }
  
  ingress {
    protocol = "ANY"
    description = "SSH"
    v4_cidr_blocks = tolist(split(",", var.protected_resources_allowed_external_ip_addresses))
    port = var.ssh_port
  }

  egress {
    protocol = "ANY"
    description = "Internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 65535
  }
}

// Static ip address for VM
resource "yandex_vpc_address" "ip_address" {
  labels = {
    project = var.project
    environment = var.environment
  }
  
  external_ipv4_address {
    zone_id = var.zone
    ddos_protection_provider = "qrator"
  }
}

locals {
  vm_ip_address = yandex_vpc_address.ip_address.external_ipv4_address[0].address
}