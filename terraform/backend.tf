terraform {
  backend "s3" {
    # These values are injected at runtime by GitHub Actions
    # using the -backend-config flags in terraform init
    # Leave empty here — injected via CI/CD or local -backend-config flags
    # After bootstrap, use outputs from backend_resources.tf:
    # terraform init -backend-config="bucket=$(terraform output -raw terraform_state_bucket)" \
    #                -backend-config="region=us-east-1" \
    #                -backend-config="dynamodb_table=$(terraform output -raw terraform_lock_table)"
    bucket         = ""
    key            = "ami-healer/terraform.tfstate"
    region         = ""
    dynamodb_table = ""
    encrypt        = true
  }
}
