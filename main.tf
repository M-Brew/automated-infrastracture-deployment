terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

# VARIABLES
variable "region" {}
variable "availability_zone" {}
variable "key_name" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

# PROVIDERS
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "vpc_1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc_1"
  }
}

# RESOURCES
resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "igw_1"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow defined incoming and outgoing traffic."
  vpc_id      = aws_vpc.vpc_1.id

  tags = {
    Name = "allow_web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "https_rule" {
  security_group_id = aws_security_group.allow_web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http_rule" {
  security_group_id = aws_security_group.allow_web.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_rule" {
  security_group_id = aws_security_group.allow_web.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_web.id
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}

resource "aws_network_interface" "net_int" {
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.net_int.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.igw_1, aws_instance.test_web_server]
}

resource "aws_instance" "test_web_server" {
  ami               = "ami-0cf2b4e024cdb6960"
  instance_type     = "t2.micro"
  availability_zone = var.availability_zone
  key_name          = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.net_int.id
    device_index         = 0
  }

  user_data = file("userdata.tpl")

  tags = {
    Name = "Test Web Server"
  }

  depends_on = [aws_network_interface.net_int]
}

# OUTPUT
output "server_public_ip" {
  value = aws_eip.one.public_ip
}
