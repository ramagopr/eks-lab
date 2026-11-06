data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Lab shortcut: public subnets only, no NAT gateway (saves ~$35/month).
# In production, nodes would sit in private subnets behind a NAT gateway.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs            = local.azs
  public_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  map_public_ip_on_launch = true
  enable_nat_gateway      = false
  enable_dns_hostnames    = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1                # lets the AWS Load Balancer Controller find these subnets (step 4)
    "karpenter.sh/discovery" = var.cluster_name # lets Karpenter find these subnets (step 8)
  }
}
