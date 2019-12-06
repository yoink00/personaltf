resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.eks_cluster_subnet.*.id
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]


  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure
  # such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_role-AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.eks_cluster_logs,
  ]
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "eks-fargate-pods.amazonaws.com",
          "eks.amazonaws.com"
        ]
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_vpc" "eks_cluster_vpc" {
  cidr_block = var.cluster_cidr_block

  tags = {
    Name                                        = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "eks_cluster_subnet" {
  count = min(3, length(data.aws_availability_zones.available.names))

  vpc_id = aws_vpc.eks_cluster_vpc.id
  cidr_block = cidrsubnet(
    var.cluster_cidr_block,
    ceil(log(length(data.aws_availability_zones.available.names) * 2, 2)),
    count.index
  )

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

locals {
  namespaces = toset(["default", "kube-system"])
}

resource "aws_eks_fargate_profile" "eks_cluster_fargate_profile" {
  for_each = local.namespaces

  cluster_name           = aws_eks_cluster.eks_cluster.name
  fargate_profile_name   = "${var.cluster_name}-fargate-profile-${each.value}"
  pod_execution_role_arn = aws_iam_role.eks_cluster_fargate_role.arn
  subnet_ids             = aws_subnet.eks_cluster_subnet.*.id

  selector {
    namespace = each.value
  }

  depends_on = [
		aws_iam_role_policy_attachment.eks_cluster_fargate_role-AmazonEKSFargatePodExecutionRolePolicy,
		/*aws_iam_role_policy_attachment.eks_cluster_fargate_role-AmazonEKSWorkerNodePolicy,
		aws_iam_role_policy_attachment.eks_cluster_fargate_role-AmazonEC2ContainerRegistryReadOnly,
		aws_iam_role_policy_attachment.eks_cluster_fargate_role-AmazonEKS_CNI_Policy*/
  ]
}

resource "aws_iam_role" "eks_cluster_fargate_role" {
  name = "${var.cluster_name}-fargate-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "eks-fargate-pods.amazonaws.com",
          "eks.amazonaws.com"
        ]
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_fargate_role-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_cluster_fargate_role.name
}

/*resource "aws_iam_role_policy_attachment" "eks_cluster_fargate_role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_fargate_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_fargate_role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_fargate_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_fargate_role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_fargate_role.name
}*/

resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_internet_gateway" "eks_cluster_igw" {
  vpc_id = aws_vpc.eks_cluster_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

data "aws_route_table" "eks_cluster_rtb" {
  vpc_id = aws_vpc.eks_cluster_vpc.id
}

resource "aws_route" "eks_cluster_igw_route" {
  route_table_id         = data.aws_route_table.eks_cluster_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_cluster_igw.id
}
