
output "worker_private_ip" {
    value = "${ibm_is_instance.worker.*.primary_network_interface.0.primary_ipv4_address}"
}

output "worker_org_private_ip" {
    value = "${ibm_is_instance.worker-org.*.primary_network_interface.0.primary_ipv4_address}"
}
