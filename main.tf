terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# VARS
variable "accessKey" {
  description = "The access_key for AWS"
  type        = string
}

variable "secretKey" {
  description = "The secret_key for AWS"
  type        = string
}


# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  access_key = var.accessKey
  secret_key = var.secretKey
}


# Create a VPC
resource "aws_vpc" "Demo_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Terraform_demo2"
  }
}

# Create an internet Gateway
resource "aws_internet_gateway" "Demo_IGW" {
  vpc_id = aws_vpc.Demo_VPC.id

  tags = {
    Name = "Terraform_demo2"
  }
}

# Create a routing table for IPV4 and IPV6
resource "aws_route_table" "Demo_default_Route" {
  vpc_id = aws_vpc.Demo_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Demo_IGW.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_internet_gateway.Demo_IGW.id
  # }

  tags = {
    Name = "Terraform_demo2"
  }
}

# Create a Subnet
resource "aws_subnet" "Demo_Subnet" {
  vpc_id     = aws_vpc.Demo_VPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Terraform_demo2"
  }
}

# Create a route table association
resource "aws_route_table_association" "Demo_route_association" {
  subnet_id      = aws_subnet.Demo_Subnet.id
  route_table_id = aws_route_table.Demo_default_Route.id
}

# Create firewall 
resource "aws_security_group" "Demo_WebServer_Access_and_SSH" {
  name        = "allow_443_80_22"
  description = "Allow TLS inbound traffic web and ssh"
  vpc_id      = aws_vpc.Demo_VPC.id


  ingress {
    description      = "TLS to VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "port 80 to VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "ssh to to VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Terraform_Demo2"
  }
}

# Create a network interface
resource "aws_network_interface" "Demo_Nic" {
  subnet_id       = aws_subnet.Demo_Subnet.id
  private_ips     = ["10.0.2.101"]
  security_groups = [aws_security_group.Demo_WebServer_Access_and_SSH.id]

  tags = {
    Name = "Terraform_Demo2"
  }
}

# Create a public IP
resource "aws_eip" "Demo_Public_Ip" {
  vpc      = true
  network_interface = aws_network_interface.Demo_Nic.id
  associate_with_private_ip = "10.0.2.101"
  depends_on = [aws_internet_gateway.Demo_IGW]

  tags = {
    Name = "Terraform_Demo2"
  }
}

# # Create an Instance
# resource "aws_instance" "web_server_1" {
#   ami = "ami-04505e74c0741db8d"
#   instance_type = "t2.micro"
#   subnet_id  = aws_subnet.Demo_Subnet.id
#   availability_zone = "us-east-1a"
#   key_name = "Terraform_Demo"
  
#   network_interface {
#     device_index = 0
#     network_interface_id = aws_network_interface.Demo_Nic.id
#   }

#   user_data = <<-EOF
#                 #!/bin/bash
#                 sudo apt -y update
#                 sudo apt -y install apache2 -y
#                 sudo systemctl start apache2
#                 sudo systemctl enable apache2
#                 sudo bash -c 'echo -e Hello World \nfrom AWS and terraform > /var/www/html/index.html'
#                 EOF

#   tags = {
#     Name = "Terraform_Demo2"
#   }
#}