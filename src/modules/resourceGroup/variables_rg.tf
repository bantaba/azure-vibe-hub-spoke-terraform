
variable "resource_group_names" {
  type = map(string)
  default = {
    NetLab      =  "mainVnet"
    CoreInfra    = "CoreInfra"
    WebFE        = "WebFE"
    DB_backend   = "DataTier"  
    K8s_kubenet    = "k8knet"  
    K8s_cni    = "k8cni"  
    K8s_acr    = "k8acr"
  }
  description = "The Name which should be used for this Resource Group."
}

variable "tags" {
    type = map(string)
    description = "A mapping of tags which should be assigned to the Resource Group."
}

variable "resource_group_location" {
    type = string
    description = "The Azure Region where the Resource Group should exist."
}
