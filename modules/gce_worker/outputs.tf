# The images for the jobs are created on prod-1. To access these images from
# the other projects, we loop these accounts to prod-1 and give them permissions
# in prod-1. See gce-production-1/service_accounts.tf

output "workers_service_account_emails" {
  value = [
    "${google_service_account.workers_org.email}",
    "${google_service_account.workers_com.email}",
    "${google_service_account.workers_com_free.email}",
  ]
}
