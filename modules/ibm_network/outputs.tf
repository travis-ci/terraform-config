
output "vpc_id" {
    value = "${ibm_is_vpc.vpc.id}"
}

output "subnet_id" {
    value = "${ibm_is_subnet.subnet.id}"
}
