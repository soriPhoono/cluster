variable "debug_mode" {
  type        = bool
  description = "Whether or not to run this pipeline in debug mode or in production mode"
}

variable "proxmox_api_url" {
  type        = string
  description = "The api url endpoint to use to connect via API key over https"
  default     = null
}

variable "proxmox_api_token" {
  type        = string
  description = "The api token of the SA on proxmox to create the cluster and provision it's VMs and other resources"
  sensitive   = true
}
