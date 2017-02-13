LoadPlugin write_http
<Plugin write_http>
  <Node "${host}">
    URL "https://collectd.librato.com/v1/measurements"
    Format "JSON"
    BufferSize 8192
    User "${email}"
    Password "${token}"
  </Node>
</Plugin>

# vim:filetype=upstart
