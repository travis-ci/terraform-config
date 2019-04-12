data "template_file" "dhcpd_install" {
  template = "${file("${path.module}/install-dhcpd.sh")}"
}

data "template_file" "dhcpd_conf" {
  template = "${file("${path.module}/dhcpd.conf.tpl")}"

  vars {
    # this is the jobs subnet. really all this does is lop the /18 off of the var
    jobs_subnet = "${cidrhost(var.jobs_network_subnet, 0)}"

    # dhcpd takes netmask in decimal form
    jobs_subnet_netmask = "${cidrnetmask(var.jobs_network_subnet)}"
    domain_name         = "macstadium.travisci.net"

    # we reserve the first 256 addresses of the subnet for ourselves. greedy
    jobs_subnet_begin = "${cidrhost(var.jobs_network_subnet, 256)}"

    # ...and the last 128, just in case.
    jobs_subnet_end = "${cidrhost(var.jobs_network_subnet, -128)}"

    # we assume the first address is the gateway (for now, it is)
    jobs_gateway = "${cidrhost(var.jobs_network_subnet, 1)}"

    # lease times are in seconds
    dhcp_lease_default_time = "600"
    dhcp_lease_max_time     = "12600"
  }
}

resource "vsphere_virtual_machine" "dhcp_server" {
  name             = "dhcp-server-${var.index}"
  folder           = "Internal VMs"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus  = 2
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
    mac_address    = "${var.mac_address}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.vanilla_template.id}"

    customize {
      network_interface {
        ipv4_address = "${cidrhost("10.182.64.0/18", 50 + var.index)}"
        ipv4_netmask = 18
      }

      network_interface {
        ipv4_address = "${cidrhost(var.jobs_network_subnet, 10)}"
        ipv4_netmask = 18
      }

      linux_options {
        host_name = "dhcp-server-${var.index}"
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
}

resource "null_resource" "dhcp_server" {
  triggers {
    install_script_signature = "${sha256(data.template_file.dhcpd_install.rendered)}"
    dhcpd_conf_signature     = "${sha256(data.template_file.dhcpd_conf.rendered)}"
    jobs_network_subnet      = "${var.jobs_network_subnet}"
    host_id                  = "${vsphere_virtual_machine.dhcp_server.id}"
  }

  connection {
    host  = "${vsphere_virtual_machine.dhcp_server.clone.0.customize.0.network_interface.0.ipv4_address}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    content     = "${data.template_file.dhcpd_conf.rendered}"
    destination = "/tmp/dhcpd.conf"
  }

  provisioner "remote-exec" {
    inline = ["${data.template_file.dhcpd_install.rendered}"]
  }
}

resource "aws_route53_record" "dhcp_server" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "dhcp-server-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.dhcp_server.clone.0.customize.0.network_interface.0.ipv4_address}"]
}
