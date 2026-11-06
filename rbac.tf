# Step 3 – a read-only "developer" identity for the cluster.
#
# Who you are  : IAM role eks-lab-developer (people assume it; no access keys)
# Mapping      : EKS access entry puts that role into the Kubernetes group "lab-readonly"
# What you can do : Kubernetes RBAC (k8s/rbac/readonly.yaml) grants that group read-only access

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "developer" {
  name = "${var.cluster_name}-developer"

  # Any IAM identity in this account that is itself allowed sts:AssumeRole can assume this role
  # (your "admin" user is, via AdministratorAccess).
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
    }]
  })
}

# AWS-side permission: just enough to run "aws eks update-kubeconfig".
# Nothing else in AWS – this role can't touch EC2, S3, IAM, etc.
resource "aws_iam_role_policy" "developer_describe_cluster" {
  name = "eks-describe-cluster"
  role = aws_iam_role.developer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = module.eks.cluster_arn
    }]
  })
}

# EKS access entry: lets the role into the cluster, as a member of the Kubernetes group "lab-readonly".
# No access *policy* is attached here on purpose – permissions come from our own RBAC instead.
resource "aws_eks_access_entry" "developer" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_role.developer.arn
  kubernetes_groups = ["lab-readonly"]
  type              = "STANDARD"
}

output "developer_role_arn" {
  value = aws_iam_role.developer.arn
}
