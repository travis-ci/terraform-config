module "dhcp_server" {
  source                        = "../modules/macstadium_dhcp_server_2"
  index                         = 1
  datacenter                    = "pod-1"
  cluster                       = "MacPro_Pod_1"
  datastore                     = "DataCore1_1"
  internal_network_label        = "Internal"
  jobs_network_label            = "Jobs-1"
  jobs_network_subnet           = "10.182.0.0/18"
  mac_address                   = "00:50:56:84:b4:81"
  travisci_net_external_zone_id = "${var.travisci_net_external_zone_id}"
  ssh_user                      = "${var.ssh_user}"
}
