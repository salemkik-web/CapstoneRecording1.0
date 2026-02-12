resource "aws_autoscaling_group" "asg" {
  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  vpc_zone_identifier = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  launch_template {
    id      = aws_launch_template.wp.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
}
