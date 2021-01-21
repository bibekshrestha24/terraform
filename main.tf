
#create ec2 instance
data "aws_ami" "amazonlx" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_instance" "mywebserver" {
  ami                    = data.aws_ami.amazonlx.id
  count                  = 2
  instance_type          = var.instance_type
  key_name               = "bibek"
  vpc_security_group_ids = [aws_security_group.allow_web.id]

  user_data = <<-EOF
                #! /bin/bash
                yum update -y
                yum install httpd -y
                systemctl start httpd
                systemctl enable httpd
                echo "The hostname is: `hostname`." > /var/www/html/index.html
                EOF
  tags = {
    Name = "instance ${count.index + 1}"
  }
}







