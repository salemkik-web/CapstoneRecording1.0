 resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 2
  max_size             = 2
  min_size             = 2
  vpc_zone_identifier  = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  # Launch template reference
launch_template {
    id      = aws_launch_template.wp.id
    version = "$Latest" #  
}


  target_group_arns = [aws_lb_target_group.tg.arn]

  # Health check type for ALB integration
  health_check_type          = "ELB"
  health_check_grace_period  = 300   # 5 minutes, adjust for WordPress initialization

  # Tags for EC2 naming
  tag {
    key                 = "Name"
    value               = "wordpress-ec2"
    propagate_at_launch = true
  }

  # Prevent ASG from being destroyed unexpectedly
  force_delete = false

  # Optional: wait for instances to be healthy before finishing apply
  wait_for_capacity_timeout = "10m"
}
