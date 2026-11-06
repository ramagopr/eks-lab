# Backend settings for the dev environment.
# Used with:  terraform init -backend-config=dev/backend.hcl
bucket       = "eks-lab-tfstate-070215089441"
key          = "eks-lab/dev/terraform.tfstate"
region       = "ap-southeast-2"
use_lockfile = true
encrypt      = true
