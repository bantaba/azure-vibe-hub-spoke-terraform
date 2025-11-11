variable "lb_name" {
  type        = string
  description = "load balancer name"
}

variable "lb_location" {
  type        = string
  description = "Load balancer location"
}

variable "lb_resource_group_name" {
  type        = string
  description = "Load balancer resource group"
}

variable "lb_fe_ip_config_name" {
  type        = string
  description = "Load balancer frontend IP configuration name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to associate load balancer"
}
# variable "loadBalancerPIPAddress_id" {
#     type = string
#     description = "(optional) describe your variable"
# }

variable "lb_be_address_pool_name" {
  type        = string
  description = "load balancer backend address pool name"
}

variable "probe_name" {
  type        = string
  description = "Load balancer probe name e.g HTTP, RDP, etc."
}

variable "lb_probe_port" {
  type        = string
  description = "load balance probe port"
}

variable "protocol" {
  type        = string
  default     = "Tcp"
  description = "load balancer probe protocol  to be one of [Http Https Tcp]"
}


# variable "lb_backend_address_pool_id" {
#     type = string
#     description = "(optional) describe your variable"
# }

# variable "lb_backend_address_ip_configuration_id" {
#     type = string
#     description = "(optional) describe your variable"
# }

variable "lb_rule_name" {
  type        = string
  description = "load balance rule name"
}

variable "lb_rule_fe_port" {
  type        = number
  description = "Load balancer rule front end port"
}


variable "lb_rule_be_port" {
  type        = number
  description = "Load balancer rule backend port"
}

variable "tags" {
  type        = map(string)
  description = "(optional) describe your variable"
}

variable "nic_ip_config_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "nic_ids" {
  type        = set(string)
  description = "(optional) describe your variable"
}

variable "private_ip_address_allocation" {
  type        = string
  default     = "Dynamic"
  description = "(optional) describe your variable"
}

# variable "loadBalancerBackendAddressPoolAddressName" {
#     type = string
#     description = "(optional) describe your variable"
# }
