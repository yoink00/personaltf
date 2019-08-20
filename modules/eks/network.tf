data "aws_availability_zones" "available" {
  provider = aws.region
}

resource "aws_vpc" "k8s" {
  cidr_block = "${var.cidr_block}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "k8s" {
  count = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.k8s.cidr_block, 8, count.index + 1)
  vpc_id            = aws_vpc.k8s.id

  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "k8s" {
  vpc_id = aws_vpc.k8s.id

  tags = {
    Name = var.cluster-name
  }
}

resource "aws_route_table" "k8s" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s.id
  }
}

resource "aws_route_table_association" "k8s" {
  count = length(data.aws_availability_zones.available.names)

  subnet_id      = aws_subnet.k8s[count.index].id
  route_table_id = aws_route_table.k8s.id
}
