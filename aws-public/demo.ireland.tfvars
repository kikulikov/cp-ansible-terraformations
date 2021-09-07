resource_name    = "confluent-platform-62x"
resource_owner   = "Kirill Kulikov"
resource_email   = "kirill.kulikov@confluent.io"
resource_purpose = "Testing CP 62x"

# ec2_ami_type = "ubuntu"
ec2_ami_type = "rhel"

# SSH Key
ssh_key_name        = "kirill-kulikov-ssh"
ssh_public_key_path = "~/.ssh/Kirill-Kulikov-Confluent.pub"

# AWS Settings
aws_region            = "eu-west-1"
aws_availability_zone = "eu-west-1a"

component = {
  jumpbox = {
    instance_count = 1
    instance_type  = "t3.micro"
  }
  zookeeper = {
    instance_count = 1
    instance_type  = "t3.medium"
  }
  kafka = {
    instance_count = 3
    instance_type  = "t3.large"
  }
  schemaregistry = {
    instance_count = 1
    instance_type  = "t3.medium"
  }
  connect = {
    instance_count = 1
    instance_type  = "t3.medium"
  }
  controlcenter = {
    instance_count = 1
    instance_type  = "t3.xlarge"
  }
  replicator = {
    instance_count = 1
    instance_type  = "t3.medium"
  }
}

aws_vpc_id    = "vpc-08da1069e2646f90f"
aws_subnet_id = "subnet-08ee5dfa7dff69142"
aws_ipv4_cidr = "172.30.0.0/16"

# vpc_security_group_ids = ["sg-055c8c07419910751","sg-09828bd2183b5f4bf"]
