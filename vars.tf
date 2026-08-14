variable "proxmox_api_url" {
  type        = string
  description = "The api url endpoint to use to connect via API key over https"
  default     = "https://pve.xerus-augmented.ts.net"
}

variable "proxmox_api_token" {
  type        = string
  description = "The api token of the SA on proxmox to create the cluster and provision it's VMs and other resources"
  sensitive   = true
}

variable "talos_version" {
  type        = string
  description = "The version of talos linux to install from the image factory."
  default     = "v1.13.8"
}

variable "flux_operator_bootstrap_revision" {
  type        = number
  description = "The revision of flux operator's installed state, bump this to reinstall flux operator into the cluster"
  default     = 1
}
