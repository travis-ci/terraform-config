# vim:filetype=nginx
# https://www.nginx.com/blog/nginx-caching-guide/
# https://nginx.org/en/docs/http/ngx_http_proxy_module.html

proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m inactive=180m max_size=${max_size}m use_temp_path=off;

proxy_cache my_cache;
proxy_cache_background_update on;
proxy_cache_convert_head on;
proxy_cache_lock on;
proxy_cache_methods GET HEAD;
proxy_cache_revalidate on;
proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
proxy_cache_valid 180m;

proxy_ignore_headers
        Cache-Control
        Expires
        Set-Cookie
        Vary;
# "Pragma" ends up with things like "no-cache" in it, which also cramps our style
proxy_set_header Pragma '';

# HSTS is good, but it really cramps our style (and makes wget sad)
proxy_set_header Strict-Transport-Security '';

# docker + ipv6 = bad vibes
resolver 1.1.1.1 1.0.0.1 ipv6=off;

log_format cached
        '$upstream_cache_status $status $request_method "$scheme://$host:$server_port$request_uri" $server_protocol '
        '[$time_local] $remote_addr '
        '"$http_user_agent"';
access_log off; # turned back on in the "server" blocks (to avoid overlapping logging settings)

server {
        listen 80 reuseport;
        listen 11371 reuseport;

        access_log /var/log/nginx/access.log cached;

        location /__squignix_health__ {
                return 200 "vigorous\n";
                add_header Content-Type text/plain;
        }

        location / {
                if ($http_x_squignix) {
                        # prevent infinite recursion
                        return 429 'Squignix Redirecting To Itself\n';
                }

                proxy_pass $scheme://$host:$server_port;
                proxy_set_header Host $http_host;
                proxy_set_header X-Squignix true;

                add_header X-Cache-Status $upstream_cache_status;
        }
}
