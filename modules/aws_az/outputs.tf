output "bastion_eip" {
    value = "${aws_eip.bastion.public_ip}"
}

output "nat_eip" {
    value = "${aws_eip.nat.public_ip}"
}
