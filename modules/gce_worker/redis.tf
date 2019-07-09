resource "google_redis_instance" "worker_rate_limit" {
  name           = "worker-rate-limit"
  tier           = "STANDARD_HA"
  memory_size_gb = 1

  location_id             = "us-central1-a"
  alternative_location_id = "us-central1-f"

  authorized_network = "main"

  redis_version = "REDIS_3_2"
  display_name  = "Worker Rate Limit"
}
