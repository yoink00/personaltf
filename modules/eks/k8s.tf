data "aws_eks_cluster_auth" "k8s" {
  name = aws_eks_cluster.k8s.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.k8s.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.k8s.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.k8s.token
  load_config_file       = false
}

####################
# Join the cluster #
####################
resource "kubernetes_config_map" "config_map_aws_auth" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<CONFIGMAPAWSAUTH
    - rolearn: ${aws_iam_role.k8s-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
  }
}

