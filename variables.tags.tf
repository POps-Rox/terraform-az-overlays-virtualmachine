# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################
# Tags Configuration    ##
####################################
variable "nic_add_tags" {
  description = "Extra tags to set on the network interface."
  type        = map(string)
  default     = {}
}

variable "public_ip_add_tags" {
  description = "Extra tags to set on the public IP resource."
  type        = map(string)
  default     = {}
}

variable "add_tags" {
  description = "Extra tags to set on each created resource."
  type        = map(string)
  default     = {}
}

variable "os_disk_add_tags" {
  description = "Extra tags to set on the OS disk."
  type        = map(string)
  default     = {}
}
