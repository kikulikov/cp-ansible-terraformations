# ---------------------------------------------------------------------------------------------------------------------
# TODO
# 1. Extract Variables
# 1. aws_key_pair from file
# 2. Namings
# 3. Documentation
# ---------------------------------------------------------------------------------------------------------------------

# Setting up inputs

variable "resource_name" {
  default = "kirill-kulikov-cp"
}

variable "resource_owner" {
  default = "Kirill Kulikov"
}

variable "public_ssh_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgabMpBLAUm8mqkRyysIp6xllh9rQDQ0JqGGK2UOPMUeq7j8EQpOq8yGahBOCjnA0KbP6pXcWqZO7H2FOyNYom+RcsKDdorOF8zmn7L8iKKFFtQjmEaiRi+O9ndYVm6gxBIZX4S0eQRPiwVjNE2ARt4AWfXPMTiQZmXf7vPxeRWsRwIDhLxEjM6Esw/Sytd3rMiZF5fkybHhqKDKZ7GlbUGngZdlK9w8AItZEYThknKvCkdt50ntZFjL3+b7ROW2RGm89kbA+j4w0gaDzCFgN/BRiKeoGblRXfHBSu7qOMARhcdO34DohGHRyjpz8utVzSN74sjUZw41C8vV25MMpT"
}

variable "aws_region" {
  default = "eu-west-2"
}

variable "aws_availability_zone" {
  default = "eu-west-2c"
}

variable "ec2_instance_count" {
  default = "4"
}

// Setting up AWS provider
provider "aws" {
  region = "${var.aws_region}"
}

// Setting up VPC
resource "aws_vpc" "kirill-kulikov-cp" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
  }
}

# variable "key_pair_name" {
#   description = "The EC2 Key Pair to associate with the EC2 Instance for SSH access."
# }

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "${var.public_ssh_key}"
}

resource "aws_subnet" "kirill-kulikov-cp" {
  cidr_block        = "${cidrsubnet(aws_vpc.kirill-kulikov-cp.cidr_block, 3, 1)}"
  vpc_id            = "${aws_vpc.kirill-kulikov-cp.id}"
  availability_zone = "${var.aws_availability_zone}"
}

// Setting up security groups
resource "aws_security_group" "kirill-kulikov-cp" {
  name   = "kirill-kulikov-cp"
  vpc_id = "${aws_vpc.kirill-kulikov-cp.id}"
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Launching EC2 instance
resource "aws_instance" "test-ec2-instance" {
  count                       = "${var.ec2_instance_count}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "m5.large"
  key_name                    = "${aws_key_pair.deployer.key_name}"
  security_groups             = ["${aws_security_group.kirill-kulikov-cp.id}"]
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
  }
  subnet_id = "${aws_subnet.kirill-kulikov-cp.id}"
}

# Attaching an elastic IP
resource "aws_eip" "kirill-kulikov-cp" {
  instance = "${element(aws_instance.test-ec2-instance.*.id, count.index)}"
  count    = "${var.ec2_instance_count}"
  vpc      = true
}

// Setting up an internet gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = "${aws_vpc.kirill-kulikov-cp.id}"
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
  }
}

// Setting up route tables
resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.kirill-kulikov-cp.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet-gateway.id}"
  }
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.kirill-kulikov-cp.id}"
  route_table_id = "${aws_route_table.route-table.id}"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["${var.ubuntu_account_number}"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

variable "ubuntu_account_number" {
  default = "099720109477"
}
