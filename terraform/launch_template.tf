# ─── IAM ROLE for EC2 ─────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# SSM policy — allows Lambda/Bedrock pipeline to remotely read logs
# from instances without needing SSH or open ports
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ─── LAUNCH TEMPLATE ─────────────────────────────────────────────────────────

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  # Read bootstrap.sh and base64-encode it (required format for UserData)
  user_data = base64encode(file("${path.module}/userdata/bootstrap.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-app-instance"
      Project = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
