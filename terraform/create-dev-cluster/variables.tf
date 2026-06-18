variable "servers_count" {
  type        = number
  description = "Number of control-plane (server) nodes in the KinD cluster"
  default     = 1
}

variable "workers_count" {
  type        = number
  description = "Number of worker nodes in the KinD cluster"
  default     = 0
}
