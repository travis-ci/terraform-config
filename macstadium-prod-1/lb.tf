data "vsphere_datacenter" "dc" {
  name = "pod-1"
}

data "vsphere_datastore" "datastore" {
  name          = "DataCore1_1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "MacPro_Pod_1"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "internal" {
  name          = "Internal"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "vanilla_template" {
  name          = "Vanilla VMs/travis-ci-centos7-internal-vanilla-1549473064"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "k8s_load_balancer" {
  name             = "cluster-1-lb"
  folder           = "Internal VMs"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus  = 2
  memory    = 2048
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
        ipv4_address = "${cidrhost("10.182.64.0/18", 336)}"
        ipv4_netmask = 18
      }

      linux_options {
        host_name = "cluster-1"
        domain    = "macstadium-us-se-1.travisci.net"
      }

      ipv4_gateway    = "10.182.64.1"
      dns_server_list = ["1.1.1.1", "1.0.0.1"]
      dns_suffix_list = ["vsphere.local"]
    }
  }

  wait_for_guest_net_routable = false

  connection {
    host  = "${vsphere_virtual_machine.k8s_load_balancer.clone.0.customize.0.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source      = "haproxy.cfg"
    destination = "/tmp/haproxy.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y haproxy",
      "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
      "sudo systemctl enable haproxy",
      "sudo systemctl start haproxy",
    ]
  }
}

resource "aws_route53_record" "k8s_load_balancer" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "cluster-1.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.k8s_load_balancer.clone.0.customize.0.network_interface.0.ipv4_address}"]
}
