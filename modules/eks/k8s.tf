data "aws_eks_cluster_auth" "k8s" {
  name = aws_eks_cluster.k8s.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.k8s.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.k8s.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.k8s.token
  load_config_file       = false
}