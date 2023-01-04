variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "East US"
}

variable "resource_group_name" {
  default = "udacity"
}

variable "num_vm" {
  description = "The number of Virtual Machines"
  default = 2
}

variable "image_name" {
  default = "udacity_webserver"
}

variable "image_rg" {
  default = "udacity"
}

variable "admin-user" {
    default = "admin_webserver"  
}

variable "admin-password" {
  default = "e6PTqaueYuC2zm<#"
}

variable "vm_instance_type" {
  default = "Standard_B1s"
}

variable "env" {}