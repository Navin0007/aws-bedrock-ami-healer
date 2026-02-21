# ─── SSM PARAMETER WRITES ─────────────────────────────────────────────────────
# These write infra outputs to SSM Parameter Store after terraform apply.
# Other repos (bedrock, lambda, pipeline) read these values via data sources.
# SSM repo (aws-bedrock-ami-healer-ssm) creates the parameters with placeholders first.
# These resources overwrite the placeholders with real values.
#
# IMPORTANT: SSM paths use var.project_name (default: "ami-healer")
# All paths will be: /ami-healer/infra/<parameter-name>
# Ensure the SSM repo uses the same project_name value for path alignment.
#
# Note: data.aws_caller_identity.current is declared in backend_resources.tf

resource "aws_ssm_parameter" "infra_vpc_id" {
  name        = "/${var.project_name}/infra/vpc-id"
  type        = "String"
  value       = aws_vpc.main.id
  description = "VPC ID for ami-healer infra"
  overwrite   = true
}

resource "aws_ssm_parameter" "infra_private_subnet_ids" {
  name        = "/${var.project_name}/infra/private-subnet-ids"
  type        = "StringList"
  value       = join(",", aws_subnet.private[*].id)
  description = "Private subnet IDs - comma separated"
  overwrite   = true
}

resource "aws_ssm_parameter" "infra_alb_dns_name" {
  name        = "/${var.project_name}/infra/alb-dns-name"
  type        = "String"
  value       = aws_lb.main.dns_name
  description = "ALB DNS name for ami-healer"
  overwrite   = true
}

resource "aws_ssm_parameter" "infra_launch_template_id" {
  name        = "/${var.project_name}/infra/launch-template-id"
  type        = "String"
  value       = aws_launch_template.app.id
  description = "Launch template ID - used by bedrock pipeline to trigger instance refresh"
  overwrite   = true
}

resource "aws_ssm_parameter" "infra_asg_name" {
  name        = "/${var.project_name}/infra/asg-name"
  type        = "String"
  value       = aws_autoscaling_group.app.name
  description = "ASG name - used by bedrock pipeline for instance refresh"
  overwrite   = true
}

resource "aws_ssm_parameter" "infra_ami_id" {
  name        = "/${var.project_name}/infra/ami-id"
  type        = "String"
  value       = data.aws_ami.amazon_linux_2.id
  description = "Current working AMI ID - overwritten by AMI build pipeline after CVE scan"
  overwrite   = true

  lifecycle {
    ignore_changes = [value]
    # AMI build pipeline owns this value after initial apply.
    # Terraform sets it once; pipeline overwrites it on each successful build.
  }
}
