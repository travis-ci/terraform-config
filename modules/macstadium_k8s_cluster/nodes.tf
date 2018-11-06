locals {
  node_vm_prefix = "${var.name_prefix}-node"
}

resource "vsphere_virtual_machine" "nodes" {
  depends_on = ["vsphere_virtual_machine.master"]

  count = "${var.node_count}"

  name             = "${local.node_vm_prefix}-${count.index + 1}"
  folder           = "${var.folder}"
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
    network_id     = "${data.vsphere_network.jobs.id}"
    use_static_mac = true
    mac_address    = "${var.mac_addresses[count.index]}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.vanilla_template.id}"

    customize {
      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", var.ip_base + count.index + 1)}"
        ipv4_netmask = 18
      }

      network_interface {
        ipv4_address = "${cidrhost(var.jobs_network_subnet, var.ip_base + count.index + 1)}"
        ipv4_netmask = 18
      }

      linux_options {
        host_name = "${local.node_vm_prefix}-${count.index + 1}"
        domain    = "macstadium-us-se-1.travisci.net"
      }

      ipv4_gateway    = "10.182.64.1"
      dns_server_list = ["1.1.1.1", "1.0.0.1"]
      dns_suffix_list = ["vsphere.local"]
    }
  }

  wait_for_guest_net_routable = false

  connection {
    host  = "${self.clone.0.customize.0.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod a+x /tmp/*.sh",
      "sudo /tmp/install-docker.sh",
      "sudo /tmp/install-kubernetes.sh",
      "sudo ${lookup(data.external.kubeadm_join.result, "command")}",
    ]
  }
}

resource "aws_route53_record" "nodes" {
  count   = "${var.node_count}"
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "${local.node_vm_prefix}-${count.index + 1}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${element(vsphere_virtual_machine.nodes.*.clone.0.customize.0.network_interface.0.ipv4_address, count.index)}"]
}
