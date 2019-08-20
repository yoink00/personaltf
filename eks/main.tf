module "london" {
  source = "../modules/eks"
  cidr_block = "10.0.0.0/16"
  desired_nodes = 2
  maximum_nodes = 2
  minimum_nodes = 1

  providers = {
    aws.region = "aws.london"
  }
}
