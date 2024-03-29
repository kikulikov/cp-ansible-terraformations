# Terraform scripts for confluentinc/cp-ansible

Terraform scripts to provision infrastructure for confluentinc/cp-ansible

terraform output -state=demo.stockholm.tfstate -raw aws_private_key > demo.sweden.key

## Finding AWS AMI

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html

## Docker on Ubuntu

https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04

```bash
First, update your existing list of packages:

sudo apt update
Next, install a few prerequisite packages which let apt use packages over HTTPS:

sudo apt install apt-transport-https ca-certificates curl software-properties-common
Then add the GPG key for the official Docker repository to your system:

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
Add the Docker repository to APT sources:

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
Next, update the package database with the Docker packages from the newly added repo:

sudo apt update
Make sure you are about to install from the Docker repo instead of the default Ubuntu repo:

apt-cache policy docker-ce

Finally, install Docker:

sudo apt install docker-ce

sudo aptitude install -y docker-compose
sudo aptitude install -y git jq vim
```

## Docker on Amazon Linux 2

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html

```bash
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo chkconfig docker on
sudo yum install -y git
sudo reboot
```

docker-compose >>> https://gist.github.com/npearce/6f3c7826c7499587f00957fee62f8ee9

## TODO

Check https://github.com/adammck/terraform-inventory for inventory generation.

## Usage

### Initialize a Terraform working directory

```bash
terraform init aws-public
```

### Generate and show an execution plan

```bash
terraform plan -var="resource_email=kirill.kulikov@confluent.io" -var="resource_name=confluent-platform-551" -var="resource_owner=Kirill Kulikov" -var="resource_purpose=Testing CP 551" -var="ssh_key_name=kirill-kulikov-ssh" -var="ssh_public_key_path=~/.ssh/Kirill-Kulikov-Confluent.pub" -state=aws-public/terraform.tfstate aws-public
```

### Build Terraform-managed infrastructure

```bash
terraform apply -var="resource_email=kirill.kulikov@confluent.io" -var="resource_name=confluent-platform-551" -var="resource_owner=Kirill Kulikov" -var="resource_purpose=Testing CP 551" -var="ssh_key_name=kirill-kulikov-ssh" -var="ssh_public_key_path=~/.ssh/Kirill-Kulikov-Confluent.pub" -state=aws-public/terraform.tfstate aws-public
```

### Generate hosts.yml `cp-ansible` configuration

```bash
./hosts.py confluent-platform-531
```

### Provision services with the ansible playbook

```bash
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ~/confluent/cp-ansible-terraformations/hosts.yml all.yml
```

### Destroy Terraform-managed infrastructure

```bash
terraform destroy -var="resource_email=kirill.kulikov@confluent.io" -var="resource_name=confluent-platform-551" -var="resource_owner=Kirill Kulikov" -var="resource_purpose=Testing CP 551" -var="ssh_key_name=kirill-kulikov-ssh" -var="ssh_public_key_path=~/.ssh/Kirill-Kulikov-Confluent.pub" -state=aws-public/terraform.tfstate aws-public
```

## Ansible

### Run cp-ansible playbook using the hosts file generated above

```bash
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i hosts.yml all.yml
# OR
ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ../cp-ansible-terraformations/hosts.yml all.yml
```

## Kafka

### TLS configuration for consumers / producers

```bash
tee cp.properties <<EOF
ssl.truststore.location=generated_ssl_files/client.truststore.jks
ssl.truststore.password=confluent
ssl.truststore.type=JKS
ssl.keystore.location=generated_ssl_files/client.keystore.jks
ssl.keystore.password=confluent
ssl.keystore.type=JKS
ssl.key.password=confluent
ssl.endpoint.identification.algorithm=
security.protocol=SSL
ssl.protocol=TLS
EOF
```

### Kafka Console Producer

```bash
kafka-console-producer --broker-list ec2-3-10-4-138.eu-west-2.compute.amazonaws.com:9092 \
--producer.config cp.properties --topic ducks
```

### Kafka Console Consumer

```bash
kafka-console-consumer --bootstrap-server ec2-3-10-4-138.eu-west-2.compute.amazonaws.com:9092 \
--consumer.config cp.properties --topic ducks --from-beginning
```

### Producer Load Testing

```bash
kafka-producer-perf-test --topic ducks --num-records 100500 --record-size 32 --producer.config cp.properties \
--throughput 3 --producer-props bootstrap.servers=ec2-3-10-4-138.eu-west-2.compute.amazonaws.com:9092
```

### Consumer Load Testing

```bash
kafka-consumer-perf-test --topic ducks --consumer.config cp.properties --messages 100 \
--broker-list ec2-3-10-4-138.eu-west-2.compute.amazonaws.com:9092 --from-latest
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

## AWS Management

```bash
aws ec2 describe-vpcs
```

```bash
aws ec2 describe-security-groups \
--filter Name=group-name,Values=confluent-platform-allow-public Name=vpc-id,Values=vpc-009966c2797a21002
```

```bash
aws ec2 authorize-security-group-ingress --protocol tcp --port 9081 --cidr 185.106.73.75/32 --group-id sg-05cbcda7dad105729
```

```bash
sr-acl-cli --config /etc/schema-registry/schema-registry.properties --add -s '*' -p 'ANONYMOUS' -o 'SUBJECT_READ'
sr-acl-cli --config /etc/schema-registry/schema-registry.properties --add -p 'ANONYMOUS' -o 'GLOBAL_SUBJECTS_READ'
sr-acl-cli --config /etc/schema-registry/schema-registry.properties --add -p 'ANONYMOUS' -o 'GLOBAL_COMPATIBILITY_READ'
sr-acl-cli --config /etc/schema-registry/schema-registry.properties --add -s '*' -p 'C=UK,O=Confluent,L=London,CN=schema-registry' -o '*'
```

## Ansible Jump Host - WIP

https://docs.ansible.com/ansible/latest/reference_appendices/faq.html

https://spin.atomicobject.com/2016/05/16/ansible-aws-ec2-vpc/

ssh-add -k ~/.ssh/private_ssh_key.pem
ssh-add -L
ssh -A ubuntu@ec2-3-9-60-128.eu-west-2.compute.amazonaws.com -t 'ssh ubuntu@ip-10-0-39-206.eu-west-2.compute.internal'

