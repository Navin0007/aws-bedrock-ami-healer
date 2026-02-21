# How to Run GitHub Actions Workflows

This guide explains how to run the different Terraform workflows in this repository.

## Available Workflows

1. **Terraform Plan** - Runs automatically on Pull Requests
2. **Terraform Apply** - Runs on push to main OR manually
3. **Terraform Destroy** - Manual trigger only
4. **Terraform Bootstrap** - Manual trigger only (for initial setup)

---

## 🚀 Terraform Apply Workflow

### Method 1: Automatic Trigger (Push to Main)

The workflow runs automatically when you:
- Push changes to the `main` branch
- Modify files in `terraform/` directory
- Modify `.github/workflows/terraform-apply.yml`

**Steps:**
1. Make changes to Terraform files
2. Commit and push to `main` branch:
   ```bash
   git add terraform/
   git commit -m "Update infrastructure"
   git push origin main
   ```
3. Go to GitHub → Actions tab
4. Watch the workflow run automatically

### Method 2: Manual Trigger (Recommended for Testing)

You can manually trigger the workflow from GitHub:

**Steps:**
1. Go to your GitHub repository
2. Click on the **Actions** tab
3. In the left sidebar, select **"Terraform Apply"**
4. Click the **"Run workflow"** button (top right)
5. Select the branch (usually `main`)
6. Optionally check **"Skip health check verification"** if you want to skip health checks
7. Click **"Run workflow"**

The workflow will:
- ✅ Initialize Terraform
- ✅ Plan the changes
- ✅ Apply the infrastructure
- ✅ Wait for ALB to be ready
- ✅ Test the health endpoint
- ✅ Show results in the workflow summary

---

## 📋 Terraform Plan Workflow

This workflow runs **automatically** on Pull Requests:

**Steps:**
1. Create a feature branch:
   ```bash
   git checkout -b feature/my-changes
   ```
2. Make your Terraform changes
3. Commit and push:
   ```bash
   git add terraform/
   git commit -m "Add new resource"
   git push origin feature/my-changes
   ```
4. Open a Pull Request to `main`
5. The workflow will automatically:
   - Run `terraform fmt` check
   - Run `terraform validate`
   - Run `terraform plan`
   - Post results as a PR comment

---

## 🗑️ Terraform Destroy Workflow

**Manual trigger only** - Use with caution!

**Steps:**
1. Go to GitHub → Actions tab
2. Select **"Terraform Destroy"** from the left sidebar
3. Click **"Run workflow"**
4. Type **"destroy"** in the confirmation field
5. Click **"Run workflow"**

The workflow will:
- ✅ Validate confirmation
- ✅ Destroy all infrastructure
- ✅ Verify resources are destroyed
- ✅ Show verification summary

**⚠️ Warning:** This will delete ALL infrastructure. Make sure you really want to do this!

---

## 🔧 Terraform Bootstrap Workflow

**Manual trigger only** - Run once for initial setup.

**Steps:**
1. Go to GitHub → Actions tab
2. Select **"Terraform Bootstrap"** from the left sidebar
3. Click **"Run workflow"**
4. Type **"bootstrap"** in the confirmation field
5. Click **"Run workflow"**

This creates the S3 bucket and DynamoDB table for Terraform state (if they don't exist).

---

## 📝 Quick Reference

| Workflow | Trigger | When to Use |
|----------|---------|-------------|
| **Plan** | Auto (PRs) | Review changes before merging |
| **Apply** | Auto (push) or Manual | Deploy infrastructure |
| **Destroy** | Manual only | Remove all infrastructure |
| **Bootstrap** | Manual only | Initial setup (one-time) |

---

## 🔍 Viewing Workflow Results

After a workflow runs:

1. Go to **Actions** tab
2. Click on the workflow run
3. Expand steps to see logs
4. Check the **Summary** section for:
   - Terraform outputs
   - Health check results
   - Verification results (for destroy)

---

## ⚙️ Required Secrets

Make sure these secrets are configured in GitHub:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_STATE_BUCKET` (optional)
- `TF_STATE_LOCK_TABLE` (optional)

Go to: **Settings → Secrets and variables → Actions**

---

## 🐛 Troubleshooting

### Workflow not running?
- Check that secrets are configured
- Verify you're on the correct branch
- Check workflow file syntax

### Health check failing?
- ALB may still be initializing (wait a few minutes)
- Check security groups allow traffic
- Verify instances are healthy in AWS Console

### Destroy verification failing?
- Some resources take time to fully delete
- Check AWS Console to confirm deletion
- Wait a few minutes and check again
