#!/usr/bin/env python

import sys
import subprocess
import yaml
import json

query = json.load(sys.stdin)
host = query['host']
user = query['user']

ssh_dest = user + '@' + host
config_str = subprocess.check_output(['ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', ssh_dest, 'sudo', 'cat', '/etc/kubernetes/admin.conf'])
config = yaml.safe_load(config_str)

cluster = config['clusters'][0]['cluster']
ca = cluster['certificate-authority-data']
server = cluster['server']
user = config['users'][0]['user']
cert = user['client-certificate-data']
key = user['client-key-data']

output = {
    'host': server,
    'cluster_ca_certificate': ca,
    'client_certificate': cert,
    'client_key': key
}

json.dump(output, sys.stdout)
