# Terraform scripts for confluentinc/cp-ansible

Terraform scripts to provision infrastructure for confluentinc/cp-ansible

## Some Commands

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