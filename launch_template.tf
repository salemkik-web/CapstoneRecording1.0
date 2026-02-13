
locals {
  userdata = templatefile("${path.module}/userdata.sh.tpl", {
    db_name     = "wordpress"
    db_user     = var.db_username
    db_password = var.db_password
    db_host     = aws_db_instance.wordpress.address
    efs_id      = aws_efs_file_system.wp.id
  })
}


resource "aws_launch_template" "wp" {
  name_prefix   = "wp-template"
  image_id      = data.aws_ami.amazon_linux2.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = base64encode(local.userdata)
  key_name      = var.key_name
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wp-launch-template"
    }
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
  aws_db_instance.wordpress,
  aws_efs_mount_target.private_1,
  aws_efs_mount_target.private_2
]
}








