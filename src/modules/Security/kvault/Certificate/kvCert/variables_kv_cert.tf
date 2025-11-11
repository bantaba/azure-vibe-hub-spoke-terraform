variable "kvCertName" {
  type        = string
  description = "(optional) describe your variable"
}

variable "kvId" {
  type        = string
  description = "(optional) describe your variable"
}

variable "san_dnsNames" {
  type = list(string)
  #default = [ "internal.${terraform.workspace}.jamano.live", "domain.${terraform.workspace}.world" ]
  description = "(optional) describe your variable"
}

variable "subject" { #Add validation to ensure it contains CN=somedomain
  type        = string
  description = "(optional) describe your variable"
}

variable "certIssuer" {
  type        = string
  default     = "Self"
  description = "(optional) describe your variable"
}

variable "validityInMonths" {
  type        = number
  default     = 12
  description = "(optional) describe your variable"
}

variable "tags" {
  type        = map(string)
  description = "(optional) describe your variable"
}