# ---------------------------------------------------------------------------------------------------------------------
# TODO
# 1. aws_key_pair from file
# 2. Namings
# 3. Documentation
# 4. No EIP for brokers
# ---------------------------------------------------------------------------------------------------------------------

# Variables

variable "resource_name" {
  default = "confluent-platform-53"
}

variable "resource_owner" {
  default = "Kirill Kulikov"
}

variable "resource_email" {
  default = "kirill.kulikov@confluent.io"
}

variable "resource_purpose" {
  default = "Testing CP 5.3.0 ansible deployment"
}

variable "ssh_key_name" {
  default = "kirill-kulikov-ssh"
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

# Terraform Code

provider "aws" {
  region = "${var.aws_region}"
}

# variable "key_pair_name" {
#   description = "The EC2 Key Pair to associate with the EC2 Instance for SSH access."
# }

resource "aws_key_pair" "platform" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${var.public_ssh_key}"
}

resource "aws_vpc" "platform" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
}

resource "aws_subnet" "platform" {
  cidr_block        = "${cidrsubnet(aws_vpc.platform.cidr_block, 3, 1)}"
  vpc_id            = "${aws_vpc.platform.id}"
  availability_zone = "${var.aws_availability_zone}"
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "allow_ssh" {
  name        = "confluent-platform-allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.platform.id}"
  ingress {
    cidr_blocks = [
      "${chomp(data.http.myip.body)}/32"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
}

resource "aws_security_group" "allow_tcp" {
  name        = "confluent-platform-allow-tcp"
  description = "Allow TCP inbound traffic"
  vpc_id      = "${aws_vpc.platform.id}"
  ingress {
    cidr_blocks = [
      "${chomp(data.http.myip.body)}/32"
    ]
    from_port = 9021
    to_port   = 9021
    protocol  = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
}

resource "aws_instance" "jump_host" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t3.micro"
  key_name      = "${aws_key_pair.platform.key_name}"
  security_groups = [
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.allow_tcp.id}"
  ]
  tags = {
    Name  = "${var.resource_name}-jump-host"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
  subnet_id = "${aws_subnet.platform.id}"
}

resource "aws_instance" "component" {
  count         = "${var.ec2_instance_count}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "m5.large"
  key_name      = "${aws_key_pair.platform.key_name}"
  security_groups = [
    "${aws_security_group.allow_ssh.id}",
    "${aws_security_group.allow_tcp.id}"
  ]
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
  subnet_id = "${aws_subnet.platform.id}"
}

# Attaching an elastic IP
resource "aws_eip" "platform_jump_host" {
  instance = "${aws_instance.jump_host.id}"
  vpc      = true
}

resource "aws_eip" "platform" {
  instance = "${element(aws_instance.component.*.id, count.index)}"
  count    = "${var.ec2_instance_count}"
  vpc      = true
}

# Setting up an internet gateway
resource "aws_internet_gateway" "platform" {
  vpc_id = "${aws_vpc.platform.id}"
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
}

# Setting up route tables
resource "aws_route_table" "platform" {
  vpc_id = "${aws_vpc.platform.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.platform.id}"
  }
  tags = {
    Name  = "${var.resource_name}"
    Owner = "${var.resource_owner}"
    Email = "${var.resource_email}"
    Email = "${var.resource_purpose}"
  }
}

resource "aws_route_table_association" "platform" {
  subnet_id      = "${aws_subnet.platform.id}"
  route_table_id = "${aws_route_table.platform.id}"
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
