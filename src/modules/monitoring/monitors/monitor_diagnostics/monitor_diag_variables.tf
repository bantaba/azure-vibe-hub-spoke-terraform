variable "name" {
    type = string
    description = "Specifies the name of the Diagnostic Setting. Changing this forces a new resource to be created."
}

variable "target_resource_id" {
    type = string
    description = "The ID of an existing Resource on which to configure Diagnostic Settings. Changing this forces a new resource to be created."
}

variable "storage_account_id" {
    type = string
    description = "he ID of the Storage Account where logs should be sent."
}