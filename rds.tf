resource "aws_db_subnet_group" "main" {
  name       = "wordpress-db-subnet"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags = {
    Name = "wordpress-db-subnet"
  }

        depends_on = [
    aws_subnet.private_1,
    aws_subnet.private_2
  ]


}

resource "aws_db_instance" "wordpress" {
  identifier              = "wordpress-db"
  engine                  = "mysql"
  engine_version          = "8.4.7"              
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"               
  db_name                 = "wordpress"
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  multi_az                = false               # single AZ
  auto_minor_version_upgrade = true

  tags = {
    Name = "wordpress-db"
  }

          depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds_sg
  ]
  timeouts {
    create = "40m"
    delete = "40m"
    update = "40m"
  }

  parameter_group_name = "default.mysql8.0"
  apply_immediately    = true
  monitoring_interval  = 60

        





}
