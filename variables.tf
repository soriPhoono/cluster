variable "bootstrap_revision" {
  description = "Bump to trigger a new bootstrap run."
  type        = number
  default     = 1
  nullable    = false
}

variable "cluster-name" {
  description = "The name of the cluster configuration to load from disk"
  type        = string
  default     = "guenivir"
  nullable    = false
}

variable "ghcr-pat" {
  description = "The personal access token for GitHub Container Registry"
  type        = string
  sensitive   = true
  nullable    = false
}