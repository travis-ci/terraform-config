locals {
  master_vm_name = "${var.name_prefix}-master"
  master_ip      = "${vsphere_virtual_machine.master.clone.0.customize.0.network_interface.0.ipv4_address}"
}

resource "vsphere_virtual_machine" "master" {
  name             = "${local.master_vm_name}"
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

  clone {
    template_uuid = "${data.vsphere_virtual_machine.vanilla_template.id}"

    customize {
      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", var.ip_base)}"
        ipv4_netmask = 18
      }

      linux_options {
        host_name = "${local.master_vm_name}"
        domain    = "macstadium-us-se-1.travisci.net"
      }

      ipv4_gateway    = "10.182.64.1"
      dns_server_list = ["1.1.1.1", "1.0.0.1"]
      dns_suffix_list = ["vsphere.local"]
    }
  }

  wait_for_guest_net_routable = false

  connection {
    host  = "${vsphere_virtual_machine.master.clone.0.customize.0.network_interface.0.ipv4_address}"
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
      "sudo /tmp/create-master.sh",
    ]
  }
}

# The command needed to join additional nodes to the cluster
data "external" "kubeadm_join" {
  program = ["${path.module}/scripts/kubeadm-token.sh"]

  query = {
    host = "${local.master_ip}"
    user = "${var.ssh_user}"
  }

  depends_on = ["vsphere_virtual_machine.master"]
}

# The configuration needed for the Terraform Kubernetes provider
data "external" "kubectl_config" {
  program = ["${path.module}/scripts/kubeadm_config.py"]

  query = {
    host = "${local.master_ip}"
    user = "${var.ssh_user}"
  }

  depends_on = ["vsphere_virtual_machine.master"]
}

output "master_ip" {
  value = "${local.master_ip}"
}

output "host" {
  value = "${lookup(data.external.kubectl_config.result, "host")}"
}

output "cluster_ca_certificate" {
  value = "${lookup(data.external.kubectl_config.result, "cluster_ca_certificate")}"
}

output "client_certificate" {
  value = "${lookup(data.external.kubectl_config.result, "client_certificate")}"
}

output "client_key" {
  value = "${lookup(data.external.kubectl_config.result, "client_key")}"
}
