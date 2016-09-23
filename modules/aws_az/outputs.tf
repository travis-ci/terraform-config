output "bastion_eip" { value = "${aws_eip.bastion.public_ip}" }
output "bastion_id" { value = "${aws_instance.bastion.id}" }
output "bastion_sg_id" { value = "${aws_security_group.bastion.id}" }
output "nat_eip" { value = "${aws_eip.nat.public_ip}" }
output "nat_id" { value = "${aws_instance.nat.id}" }
output "public_subnet" { value = "${aws_subnet.public.cidr_block}" }
output "workers_com_subnet" { value = "${var.workers_com_subnet}" }
output "workers_org_subnet" { value = "${var.workers_org_subnet}" }
