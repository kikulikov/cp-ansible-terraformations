# Terraform scripts for confluentinc/cp-ansible

Terraform scripts to provision infrastructure for confluentinc/cp-ansible

## Usage

### Initialize a Terraform working directory

```bash
terraform init aws-public
```

### Generate and show an execution plan

```bash
terraform plan -var="resource_email=kirill.kulikov@confluent.io" -var="resource_name=confluent-platform-531" -var="resource_owner=Kirill Kulikov" -var="resource_purpose=Testing CP 5.3.1" -var="ssh_key_name=kirill-kulikov-ssh" -var="ssh_public_key_path=~/.ssh/Kirill-Kulikov-Confluent.pub" -state=aws-public/terraform.tfstate aws-public
```

### Build Terraform-managed infrastructure

```bash
terraform apply -var="resource_email=kirill.kulikov@confluent.io" -var="resource_name=confluent-platform-531" -var="resource_owner=Kirill Kulikov" -var="resource_purpose=Testing CP 5.3.1" -var="ssh_key_name=kirill-kulikov-ssh" -var="ssh_public_key_path=~/.ssh/Kirill-Kulikov-Confluent.pub" -state=aws-public/terraform.tfstate aws-public
```

### Generate hosts.yml `cp-ansible` configuration

```bash
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ~/confluent/cp-ansible-terraformations/hosts.yml all.yml
```

### Destroy Terraform-managed infrastructure

```bash
terraform destroy -var="resource_email=kirill.kulikov@confluent.io" -var="resource_name=confluent-platform-531" -var="resource_owner=Kirill Kulikov" -var="resource_purpose=Testing CP 5.3.1" -var="ssh_key_name=kirill-kulikov-ssh" -var="ssh_public_key_path=~/.ssh/Kirill-Kulikov-Confluent.pub" -state=aws-public/terraform.tfstate aws-public
```

## Kafka

```bash
security.protocol=SSL
ssl.key.password=confluent
ssl.keystore.location=generated_ssl_files/client.keystore.jks
ssl.keystore.password=confluent
ssl.keystore.type=JKS
ssl.truststore.location=generated_ssl_files/client.truststore.jks
ssl.truststore.password=confluent
ssl.truststore.type=JKS
ssl.endpoint.identification.algorithm=
ssl.protocol=TLS
```

```bash
kafkacat -b ec2-18-130-205-109.eu-west-2.compute.amazonaws.com:9092 \
-X security.protocol=SSL \
-X ssl.key.location=generated_ssl_files/client.key \
-X ssl.key.password=confluent \
-X ssl.certificate.location=generated_ssl_files/client.certificate.pem \
-X ssl.ca.location=generated_ssl_files/snakeoil-ca-1.crt -L

echo "cnwejkfbhwekjnfjwerk" | kafkacat -b ec2-18-130-205-109.eu-west-2.compute.amazonaws.com:9092 \
-X security.protocol=SSL \
-X ssl.key.location=generated_ssl_files/client.key \
-X ssl.key.password=confluent \
-X ssl.certificate.location=generated_ssl_files/client.certificate.pem \
-X ssl.ca.location=generated_ssl_files/snakeoil-ca-1.crt -t bunch-of-monkeys -P
```

## Ansible

```bash
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i hosts.yml all.yml
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ~/confluent/cp-ansible-terraformations/hosts.yml all.yml
```

## AWS Describe Instances

```bash
aws ec2 describe-instances --output json --filters "Name=instance-state-code,Values=16"
```

```bash
aws ec2 describe-instances --output json --filters "Name=instance-state-code,Values=16" | jq -r '[.Reservations[].Instances[] | {State: .State.Name, InstanceType: .InstanceType, PublicIpAddress: .PublicIpAddress, InstanceId: .InstanceId, PublicDnsName: .PublicDnsName} ]'
```

```bash
aws ec2 describe-instances --output json --filters "Name=instance-state-code,Values=16" | jq -r '[.Reservations[].Instances[] | {State: .State.Name, InstanceType: .InstanceType, PublicIpAddress: .PublicIpAddress, InstanceId: .InstanceId, PublicDnsName: .PublicDnsName} ]' | grep -i PublicDnsName | cut -d':' -f2 | sort | cut -d'"' -f2
```

## Ansible Jump Host

https://docs.ansible.com/ansible/latest/reference_appendices/faq.html

https://spin.atomicobject.com/2016/05/16/ansible-aws-ec2-vpc/

ssh-add -k ~/.ssh/private_ssh_key.pem
ssh-add -L
ssh -A ubuntu@ec2-3-9-60-128.eu-west-2.compute.amazonaws.com -t 'ssh ubuntu@ip-10-0-39-206.eu-west-2.compute.internal'

## Examples

```terraform
variable "AMI_ID" {
  type    = "string"
  description = "AMI ID for the instance"
}
variable "EC2_INSTANCE_SIZE" {
  type    = "string"
  default = "t2.micro"
  description = "The EC2 instance size"
}
variable "EC2_ROOT_VOLUME_SIZE" {
  type    = "string"
  default = "30"
  description = "The volume size for the root volume in GiB"
}
variable "EC2_ROOT_VOLUME_TYPE" {
  type    = "string"
  default = "gp2"
  description = "The type of data storage: standard, gp2, io1"
}
variable "EC2_ROOT_VOLUME_DELETE_ON_TERMINATION" {
  default = true
  description = "Delete the root volume on instance termination."
}
```