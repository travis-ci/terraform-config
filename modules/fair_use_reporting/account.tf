variable "k8s_namespace" {}

resource "google_service_account" "fair_use_ip_query_report_account" {
  account_id   = "fair-use-ip-query-report"
  display_name = "fair-use-ip-query-report"
}

resource "google_project_iam_member" "fair_use_ip_query_report_dataviewer_member" {
  role   = "roles/bigquery.dataViewer"
  member = "serviceAccount:${google_service_account.fair_use_ip_query_report_account.email}"
}

resource "google_project_iam_member" "fair_use_ip_query_report_jobuser_member" {
  role   = "roles/bigquery.jobUser"
  member = "serviceAccount:${google_service_account.fair_use_ip_query_report_account.email}"
}

resource "google_service_account_key" "fair_use_ip_query_report_key" {
  service_account_id = "${google_service_account.fair_use_ip_query_report_account.email}"
}

resource "kubernetes_secret" "fair_use_ip_query_report_config" {
  metadata {
    name      = "fair-use-ip-query-report-terraform"
    namespace = "${var.k8s_namespace}"
  }

  data = {
    GOOGLE_APPLICATION_CREDENTIALS_JSON = "${base64decode(google_service_account_key.fair_use_ip_query_report_key.private_key)}"
  }
}

output "fair_use_ip_query_report_account_json" {
  value = "${base64decode(google_service_account_key.fair_use_ip_query_report_key.private_key)}"
}
