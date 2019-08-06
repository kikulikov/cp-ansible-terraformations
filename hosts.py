#!/usr/bin/env python3

from jinja2 import Template
from boto3 import client

ec2client = client('ec2')
ec2_instance_name = "confluent-platform-53"

filters = [
    {
        'Name': 'instance-state-name',
        'Values': [
            'running',
        ]
    },
    {
        'Name': 'tag:Name',
        'Values': [
            'confluent-platform-53',
        ]
    },
]

response = ec2client.describe_instances(Filters=filters)
servers = []

for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
        servers.append(instance["PrivateDnsName"])

servers = sorted(servers)

for ec2 in servers:
    print('> ' + ec2)

with open('hosts.yml.jinja2') as file_:
    template = Template(file_.read())

output = template.render(servers=servers)

with open('hosts.yml', 'w+') as writer:
    writer.write(output + '\n')
