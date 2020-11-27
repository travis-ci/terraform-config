version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
  maintenance:
    uploadpurging:
      enabled: true
      age: 6h
      interval: 1h
      dryrun: false
http:
  addr: :443
  headers:
    X-Content-Type-Options: [nosniff]
    #auth:
    #  htpasswd:
    #realm: basic-realm
    #path: /etc/registry
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
  remoteurl: https://registry-1.docker.io
