
output "Bastion VM external IP address" {
    value = "${ibm_is_floating_ip.bastion.address}"
}

#output "Worker external IP address" {
#    value = "${module.worker.worker_external_ip}"
#}

output "Worker private IP address" {
    value = "${module.worker.worker_private_ip}"
}

output "Worker org private IP address" {
    value = "${module.worker.worker_org_private_ip}"
}
