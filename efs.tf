# ---------------------------
# EFS File System
# ---------------------------
resource "aws_efs_file_system" "wp" {
  creation_token = "wordpress-efs"

  tags = {
    Name = "wordpress-efs"
  }
}

# ---------------------------
# EFS Security Group
# ---------------------------
resource "aws_security_group" "efs_sg" {
  name   = "efs_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs_sg"
  }
}

# ---------------------------
# Mount Targets (VERY IMPORTANT)
# One per AZ / private subnet
# ---------------------------
resource "aws_efs_mount_target" "private_1" {
  file_system_id  = aws_efs_file_system.wp.id
  subnet_id       = aws_subnet.private_1.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "private_2" {
  file_system_id  = aws_efs_file_system.wp.id
  subnet_id       = aws_subnet.private_2.id
  security_groups = [aws_security_group.efs_sg.id]
}
