// Boot HDD with Ubuntu 24.04 LTS
resource "yandex_compute_disk" "vm-disk" {
  name = local.resource_name_prefix
  type = "network-hdd"
  zone = var.zone
  image_id = "fd81qgp4lonb0bu8cg5m" // Ubuntu 24.04 lts
  size = 32 // Gb

  labels = {
    project = var.project
    environment = var.environment
  }
}

resource "yandex_compute_instance" "vm" {
  name = local.resource_name_prefix
  platform_id = "standard-v2" // Intel Cascade Lake https://yandex.cloud/ru/docs/compute/concepts/vm-platforms#standard-platforms
  zone = var.zone
  allow_stopping_for_update = true
  hostname = local.resource_name_prefix
  
  service_account_id = yandex_iam_service_account.monitoring_service_account.id

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = var.vm_cpu_cores_count 
    memory = var.vm_ram_in_gb
    core_fraction = var.vm_guaranteed_cpu_share_in_percent // % of CPU
  }

  boot_disk {
    disk_id = yandex_compute_disk.vm-disk.id
    auto_delete = false
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    security_group_ids = [format("%s", yandex_vpc_security_group.security_group.id)]
    nat = true
    nat_ip_address = local.vm_ip_address
  }

  metadata = {
    // ssh key file should be named as project name + environment + ssh. Example: inner-circle-prod-ssh.pub
    ssh-keys = "ubuntu:${file(format("./%s-ssh.pub", local.resource_name_prefix))}"

    // Install Unified Agent for monitoring
    // https://yandex.cloud/ru/docs/monitoring/concepts/data-collection/unified-agent/installation#setup
    install-unified-agent = 1
    user-data = "#cloud-config\nusers:\n- name: ubuntu\n  sudo: ALL=(ALL) NOPASSWD:ALL\n  shell: /bin/bash\n  ssh_authorized_keys:\n  - ssh-ed25519  ${file(format("./%s-ssh.pub", local.resource_name_prefix))}\nruncmd:\n  - wget -O - https://monitoring.api.cloud.yandex.net/monitoring/v2/unifiedAgent/config/install.sh | bash"
  }
  
  labels = {
    project = var.project
    environment = var.environment
  }
}

// Service account that can manage monitoring for VM
resource "yandex_iam_service_account" "monitoring_service_account" {
  name      = format("%s-vm-service-account", local.resource_name_prefix)
}

// Grant monitoring.editor permission for monitoring service account
resource "yandex_resourcemanager_folder_iam_member" "monitoring_service_account_iam" {
  folder_id = var.folder_id
  role      = "monitoring.editor"
  member    = "serviceAccount:${yandex_iam_service_account.monitoring_service_account.id}"
}