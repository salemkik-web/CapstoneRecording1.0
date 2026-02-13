# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "wp-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  security_groups    = [aws_security_group.alb_sg.id]
  enable_deletion_protection = false    
  internal = false
  idle_timeout             = 60
  tags = {
    Name = "wp-alb"
  }
}

# Target Group for EC2 instances
resource "aws_lb_target_group" "tg" {
  name     = "wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"              
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "wp-tg"
  }
}

# Listener for HTTP
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  tags = {
    Name = "wp-listener"
  }

  depends_on = [
    aws_lb.alb,
    aws_lb_target_group.tg
  ]


}
