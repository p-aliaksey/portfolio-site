variable "yc_token" { type = string }
variable "yc_cloud_id" { type = string }
variable "yc_folder_id" { type = string }
variable "yc_zone" { type = string  default = "ru-central1-a" }
variable "ssh_user" { type = string  default = "ubuntu" }
variable "public_ssh_key_path" { type = string }
variable "ubuntu_image_id" { type = string  description = "Ubuntu 24.04 LTS image-id" }
