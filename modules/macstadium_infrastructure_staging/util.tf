resource "vsphere_virtual_machine" "util" {
  name             = "util-${var.name_suffix}"
  folder           = "Internal VMs"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus  = 4
  memory    = 4096
  guest_id  = "${data.vsphere_virtual_machine.vanilla_template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.vanilla_template.scsi_type}"

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.vanilla_template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.vanilla_template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.vanilla_template.disks.0.thin_provisioned}"
  }

  network_interface {
    network_id = "${data.vsphere_network.internal.id}"
  }

  network_interface {
    network_id = "${data.vsphere_network.management.id}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.vanilla_template.id}"

    customize {
      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", 40 + var.index)}"
        ipv4_netmask = 18
      }

      network_interface {
        ipv4_address = "${cidrhost("10.88.208.0/23", 498 + var.index)}"
        ipv4_netmask = 23
      }

      linux_options {
        host_name = "util-${var.name_suffix}"
        domain    = "macstadium-us-se-1.travisci.net"
      }

      ipv4_gateway    = "10.182.64.1"
      dns_server_list = ["1.1.1.1", "1.0.0.1"]
      dns_suffix_list = ["vsphere.local"]
    }
  }

  wait_for_guest_net_routable = false
}

output "util_ip" {
  value = "${vsphere_virtual_machine.util.clone.0.customize.0.network_interface.0.ipv4_address}"
}

output "util_uuid" {
  value = "${vsphere_virtual_machine.util.uuid}"
}
