global
    log 127.0.0.1 local0
    maxconn 4096
    user haproxy
    group haproxy

defaults
    log global
    mode http
    retries 3
    timeout client 600s
    timeout connect 120s
    timeout server 600s
    option dontlognull
    option httplog
    option redispatch
    balance roundrobin

listen admin
    bind 127.0.0.1:22002
    mode http
    stats uri /

