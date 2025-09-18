provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

resource "yandex_vpc_network" "default" {
  name = "default-net"
}

resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

resource "yandex_compute_instance" "vm" {
  name        = "mysite-vm"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8m8b9h3vulqsk1e9gh"
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}" 
  }
}

output "external_ip" {
  value = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}
