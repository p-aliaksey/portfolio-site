terraform {
  required_version = ">= 1.6.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.124.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

locals {
  use_existing_vpc   = var.vpc_network_id != ""
  use_existing_subnet = var.vpc_subnet_id != ""
}

resource "yandex_vpc_network" "vpc" {
  count = local.use_existing_vpc ? 0 : 1
  name  = "devops-portfolio-net"
}

resource "yandex_vpc_subnet" "subnet" {
  count          = local.use_existing_subnet ? 0 : 1
  name           = "devops-portfolio-subnet"
  zone           = var.yc_zone
  network_id     = local.use_existing_vpc ? var.vpc_network_id : yandex_vpc_network.vpc[0].id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "sg" {
  name        = "devops-portfolio-sg"
  network_id  = local.use_existing_vpc ? var.vpc_network_id : yandex_vpc_network.vpc[0].id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "ALL"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "vm" {
  name = "devops-portfolio-vm"
  platform_id = "standard-v3"
  zone = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = local.use_existing_subnet ? var.vpc_subnet_id : yandex_vpc_subnet.subnet[0].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.public_ssh_key}"
  }
}

 
