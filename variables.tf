variable "region" {
  default = "us-west-2"
}

variable "availability_zone1" {
  default = "us-west-2a"
}

variable "availability_zone2" {
  default = "us-west-2b"      
          
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "db_username" {      


  default = "admin"
}

variable "db_password" {        
  default = "StrongPassword123!"
}

variable "myip" {     
  type    = string
  default = "149.233.230.216/32"
}





variable "key_name" {
  description = "The AWS Key Pair name for SSH access"
  type        = string
  default     = "vockey"  
}





