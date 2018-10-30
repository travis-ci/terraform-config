resource "aws_route53_record" "wjb" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "wjb-${var.name_suffix}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.wjb.clone.0.customize.0.network_interface.0.ipv4_address}"]
}

resource "aws_route53_record" "util" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "util-${var.name_suffix}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.util.clone.0.customize.0.network_interface.0.ipv4_address}"]
}
