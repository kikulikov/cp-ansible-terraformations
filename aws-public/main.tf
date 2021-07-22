# Terraform Code

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "platform" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}

resource "aws_vpc" "platform" {
  cidr_block           = var.aws_ipv4_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name    = var.resource_name
    Owner   = var.resource_owner
    Email   = var.resource_email
    Purpose = var.resource_purpose
  }
  count = var.aws_vpc_id != "" ? 0 : 1
}

locals {
  aws_vpc_id    = var.aws_vpc_id != "" ? var.aws_vpc_id : aws_vpc.platform[0].id
  aws_ipv4_cidr = var.aws_ipv4_cidr != "" ? var.aws_ipv4_cidr : aws_vpc.platform[0].cidr_block
}

resource "aws_subnet" "platform" {
  cidr_block        = cidrsubnet(local.aws_ipv4_cidr, 3, 1)
  vpc_id            = local.aws_vpc_id
  availability_zone = var.aws_availability_zone
  tags = {
    Name    = var.resource_name
    Owner   = var.resource_owner
    Email   = var.resource_email
    Purpose = var.resource_purpose
  }
  count = var.aws_subnet_id != "" ? 0 : 1
}

locals {
  aws_subnet_id = var.aws_subnet_id != "" ? var.aws_subnet_id : aws_subnet.platform[0].id
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "allow_private" {
  name        = "confluent-platform-allow-private"
  description = "Allow private inbound traffic"
  vpc_id      = local.aws_vpc_id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${local.aws_ipv4_cidr}"]
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
  vpc_id      = local.aws_vpc_id
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

locals {
  ec2_ami_id = var.ec2_ami_type == "rhel" ? data.aws_ami.rhel_8.id : data.aws_ami.ubuntu_18.id
  # TODO ec2_ami_id = data.aws_ami.amazon_linux_2.id
}

locals {
  service_instances = flatten([
    for svc_name, svc in var.component : [
      for i in range(0, svc.instance_count) : {
        instance_name = "${svc_name}-${i}"
        instance_type = svc.instance_type
        # data_volume   = svc.data_volume
      }
    ]
  ])
  service_instances_map = {
    for inst in local.service_instances : inst.instance_name => inst
  }
}

resource "aws_instance" "component" {
  ami = local.ec2_ami_id

  # count = var.ec2_instance_count
  for_each = local.service_instances_map

  instance_type = each.value.instance_type
  key_name      = aws_key_pair.platform.key_name
  vpc_security_group_ids = [
    "${aws_security_group.allow_public.id}",
    "${aws_security_group.allow_private.id}"
  ]
  tags = {
    Name    = "${var.resource_name}-${each.value.instance_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
  root_block_device { # TODO attach volumes
    volume_size = 32
    volume_type = "gp2"
  }
  associate_public_ip_address = true
  subnet_id                   = local.aws_subnet_id
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
  vpc_id = local.aws_vpc_id
  tags = {
    Name    = "${var.resource_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
  
  # Skip for the existing VPC
  count = var.aws_vpc_id != "" ? 0 : 1
}

# Setting up the route table
resource "aws_route_table" "platform" {
  vpc_id = local.aws_vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.platform[0].id
  }
  tags = {
    Name    = "${var.resource_name}"
    Owner   = "${var.resource_owner}"
    Email   = "${var.resource_email}"
    Purpose = "${var.resource_purpose}"
  }
  
  # Skip for the existing VPC
  count = var.aws_vpc_id != "" ? 0 : 1
}

# Associating the route tables
resource "aws_route_table_association" "platform" {
  subnet_id      = local.aws_subnet_id
  route_table_id = aws_route_table.platform[0].id
  
  # Skip for the existing VPC
  count = var.aws_vpc_id != "" ? 0 : 1
}

data "aws_ami" "ubuntu_18" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  name_regex = "^ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-.*"
}

data "aws_ami" "rhel_8" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  name_regex = "^RHEL-8.*x86_64.*"
}

# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners = ["amazon"]

#   filter {
#     name   = "owner-alias"
#     values = ["amazon"]
#   }

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-ebs"]
#   }
# }
