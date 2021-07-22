resource_name = "confluent-platform-620"
resource_owner = "Kirill Kulikov"
resource_email = "kirill.kulikov@confluent.io"
resource_purpose = "Testing CP 620"

# ec2_ami_type = "ubuntu"
ec2_ami_type = "rhel"

# SSH Key
ssh_key_name = "kirill-kulikov-ssh"
ssh_public_key_path = "~/.ssh/Kirill-Kulikov-Confluent.pub"

# AWS Settings
aws_region = "eu-north-1"
aws_availability_zone = "eu-north-1a"

component = {
    jumpbox = {
        instance_count = 1
        instance_type = "t3.micro"
    }
    zookeeper = {
        instance_count = 1
        instance_type = "t3.medium"
    }
    kafka = {
        instance_count = 3
        instance_type = "t3.large"
    }
    controlcenter = {
        instance_count = 1
        instance_type = "t3.xlarge"
    }
    # connect = {
    #     instance_count = 2
    #     instance_type = "t3.medium"
    # }
    # schemaregistry = {
    #     instance_count = 2
    #     instance_type = "t3.medium"
    # }
}
