# Public subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
  tags = { Name = "public-1" }
  depends_on = [aws_internet_gateway.main]

}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = true
  tags = { Name = "public-2" }
  depends_on = [aws_internet_gateway.main]

}
# Private subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.availability_zone1
  tags = { Name = "private-1" }

}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability_zone2
  tags = { Name = "private-2" }
}
