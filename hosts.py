#!/usr/bin/env python3

from argparse import ArgumentParser

from boto3 import client
from jinja2 import Template

parser = ArgumentParser(description='Hosts file generator')
parser.add_argument('ec2_instance_name', metavar='NAME', type=str,
                    help='EC2 instance name for filtering')
args = parser.parse_args()
ec2_instance_name = args.ec2_instance_name

ec2client = client('ec2')

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
            ec2_instance_name,
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
