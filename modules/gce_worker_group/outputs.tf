output "workers_service_account_emails" {
  value = ["${module.gce_workers.workers_service_account_emails}"]
}

output "workers_service_account_names" {
  value = ["${module.gce_workers.workers_service_account_names}"]
}

output "redis_worker_rate_limit" {
  value = "${module.gce_workers.redis_worker_rate_limit}"
}
