<Plugin snmp>
	<Data "ifmib_if_octets64">
		Type "if_octets"
		Table true
		Instance "IF-MIB::ifName"
		Values "IF-MIB::ifHCInOctets" "IF-MIB::ifHCOutOctets"
	</Data>

	<Data "ifmib_if_packets64">
		Type "if_packets"
		Table true
		Instance "IF-MIB::ifName"
		Values "IF-MIB::ifHCInUcastPkts" "IF-MIB::ifHCOutUcastPkts"
	</Data>

	<Host "TravisCI-Prod-FW">
		Address "${fw_ip}"
		Version 2
		Community "${fw_snmp_community}"
		Collect "ifmib_if_octets64" "ifmib_if_packets64"
		Interval 60
	</Host>
</Plugin>
