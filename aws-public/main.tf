# Variables

variable "resource_name" {
  description = "The `Name` tag to use for provisioned services (e.g. confluent-platform-551)"
  type        = string
}

variable "resource_owner" {
  description = "The `Owner` tag to use for provisioned services (e.g. Kirill Kulikov)"
  type        = string
}

variable "resource_email" {
  description = "The `Email` tag to use for provisioned services (e.g. kirill.kulikov@confluent.io)"
  type        = string
}

variable "resource_purpose" {
  description = "The `Purpose` tag to use for provisioned services (e.g. Testing CP 551)"
  type        = string
}

variable "aws_region" {
  description = "The region to use (e.g. eu-west-2)"
  type        = string
  default     = "eu-west-2"
}

variable "aws_availability_zone" {
  description = "The availbility zone to use (e.g. eu-west-2c)"
  type        = string
  default     = "eu-west-2c"
}

variable "ec2_instance_count" {
  description = "The number of EC2 Instances to run (e.g. 4)"
  type        = string
  default     = "4"
}

variable "ec2_instance_type" {
  description = "The type of EC2 Instances to run (e.g. m5.large)"
  type        = string
  default     = "m5.large"
}

variable "ec2_ami_type" {
  description = "The type of AMI to run on EC2 Instances (ubuntu, rhel)"
  type        = string
  default     = "ubuntu"
}

variable "ssh_key_name" {
  description = "The key pair name (e.g. kirill-kulikov-ssh)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "The path to the SSH public key (e.g. ~/.ssh/Kirill-Kulikov-Confluent.pub)"
  type        = string
}

# Terraform Code

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "platform" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}

resource "aws_vpc" "platform" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name    = var.resource_name
    Owner   = var.resource_owner
    Email   = var.resource_email
    Purpose = var.resource_purpose
  }
}

resource "aws_subnet" "platform" {
  cidr_block        = cidrsubnet(aws_vpc.platform.cidr_block, 3, 1)
  vpc_id            = aws_vpc.platform.id
  availability_zone = var.aws_availability_zone
  tags = {
    Name    = var.resource_name
    Owner   = var.resource_owner
    Email   = var.resource_email
    Purpose = var.resource_purpose
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "allow_private" {
  name        = "confluent-platform-allow-private"
  description = "Allow private inbound traffic"
  vpc_id      = "${aws_vpc.platform.id}"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = var.resource_name
    Owner   = var.resource_owner
    Email   = var.resource_email
    Purpose = var.resource_purpose
  }
}

resource "aws_security_group" "allow_public" {
  name        = "confluent-platform-allow-public"
  description = "Allow public inbound traffic"
  vpc_id      = aws_vpc.platform.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "SSH"
  }
  ingress {
    from_port   = 9021
    to_port     = 9021
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "Control Center"
  }
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "Kafka"
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "Schema Registry"
  }
  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    description = "Kafka"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "${var.resource_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
}

# resource "aws_instance" "jumpbox" {
#   ami           = "${data.aws_ami.ubuntu.id}"
#   instance_type = "t3.micro"
#   key_name      = "${aws_key_pair.platform.key_name}"
#   vpc_security_group_ids = [
#     "${aws_security_group.allow_public.id}"
#   ]
#   tags = {
#     Name    = "${var.resource_name}-jumpbox"
#     Owner   = "${var.resource_owner}"
#     Email   = "${var.resource_email}"
#     Purpose = "${var.resource_purpose}"
#   }
#   root_block_device {
#     volume_size = 8
#     volume_type = "gp2"
#   }
#   # associate_public_ip_address = true
#   subnet_id = "${aws_subnet.platform.id}"
# }

locals {
  ec2_ami_id = var.ec2_ami_type == "rhel" ? data.aws_ami.rhel.id : data.aws_ami.ubuntu.id
}

resource "aws_instance" "component" {
  count         = "${var.ec2_instance_count}"
  ami           = "${local.ec2_ami_id}"

  instance_type = "${var.ec2_instance_type}"
  key_name      = "${aws_key_pair.platform.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.allow_public.id}",
    "${aws_security_group.allow_private.id}"
  ]
  tags = {
    Name    = "${var.resource_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
  root_block_device {
    volume_size = 16
    volume_type = "gp2"
  }
  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.platform.id}"
}

# Attaching an elastic IP
# resource "aws_eip" "platform_jumpbox" {
#   instance = "${aws_instance.jumpbox.id}"
#   vpc      = true
#   tags = {
#     Name    = "${var.resource_name}"
#     Owner   = "${var.resource_owner}"
#     Email   = "${var.resource_email}"
#     Purpose = "${var.resource_purpose}"
#   }
# }

# resource "aws_eip" "platform" {
#   instance = "${element(aws_instance.component.*.id, count.index)}"
#   count    = "${var.ec2_instance_count}"
#   vpc      = true
# }

# Setting up an internet gateway
resource "aws_internet_gateway" "platform" {
  vpc_id = "${aws_vpc.platform.id}"
  tags = {
    Name    = "${var.resource_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
}

# Setting up the route table
resource "aws_route_table" "platform" {
  vpc_id = "${aws_vpc.platform.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.platform.id}"
  }
  tags = {
    Name    = "${var.resource_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
}

# Associating the route tables
resource "aws_route_table_association" "platform" {
  subnet_id      = "${aws_subnet.platform.id}"
  route_table_id = "${aws_route_table.platform.id}"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

 filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  name_regex = "^ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-.*"
}

data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"]

 filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  name_regex = "^RHEL-7.*x86_64.*"
}
