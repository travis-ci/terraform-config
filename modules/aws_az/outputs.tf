output "bastion_eip" {
    value = "${aws_eip.bastion.public_ip}"
}

output "nat_eip" {
    value = "${aws_eip.nat.public_ip}"
}

output "workers_subnet_id" {
    value = "${aws_subnet.workers.id}"
}

output "workers_security_group_id" {
    value = "${aws_security_group.workers.id}"
}
