##########
# Master #
##########

resource "aws_security_group" "k8s-cluster" {
  name        = "${var.cluster-name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.k8s.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.cluster-name
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "k8s-ingress-workstation-https" {
  cidr_blocks       = ["90.254.17.44/32"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.k8s-cluster.id
  to_port           = 443
  type              = "ingress"
}

#########
# Nodes #
#########

resource "aws_security_group" "k8s-node" {
  name        = "${var.cluster-name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.k8s.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "k8s-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.k8s-node.id
  source_security_group_id = aws_security_group.k8s-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "k8s-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s-node.id
  source_security_group_id = aws_security_group.k8s-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

###################
# Node <-> Master #
###################

resource "aws_security_group_rule" "k8s-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s-cluster.id
  source_security_group_id = aws_security_group.k8s-node.id
  to_port                  = 443
  type                     = "ingress"
}