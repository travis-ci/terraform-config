resource "aws_route53_record" "wjb" {
  zone_id = "${var.travisci_net_external_zone_id}"
  name    = "wjb-${var.index}.macstadium-us-se-1.travisci.net"
  type    = "A"
  ttl     = 300
  records = ["${vsphere_virtual_machine.wjb.network_interface.0.ipv4_address}"]
}
