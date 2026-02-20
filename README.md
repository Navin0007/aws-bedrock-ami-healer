# AWS Bedrock AMI Healer

## What This Builds
A working EC2 Auto Scaling setup behind an ALB, provisioned via Terraform
and deployed automatically via GitHub Actions.

This is **Phase 1** — the working baseline. Later phases add Bedrock-powered
automatic healing when AMI upgrades break the bootstrap script.

## Architecture
```
Internet → ALB (public subnets) → EC2 Flask App (private subnets)
EC2 instances are registered with the ALB and health-checked on /health
```

## Phase Roadmap
- [x] Phase 1 — Terraform baseline + GitHub Actions CI/CD
- [ ] Phase 2 — Break it: swap AMI to Amazon Linux 2023
- [ ] Phase 3 — EventBridge detects the failure
- [ ] Phase 4 — Lambda + SSM collects logs
- [ ] Phase 5 — Bedrock analyzes and generates fix
- [ ] Phase 6 — Auto-apply fix via Launch Template update

---

## Prerequisites

- AWS CLI configured locally
- Terraform >= 1.5.0
- GitHub repository with Actions enabled
- IAM user with permissions for: EC2, VPC, ELB, IAM, SSM, S3, DynamoDB

---

## One-Time AWS Setup (Bootstrap Terraform Backend)

The S3 bucket and DynamoDB table for Terraform state are now managed by Terraform itself, using the account ID dynamically fetched from AWS.

### Bootstrap Steps

1. **First, create the backend resources using a local backend:**
```bash
cd terraform

# Temporarily use local backend for bootstrap
terraform init -backend=false

# Create only the backend resources
terraform apply -target=aws_s3_bucket.terraform_state \
                 -target=aws_s3_bucket_versioning.terraform_state \
                 -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                 -target=aws_s3_bucket_public_access_block.terraform_state \
                 -target=aws_dynamodb_table.terraform_locks
```

2. **Get the bucket and table names from outputs:**
```bash
# Get the bucket name (account ID is included automatically)
terraform output -raw terraform_state_bucket

# Get the DynamoDB table name
terraform output -raw terraform_lock_table
```

3. **Re-initialize Terraform with S3 backend:**
```bash
# Re-initialize with S3 backend using the created resources
terraform init -migrate-state \
  -backend-config="bucket=$(terraform output -raw terraform_state_bucket)" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=$(terraform output -raw terraform_lock_table)"
```

4. **Now apply the full infrastructure:**
```bash
terraform plan
terraform apply
```

**Note:** The S3 bucket name automatically includes your AWS account ID (e.g., `ami-healer-terraform-state-123456789012`), so no manual account ID configuration is needed.

---

## GitHub Repository Setup

### Required Secrets
Go to: Settings → Secrets and variables → Actions → New repository secret

| Secret Name            | Value                                         |
|------------------------|-----------------------------------------------|
| `AWS_ACCESS_KEY_ID`    | IAM user access key                           |
| `AWS_SECRET_ACCESS_KEY`| IAM user secret key                           |
| `AWS_REGION`           | `us-east-1`                                   |
| `TF_STATE_BUCKET`      | Output from `terraform output -raw terraform_state_bucket` (includes account ID) |
| `TF_STATE_LOCK_TABLE`  | `ami-healer-terraform-locks`                  |

### GitHub Environment
Create an environment called `production` under Settings → Environments.
Optionally add yourself as a required reviewer for extra protection.

### Branch Protection (recommended)
- Require PR reviews before merging to `main`
- Require `Terraform Plan` status check to pass before merging

---

## Developer Workflow

```
Edit .tf files
      ↓
Push to feature branch → open PR
      ↓
GitHub Actions runs terraform-plan.yml
      ↓
Plan output posted as PR comment
      ↓
Reviewer approves PR
      ↓
Merge to main
      ↓
GitHub Actions runs terraform-apply.yml
      ↓
AWS infrastructure updated
      ↓
Outputs (ALB URL etc.) visible in Actions logs
```

---

## Local Development

```bash
cd terraform

# If backend resources already exist, init with outputs:
terraform init \
  -backend-config="bucket=$(terraform output -raw terraform_state_bucket 2>/dev/null || echo 'ami-healer-terraform-state-<account-id>')" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=$(terraform output -raw terraform_lock_table 2>/dev/null || echo 'ami-healer-terraform-locks')"

# Or manually specify after bootstrap:
# terraform init \
#   -backend-config="bucket=ami-healer-terraform-state-$(aws sts get-caller-identity --query Account --output text)" \
#   -backend-config="region=us-east-1" \
#   -backend-config="dynamodb_table=ami-healer-terraform-locks"

terraform plan
terraform apply
```

## Test the deployment
```bash
curl http://<alb_dns_name>/health
# Expected: {"status": "healthy", "hostname": "...", "instance_id": "..."}
```

## Destroy (use GitHub Actions Destroy workflow or locally)
```bash
terraform destroy
```
