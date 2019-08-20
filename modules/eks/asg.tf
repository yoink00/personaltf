data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.k8s.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We implement a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  k8s-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.k8s.endpoint}' --b64-cluster-ca '${aws_eks_cluster.k8s.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "k8s" {
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.k8s-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = var.cluster-name
  security_groups             = [aws_security_group.k8s-node.id]
  user_data_base64            = "${base64encode(local.k8s-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "k8s" {
  desired_capacity     = var.desired_nodes
  launch_configuration = aws_launch_configuration.k8s.id
  max_size             = var.maximum_nodes
  min_size             = var.minimum_nodes
  name                 = var.cluster-name
  vpc_zone_identifier  = aws_subnet.k8s.*.id

  tag {
    key                 = "Name"
    value               = var.cluster-name
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}