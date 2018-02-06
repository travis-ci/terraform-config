subnet ${jobs_subnet} netmask ${jobs_subnet_netmask} {
  option domain-name "${domain_name}";
  range ${jobs_subnet_begin} ${jobs_subnet_end};
  option routers ${jobs_gateway};
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  default-lease-time ${dhcp_lease_default_time};
  max-lease-time ${dhcp_lease_max_time};
}
