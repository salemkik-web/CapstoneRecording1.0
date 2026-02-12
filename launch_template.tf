data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh.tpl")
  vars = {
    db_name     = "wordpress"
    db_user     = var.db_username
    db_password = var.db_password
    db_host     = aws_db_instance.wordpress.address
    alb_dns     = aws_lb.alb.dns_name
  }
}

resource "aws_launch_template" "wp" {
  name_prefix   = "wp-template"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id] 
  user_data = base64encode(data.template_file.userdata.rendered)
  key_name      = var.key_name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wordpress-ec2"
    }
}
}


