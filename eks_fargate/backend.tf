terraform {
    backend "s3" {
        bucket = "stuartwallace-oc-tf-state"
        key = "stuartwallace-oc/eks-fargate/terraform.tfstate"
        region = "eu-west-2"
        dynamodb_table = "terraform-state"
    }
}

