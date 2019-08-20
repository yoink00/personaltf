provider "aws" {
  alias = "region"
}

variable "cluster-name" {
  default = "eks-k8s"
  type    = "string"
}

variable cidr_block {}

variable maximum_nodes {}

variable minimum_nodes {}


variable desired_nodes {}
