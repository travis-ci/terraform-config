output "workers_org_subnet_id" {
  value = "${aws_subnet.workers_org.id}"
}

output "workers_org_security_group_id" {
  value = "${aws_security_group.workers_org.id}"
}

output "workers_com_subnet_id" {
  value = "${aws_subnet.workers_com.id}"
}

output "workers_com_security_group_id" {
  value = "${aws_security_group.workers_com.id}"
}
