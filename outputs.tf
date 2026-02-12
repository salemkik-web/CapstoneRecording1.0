
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}
output "db_endpoint" {
  value = aws_db_instance.wordpress.address
}

            output "db_port" {
  value = aws_db_instance.wordpress.port
}

 




