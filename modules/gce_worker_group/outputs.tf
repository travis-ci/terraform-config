output "workers_service_account_emails" {
  value = ["${module.gce_workers.workers_service_account_emails}"]
}
