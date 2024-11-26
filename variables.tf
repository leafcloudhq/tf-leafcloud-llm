variable "prefix" {
  type        = string
  default     = ""
  description = "Prefix all resources to prevent name collisions"
}

variable "vm_total" {
  type        = number
  default     = 1
  description = "Total of vms to be created"
}

variable "vm_flavor_name" {
  type        = string
  default     = "eg1.a30x1.V8-32"
  description = "Flavor type of the VM"
}

variable "subnet_cidr" {
  type        = string
  default     = "192.168.42.0/24"
  description = "Subnet cidr to be used"
}

variable "vm_cidr_whitelist" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Whitelist source ip to access the VM"
}
