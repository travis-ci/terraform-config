#!/bin/bash
# vim: set ft=sh :

set -e

ORG="${org}"
ADMIN_TEAM="${admin_team}"

GUARD_DATA_DIR=$(mktemp -d)
export GUARD_DATA_DIR

curl -Lo /usr/local/bin/guard https://github.com/appscode/guard/releases/download/0.3.0/guard-linux-amd64 \
  && chmod +x /usr/local/bin/guard

/usr/local/bin/guard init ca
/usr/local/bin/guard init server --ips="10.96.10.96"
/usr/local/bin/guard init client "$ORG" -o github

# Delete any existing Guard instance
kubectl delete deployment guard -n kube-system || true

/usr/local/bin/guard get installer --auth-providers=github >"$GUARD_DATA_DIR/installer.yaml"
kubectl apply -f "$GUARD_DATA_DIR/installer.yaml"

mkdir -p /etc/kubernetes/guard
/usr/local/bin/guard get webhook-config "$ORG" -o github --addr="10.96.10.96:443" >/etc/kubernetes/guard/webhook.yaml

python <<SCRIPT >"$GUARD_DATA_DIR/kube-apiserver.yaml"
import yaml
config = yaml.safe_load(open('/etc/kubernetes/manifests/kube-apiserver.yaml').read())
cmd = config['spec']['containers'][0]['command']
mounts = config['spec']['containers'][0]['volumeMounts']
volumes = config['spec']['volumes']

new_arg = '--authentication-token-webhook-config-file=/etc/kubernetes/guard/webhook.yaml'
if new_arg not in cmd:
  cmd.append(new_arg)

if not any(v['name'] == 'guard' for v in mounts):
  mounts.append({ 'readOnly': True, 'mountPath': '/etc/kubernetes/guard', 'name': 'guard' })

if not any(v['name'] == 'guard' for v in volumes):
  volumes.append({ 'hostPath': { 'path': '/etc/kubernetes/guard', 'type': 'DirectoryOrCreate' }, 'name': 'guard' })

print yaml.dump(config, default_flow_style=False)
SCRIPT

cp /etc/kubernetes/manifests/kube-apiserver.yaml "$GUARD_DATA_DIR/kube-apiserver-backup.yaml"
cp "$GUARD_DATA_DIR/kube-apiserver.yaml" /etc/kubernetes/manifests/kube-apiserver.yaml

# Travis CI employees are admins on the cluster
kubectl apply -f - <<RESOURCE
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: employees-team
subjects:
- kind: Group
  name: $ADMIN_TEAM
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
RESOURCE

# Restart the API server in case we didn't actually have to change it
# This ensures we pick up the most current webhook config
kubectl delete pod -l component=kube-apiserver -n kube-system
