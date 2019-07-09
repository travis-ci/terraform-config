output "workers_service_account_emails" {
  value = [
    "${google_service_account.workers_org.email}",
    "${google_service_account.workers_com.email}",
    "${google_service_account.workers_com_free.email}",
  ]
}

output "workers_service_account_names" {
  value = [
    "${google_service_account.workers_org.name}",
    "${google_service_account.workers_com.name}",
    "${google_service_account.workers_com_free.name}",
  ]
}

output "redis_worker_rate_limit" {
  value = "redis://${google_redis_instance.worker_rate_limit.host}:${google_redis_instance.worker_rate_limit.port}"
}
