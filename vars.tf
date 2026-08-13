variable "proxmox_api_url" {
  type        = string
  description = "The api url endpoint to use to connect via API key over https"
}

variable "proxmox_api_token" {
  type        = string
  description = "The api token of the SA on proxmox to create the cluster and provision it's VMs and other resources"
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  description = "The name of the core cluster"
}

variable "flux_operator_bootstrap_revision" {
  type        = number
  description = "The revision of flux operator's installed state, bump this to reinstall flux operator into the cluster"
  default     = 1
}
