# Step 5b – CI: ECR repository + GitHub Actions → AWS via OIDC (no access keys anywhere).
#
# How the trust works (same idea as IRSA):
#   GitHub issues each workflow run a signed token (issuer: token.actions.githubusercontent.com)
#   AWS IAM trusts that issuer (aws_iam_openid_connect_provider.github)
#   The role's trust policy only accepts tokens from YOUR repo's main branch
#   The workflow swaps the token for short-lived AWS credentials

variable "github_repo" {
  description = "owner/name of the GitHub repo allowed to push images"
  type        = string
  default     = "ramagopr/eks-lab"
}

# GitHub now puts immutable numeric IDs in the OIDC "sub" claim:
#   repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:refs/heads/main
# The IDs stop a deleted-and-recreated repo (or renamed account) from inheriting this trust.
# Find them in a workflow run's token claims, or: gh api repos/ramagopr/eks-lab --jq '.owner.id, .id'
variable "github_owner_id" {
  type    = string
  default = "8437439"
}

variable "github_repo_id" {
  type    = string
  default = "1448030531"
}

locals {
  github_owner     = split("/", var.github_repo)[0]
  github_repo_name = split("/", var.github_repo)[1]
  github_oidc_sub  = "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo_name}@${var.github_repo_id}:ref:refs/heads/main"
}

resource "aws_ecr_repository" "podinfo" {
  name                 = "podinfo"
  image_tag_mutability = "IMMUTABLE" # a tag can never be overwritten – what's deployed is what was scanned
  force_delete         = true        # lab only: lets "terraform destroy" remove it even with images inside

  image_scanning_configuration {
    scan_on_push = true # ECR's own basic scan, in addition to Trivy in the pipeline
  }
}

# Keep the repo small: only the last 10 images
resource "aws_ecr_lifecycle_policy" "podinfo" {
  repository = aws_ecr_repository.podinfo.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.cluster_name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        # Only workflows running on the main branch of this one repo (exact match, no wildcards)
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.github_oidc_sub
        }
      }
    }]
  })
}

# Least privilege: log in to ECR and push to the podinfo repo only. No EKS, no kubectl.
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "ecr-push-podinfo"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*" # this API doesn't support resource-level permissions
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.podinfo.arn
      }
    ]
  })
}

output "ecr_repository_url" {
  value = aws_ecr_repository.podinfo.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
