resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-asg"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  vpc_zone_identifier = aws_subnet.private[*].id

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  target_group_arns = [aws_lb_target_group.app.arn]

  # ELB health check means ASG terminates instance if ALB marks it unhealthy
  health_check_type         = "ELB"
  health_check_grace_period = 300

  termination_policies = ["OldestInstance"]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg"
    propagate_at_launch = false
  }
}
