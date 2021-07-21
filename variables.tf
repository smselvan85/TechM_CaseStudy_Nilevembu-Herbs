# For Service Principal using password for auth when running plan/apply
variable "client_secret" {
}

# read in from the terraform.tfvars file
variable "global_settings" {
}

variable "location1" {
  type = string
}

variable "resource_group1" {
  type = string
}

variable "location2" {
  type = string
}

variable "resource_group2" {
  type = string
}

variable "management_source" {
  type = string
}

variable "domain_name_prefix" {
  type = string
}

# Windows vm servers variables
variable "server_vm_image_publisher" {
}
variable "server_vm_image_offer" {
}
variable "server_vm_image_sku" {
}
variable "server_vm_image_version" {
}
variable "server_vm_size" {
}
