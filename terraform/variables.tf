variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "grafana_admin_password" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "nfs_server" {
  type = string
}

variable "nfs_path" {
  type    = string
  default = "/nfs"
}

variable "nfs_sc_default" {
  type    = bool
  default = true
}
