variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "cluster_name" {
  type    = string
  default = "eks-lab"
}

variable "kubernetes_version" {
  description = "Start on 1.36; step 9 upgrades this to 1.37."
  type        = string
  default     = "1.36"
}

variable "my_ip_cidr" {
  description = "Your public IP as a /32, e.g. 203.0.113.10/32. Only this IP can reach the Kubernetes API."
  type        = string
}
