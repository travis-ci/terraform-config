module "dhcp_server" {
  source                        = "../modules/macstadium_dhcp_server_2"
  index                         = 2
  datacenter                    = "pod-2"
  cluster                       = "MacPro_Pod_2"
  datastore                     = "DataCore1_3"
  internal_network_label        = "Internal"
  jobs_network_label            = "Jobs-2"
  jobs_network_subnet           = "10.182.128.0/18"
  mac_address                   = "00:50:56:ab:d3:e4"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  ssh_user                      = "${var.ssh_user}"
}
