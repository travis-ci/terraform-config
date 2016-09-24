output "workers_org_security_group_id" {
  value = "${aws_security_group.workers_org.id}"
}

output "workers_com_security_group_id" {
  value = "${aws_security_group.workers_com.id}"
}
