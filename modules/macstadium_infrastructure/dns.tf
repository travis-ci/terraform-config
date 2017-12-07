resource "aws_route53_record" "vsphere" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "vsphere-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${var.vsphere_ip}"]
}

resource "aws_route53_record" "wjb" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "wjb-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"]
}

resource "aws_route53_record" "wjb-staging" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "wjb-staging-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.wjb-staging.network_interface.0.ipv4_address}"]
}

resource "aws_route53_record" "util" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "util-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.util.network_interface.0.ipv4_address}"]
}

resource "aws_route53_record" "pfsense-1" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "pfsense-1-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${var.pfsense_1_ip}"]
}

resource "aws_route53_record" "pfsense-2" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "pfsense-2-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${var.pfsense_2_ip}"]
}
