variable "proxmox_api_url" {
  type        = string
  description = "The api url endpoint to use to connect via API key over https"
}

variable "proxmox_api_token" {
  type        = string
  description = "The api token of the SA on proxmox to create the cluster and provision it's VMs and other resources"
  sensitive   = true
}

variable "talos_version" {
  type        = string
  description = "The version of talos linux to install from the image factory."
}

variable "control_plane_count" {
  type        = number
  description = "The number of control plane nodes to create in the cluster"
  default     = 1
}

variable "worker_count" {
  type        = number
  description = "The number of worker nodes to create in the cluster"
  default     = 1
}
