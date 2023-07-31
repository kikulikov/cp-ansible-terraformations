resource_name    = "confluent-platform-7xx"
resource_owner   = "Kirill Kulikov"
resource_email   = "kirill.kulikov@confluent.io"

ec2_ami_type = "ubuntu"
# ec2_ami_type = "rhel"

# AWS Settings
aws_region            = "eu-north-1"
aws_availability_zone = "eu-north-1b"

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
  #ksqldb = {
  #  instance_count = 1
  #  instance_type  = "t3.large"
  #}
  controlcenter = {
   instance_count = 1
   instance_type  = "t3.large"
  }
  #connect = {
  #  instance_count = 1
  #  instance_type = "t3.large"
  #}
  schemaregistry = {
   instance_count = 1
   instance_type = "t3.medium"
  }
}
