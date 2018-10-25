resource "vsphere_virtual_machine" "wjb" {
  name             = "wjb-${var.name_suffix}"
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
    network_id = "${data.vsphere_network.jobs.id}"
  }

  network_interface {
    network_id = "${data.vsphere_network.management.id}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.vanilla_template.id}"

    customize {
      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", 30 + var.index)}"
        ipv4_netmask = 18
      }

      network_interface {
        ipv4_address = "${cidrhost(var.jobs_network_subnet, 30 + var.index)}"
        ipv4_netmask = 18
      }

      network_interface {
        ipv4_address = "${cidrhost("10.88.208.0/23", 496 + var.index)}"
        ipv4_netmask = 23
      }

      linux_options {
        host_name = "wjb-${var.name_suffix}"
        domain    = "macstadium-us-se-1.travisci.net"
      }

      ipv4_gateway    = "10.182.64.1"
      dns_server_list = ["1.1.1.1", "1.0.0.1"]
      dns_suffix_list = ["vsphere.local"]
    }
  }

  wait_for_guest_net_routable = false

  connection {
    host  = "${vsphere_virtual_machine.wjb.clone.0.customize.0.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "curl -s -v 'https://app.threatstack.com/agents/script?key=${var.threatstack_key}' | sudo bash",
    ]
  }
}

resource "null_resource" "worker" {
  triggers {
    host_id                = "${vsphere_virtual_machine.wjb.uuid}"
    ssh_key_file_signature = "${sha256(file(var.vm_ssh_key_path))}"
  }

  connection {
    host  = "${vsphere_virtual_machine.wjb.clone.0.customize.0.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source      = "${var.vm_ssh_key_path}"
    destination = "/tmp/travis-vm-ssh-key"
  }

  provisioner "remote-exec" {
    inline = [
      "if ! getent passwd travis-worker >/dev/null; then sudo useradd -r -s /usr/bin/nologin travis-worker; fi",
      "sudo mv /tmp/travis-vm-ssh-key /etc/travis-vm-ssh-key",
      "sudo chown travis-worker:travis-worker /etc/travis-vm-ssh-key",
      "sudo chmod 0600 /etc/travis-vm-ssh-key",
    ]
  }
}

output "wjb_ip" {
  value = "${vsphere_virtual_machine.wjb.clone.0.customize.0.network_interface.0.ipv4_address}"
}

output "wjb_uuid" {
  value = "${vsphere_virtual_machine.wjb.uuid}"
}
