resource "aws_autoscaling_group" "asg" {
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  launch_template {
    id      = aws_launch_template.wp.id
    version = aws_launch_template.wp.latest_version
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  termination_policies = ["OldestInstance"]

  tag {
    key                 = "Name"
    value               = "wordpress-ec2"
    propagate_at_launch = true
  }

  wait_for_capacity_timeout = "10m"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_launch_template.wp,
    aws_lb_target_group.tg,
    aws_lb_listener.listener
  ]
}
