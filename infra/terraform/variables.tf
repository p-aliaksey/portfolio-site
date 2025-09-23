variable "yc_token" {
  type = string
}

variable "yc_cloud_id" {
  type = string
}

variable "yc_folder_id" {
  type = string
}

variable "yc_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "public_ssh_key" {
  type        = string
  description = "OpenSSH public key line"
}

variable "ubuntu_image_id" {
  type        = string
  description = "Ubuntu 24.04 LTS image-id"
}

# Optional: use existing VPC network/subnet to avoid quota issues
variable "vpc_network_id" {
  type        = string
  default     = ""
  description = "Existing VPC network ID (leave empty to create a new one)"
}

variable "vpc_subnet_id" {
  type        = string
  default     = ""
  description = "Existing VPC subnet ID (leave empty to create a new one)"
}
