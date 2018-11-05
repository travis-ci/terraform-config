module "kubernetes_cluster" {
  source                 = "../modules/macstadium_k8s_cluster"
  name_prefix            = "cluster-staging"
  ip_base                = 100
  node_count             = 2
  datacenter             = "pod-1"
  cluster                = "MacPro_Staging_1"
  datastore              = "DataCore1_1"
  internal_network_label = "Internal"
  jobs_network_label     = "Jobs-1"
  jobs_network_subnet    = "10.182.0.0/18"
  mac_addresses          = [
    "00:50:56:84:0b:b1",
    "00:50:56:84:0b:b2",
  ]
  ssh_user               = "${var.ssh_user}"
}
