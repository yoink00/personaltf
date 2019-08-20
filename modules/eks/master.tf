resource "aws_eks_cluster" "k8s" {
  name            = var.cluster-name
  role_arn        = aws_iam_role.k8s-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.k8s-cluster.id]
    subnet_ids         = aws_subnet.k8s.*.id
  }

  depends_on = [
    "aws_iam_role_policy_attachment.k8s-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.k8s-cluster-AmazonEKSServicePolicy",
  ]
}