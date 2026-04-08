terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
  }
}

resource "aws_vpc" "wordpress-tf-vpc" {
  cidr_block = "192.168.0.0/27"
  tags = {
    Name = "wordpress-tf-vpc"
  }
}

resource "aws_subnet" "public-tf-wordpress-subnet" {
  vpc_id     = aws_vpc.wordpress-tf-vpc.id
  cidr_block = "192.168.0.0/28"

  tags = {
    Name = "public-tf-wordpress-subnet"
  }
}

resource "aws_subnet" "private-tf-wordpress-subnet" {
  vpc_id     = aws_vpc.wordpress-tf-vpc.id
  cidr_block = "192.168.0.16/28"

  tags = {
    Name = "private-tf-wordpress-subnet"
  }
}

resource "aws_route_table" "public-tf-wordpress-rtb" {
  vpc_id = aws_vpc.wordpress-tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wordpress-tf-igw.id
  }

  tags = {
    Name = "public-tf-wordpress-rtb"
  }
}

resource "aws_route_table_association" "public-tf-wordpress-rtb-association" {
  subnet_id      = aws_subnet.public-tf-wordpress-subnet.id
  route_table_id = aws_route_table.public-tf-wordpress-rtb.id
}

resource "aws_route_table" "private-tf-wordpress-rtb" {
  vpc_id = aws_vpc.wordpress-tf-vpc.id

  tags = {
    Name = "private-tf-wordpress-rtb"
  }
}

resource "aws_route_table_association" "private-tf-wordpress-rtb-association" {
  subnet_id      = aws_subnet.private-tf-wordpress-subnet.id
  route_table_id = aws_route_table.private-tf-wordpress-rtb.id
}

resource "aws_internet_gateway" "wordpress-tf-igw" {
  vpc_id = aws_vpc.wordpress-tf-vpc.id

  tags = {
    Name = "wordpress-tf-igw"
  }
}

resource "aws_security_group" "wordpress-tf-sg" {
  name        = "wordpress-tf-sg"
  description = "Allow for HTTP and SSH access to the WordPress instance"
  vpc_id      = aws_vpc.wordpress-tf-vpc.id

  tags = {
    Name = "wordpress-tf-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "wordpress-tf-sg-allow-http" {
  security_group_id = aws_security_group.wordpress-tf-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "wordpress-tf-sg-allow-ssh" {
  security_group_id = aws_security_group.wordpress-tf-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "wordpress-tf-sg-allow-mysql" {
  security_group_id = aws_security_group.wordpress-tf-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "wordpress-tf-sg-allow-all" {
  security_group_id = aws_security_group.wordpress-tf-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# data "aws_ami" "amazon-linux-2023" { # Find the latest Amazon Linux 2023 AMI
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }

resource "aws_instance" "wordpress-tf-instance" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = "t3.small"
  associate_public_ip_address = true
  key_name                    = "YAIC-KeyPair"
  subnet_id                   = aws_subnet.public-tf-wordpress-subnet.id
  vpc_security_group_ids      = [aws_security_group.wordpress-tf-sg.id]
  depends_on                  = [aws_vpc.wordpress-tf-vpc, aws_subnet.public-tf-wordpress-subnet, aws_security_group.wordpress-tf-sg]

  tags = {
    Name = "wordpress-tf-instance"
  }
}
