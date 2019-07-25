#!/usr/bin/env python3

from jinja2 import Template
import boto3

ec2client = boto3.client('ec2')

# TODO proper filtering
filters = [
    {
        'Name': 'instance-state-name',
        'Values': [
            'running',
        ]
    },
]

response = ec2client.describe_instances(Filters=filters)
servers = []

for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
        servers.append(instance["PublicDnsName"])

servers = sorted(servers)

for ec2 in servers:
    print('> ' + ec2)

with open('hosts.yml.jinja2') as file_:
    template = Template(file_.read())

output = template.render(servers=servers)

with open('hosts.yml', 'w+') as writer:
    writer.write(output + '\n')
