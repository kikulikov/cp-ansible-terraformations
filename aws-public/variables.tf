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
  description = "The AWS region to use (e.g. eu-west-2)"
  type        = string
  default     = "eu-west-2"
}

variable "aws_availability_zone" {
  description = "The AWS availbility zone to use (e.g. eu-west-2c)"
  type        = string
  default     = "eu-west-2c"
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

variable "component" {
  description = "Map of component names to configuration"
  type        = map(any)
  default = {
    jumpbox = {
      instance_count = 1
      instance_type  = "t3.micro"
    },
    zookeeper = {
      instance_count = 3
      instance_type  = "t3.medium"
    },
    kafka = {
      instance_count = 3
      instance_type  = "t3.medium"
    }
  }
}

variable "aws_vpc_id" {
  type = string
  default = ""
}

variable "aws_subnet_id" {
  type = string
  default = ""
}

variable "aws_ipv4_cidr" {
  type = string
  default = "10.0.0.0/16"
}
