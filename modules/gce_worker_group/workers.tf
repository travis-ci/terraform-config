module "gce_workers" {
  source = "../gce_worker"

  config_com      = "${var.worker_config_com}"
  config_com_free = "${var.worker_config_com_free}"
  config_org      = "${var.worker_config_org}"

  k8s_namespace = "${kubernetes_namespace.default.metadata.0.name}"
  env           = "${var.env}"
  github_users  = "${var.github_users}"
  index         = "${var.index}"

  managed_instance_count_com      = "${var.worker_managed_instance_count_com}"
  managed_instance_count_com_free = "${var.worker_managed_instance_count_com_free}"
  managed_instance_count_org      = "${var.worker_managed_instance_count_org}"

  machine_type             = "${var.worker_machine_type}"
  project                  = "${var.project}"
  region                   = "${var.region}"
  subnetwork_workers       = "${var.worker_subnetwork}"
  syslog_address_com       = "${var.syslog_address_com}"
  syslog_address_org       = "${var.syslog_address_org}"
  worker_docker_self_image = "${var.worker_docker_self_image}"
  worker_image             = "${var.worker_image}"
  zones                    = "${var.worker_zones}"
}
