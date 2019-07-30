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