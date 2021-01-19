terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

#create vpc
resource "aws_vpc" "mycustomvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "webserver"
  }
}



#create internet-gateway
resource "aws_internet_gateway" "mycustomigw" {
  vpc_id = aws_vpc.mycustomvpc.id

  tags = {
    Name = "webserver"
  }
}

#create custom route table to access the internet through internet gateway
resource "aws_route_table" "myroutetable" {
  vpc_id = aws_vpc.mycustomvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mycustomigw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.mycustomigw.id
  }

  tags = {
    Name = "webserver"
  }
}

#create subnet with cidr block of 10.0.0.0/24 and assign public ip
resource "aws_subnet" "mycustomsubnet" {
  vpc_id            = aws_vpc.mycustomvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  /*map_public_ip_on_launch = true
  depends_on = [aws_internet_gateway.mycustomigw]*/
  tags = {
    Name = "webserver"
  }
}


#associate subnet with routetable
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mycustomsubnet.id
  route_table_id = aws_route_table.myroutetable.id
}

#create security group to allow port 22,80 and 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.mycustomvpc.id

  #inbound traffic
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#create network interface
resource "aws_network_interface" "webserver" {
  subnet_id       = aws_subnet.mycustomsubnet.id
  security_groups = [aws_security_group.allow_web.id]
}

#create elastic ip 
resource "aws_eip" "webserver" {
  instance   = aws_instance.mywebserver.id
  vpc        = true
  depends_on = [aws_internet_gateway.mycustomigw]
}

output "server_public_ip" {
  value = aws_eip.webserver.public_ip
}


#create ec2 instance
resource "aws_instance" "mywebserver" {
  ami               = var.instance_ami
  instance_type     = var.instance_type
  availability_zone = "us-west-2a"
  key_name          = "bibek"
  network_interface {
    network_interface_id = aws_network_interface.webserver.id
    device_index         = 0
  }
  user_data = <<-EOF
                #! /bin/bash
                yum update -y
                yum install httpd -y
                systemctl start httpd
                systemctl enable httpd
                echo "Welcome to my WebServer." > /var/www/html/index.html
                EOF
  tags = {
    Name = "my_webserver"
  }
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_ami" {
  type    = string
  default = "ami-0a36eb8fadc976275"
}




