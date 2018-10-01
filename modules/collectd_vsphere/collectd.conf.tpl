# Set by Librato
Interval 60

LoadPlugin syslog
<Plugin syslog>
	LogLevel info
</Plugin>

LoadPlugin cpu
LoadPlugin interface
LoadPlugin load
LoadPlugin memory
LoadPlugin ping

<Plugin ping>
	Host "smart-gorilla.rmq.cloudamqp.com"
	Interval 1.0
	Timeout 0.9
	MaxMissed 10
</Plugin>

<Plugin ping>
	Host "red-whale.rmq.cloudamqp.com"
	Interval 1.0
	Timeout 0.9
	MaxMissed 10
</Plugin>


<Plugin ping>
	Host "8.8.8.8"
	Interval 1.0
	Timeout 0.9
	MaxMissed -1
</Plugin>

<Plugin ping>
	Host "8.8.4.4"
	Interval 1.0
	Timeout 0.9
	MaxMissed -1
</Plugin>

Include "/opt/collectd/etc/collectd.conf.d/cpu.conf"
Include "/opt/collectd/etc/collectd.conf.d/librato.conf"
Include "/opt/collectd/etc/collectd.conf.d/disk.conf"
Include "/opt/collectd/etc/collectd.conf.d/df.conf"
Include "/opt/collectd/etc/collectd.conf.d/swap.conf"

# REQUIRED for Cisco SNMP info
LoadPlugin snmp
Include "/opt/collectd/etc/collectd.conf.d/snmp.conf"

# REQUIRED for collectd-vsphere
# Include "/opt/collectd/etc/collectd.conf.d/network.conf"

LoadPlugin network
<Plugin "network">
  <Listen "127.0.0.1" "1785">
    SecurityLevel "Encrypt"
    AuthFile "/opt/collectd/etc/collectd-network-auth"
  </Listen>
</Plugin>
