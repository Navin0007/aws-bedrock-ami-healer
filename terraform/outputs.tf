output "alb_dns_name" {
  description = "DNS name of the ALB — use this to test the app"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "Full URL to test the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "health_check_url" {
  description = "URL to test the health check endpoint directly"
  value       = "http://${aws_lb.main.dns_name}/health"
}

output "launch_template_id" {
  description = "Launch Template ID — needed later for the Bedrock pipeline"
  value       = aws_launch_template.app.id
}

output "launch_template_name" {
  description = "Launch Template name"
  value       = aws_launch_template.app.name
}

output "asg_name" {
  description = "Auto Scaling Group name — needed for EventBridge rules"
  value       = aws_autoscaling_group.app.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "working_ami_id" {
  description = "The Amazon Linux 2 AMI used in the working baseline"
  value       = data.aws_ami.amazon_linux_2.id
}

output "terraform_state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
