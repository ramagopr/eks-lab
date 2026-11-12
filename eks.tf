module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # API endpoint reachable from the internet, but only from your IP.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = [var.my_ip_cidr]

  # Gives the IAM identity running Terraform (your "admin" user) cluster-admin via an EKS access entry.
  enable_cluster_creator_admin_permissions = true

  enabled_log_types = ["api", "audit"]

  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
  }

  eks_managed_node_groups = {
    general = {
      # Upgrade phase 1: keep workers on 1.36 while the control plane goes to 1.37.
      # Phase 3: delete this line so the node group follows the cluster version.
      # kubernetes_version = "1.36"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m7i-flex.large"] # Free plan only allows: t3.micro, t3.small, t4g.micro, t4g.small, c7i-flex.large, m7i-flex.large
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        role = "general"
      }
    }
  }

  # Lets Karpenter (step 8) reuse the node security group.
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}
