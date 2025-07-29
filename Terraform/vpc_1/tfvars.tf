# Example usage of the VPC module
module "vpc" {
  source = "./vpc"

  region             = "us-east-1"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  environment        = "dev"
  custom_tags = {
    Project = "MyProject"
    Owner   = "TeamA"
  }
}
