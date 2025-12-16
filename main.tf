terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  required_version = ">= 0.13"

  backend "s3" {
    endpoints = { 
      s3 = "https://storage.yandexcloud.net" 
    }

    region    = "ru-central1"
    key       = "terraform.tfstate"

    // Some of the checks weren`t implemented in Yandex Cloud, so this is the reason we`re skipping them
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = var.zone
  service_account_key_file = "authorized_key.json"
}

variable "cloud_id" {
  type = string
  sensitive = true
}

variable "folder_id" {
  type = string
  sensitive = true
}

// availability zone
variable "zone" {
  type = string
  default = "ru-central1-b"
}

// name of project that will be used as part of name of every resource
variable "project" {
  type = string
  default = "inner-circle"
}

// name of environment that will be used as part of name of every resource
variable "environment" {
  type = string
  default = "prod"
}

locals {
  resource_name_prefix = format("%s-%s", var.project, var.environment)
}

# List of IP's that have access to VM via SSH. Should be separated by commas without spacing. Example: 8.8.8.8/32,77.88.55.88/32
variable "protected_resources_allowed_external_ip_addresses" {
  type = string
  sensitive = true
}

variable "ssh_port" {
  type = string
  sensitive = true
}