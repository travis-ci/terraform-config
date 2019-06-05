variable "config_com" {}
variable "config_com_free" {}
variable "config_org" {}
variable "env" {}
variable "github_users" {}
variable "index" {}
variable "managed_instance_count_com" {}
variable "managed_instance_count_com_free" {}
variable "managed_instance_count_org" {}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "project" {}
variable "region" {}

variable "regions_abbrev" {
  default = {
    "us-central1" = "uc1"
    "us-east1"    = "ue1"
  }
}

variable "subnetwork_workers" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "worker_docker_self_image" {}

variable "worker_image" {
  default = "projects/ubuntu-os-cloud/global/images/family/ubuntu-1804-lts"
}

variable "zones" {
  default = ["a", "b", "c", "f"]
}

resource "google_service_account" "workers_com" {
  account_id   = "workers-com-${lookup(var.regions_abbrev, var.region, "unk")}"
  display_name = "travis-worker processes com ${var.region}"
}

resource "google_service_account" "workers_com_free" {
  account_id   = "workers-com-free-${lookup(var.regions_abbrev, var.region, "unk")}"
  display_name = "travis-worker processes com free ${var.region}"
}

resource "google_service_account" "workers_org" {
  account_id   = "workers-org-${lookup(var.regions_abbrev, var.region, "unk")}"
  display_name = "travis-worker processes org ${var.region}"
}

resource "google_project_iam_custom_role" "worker" {
  role_id     = "worker"
  title       = "travis-worker"
  description = "A travis-worker process that can do travis-worky stuff"

  permissions = [
    "cloudtrace.traces.patch",
    "compute.acceleratorTypes.get",
    "compute.acceleratorTypes.list",
    "compute.addresses.create",
    "compute.addresses.createInternal",
    "compute.addresses.delete",
    "compute.addresses.deleteInternal",
    "compute.addresses.get",
    "compute.addresses.list",
    "compute.addresses.setLabels",
    "compute.addresses.use",
    "compute.addresses.useInternal",
    "compute.diskTypes.get",
    "compute.diskTypes.list",
    "compute.disks.create",
    "compute.disks.createSnapshot",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.getIamPolicy",
    "compute.disks.list",
    "compute.disks.resize",
    "compute.disks.setIamPolicy",
    "compute.disks.setLabels",
    "compute.disks.update",
    "compute.disks.use",
    "compute.disks.useReadOnly",
    "compute.globalOperations.get",
    "compute.globalOperations.list",
    "compute.images.list",
    "compute.images.useReadOnly",
    "compute.instances.addAccessConfig",
    "compute.instances.addMaintenancePolicies",
    "compute.instances.attachDisk",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.deleteAccessConfig",
    "compute.instances.detachDisk",
    "compute.instances.get",
    "compute.instances.getGuestAttributes",
    "compute.instances.getIamPolicy",
    "compute.instances.getSerialPortOutput",
    "compute.instances.list",
    "compute.instances.listReferrers",
    "compute.instances.osAdminLogin",
    "compute.instances.osLogin",
    "compute.instances.removeMaintenancePolicies",
    "compute.instances.reset",
    "compute.instances.setDeletionProtection",
    "compute.instances.setDiskAutoDelete",
    "compute.instances.setIamPolicy",
    "compute.instances.setLabels",
    "compute.instances.setMachineResources",
    "compute.instances.setMachineType",
    "compute.instances.setMetadata",
    "compute.instances.setMinCpuPlatform",
    "compute.instances.setScheduling",
    "compute.instances.setServiceAccount",
    "compute.instances.setShieldedVmIntegrityPolicy",
    "compute.instances.setTags",
    "compute.instances.start",
    "compute.instances.startWithEncryptionKey",
    "compute.instances.stop",
    "compute.instances.update",
    "compute.instances.updateAccessConfig",
    "compute.instances.updateNetworkInterface",
    "compute.instances.updateShieldedVmConfig",
    "compute.instances.use",
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.machineTypes.get",
    "compute.machineTypes.list",
    "compute.networks.get",
    "compute.networks.list",
    "compute.networks.use",
    "compute.projects.get",
    "compute.regions.get",
    "compute.regions.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.zoneOperations.get",
    "compute.zoneOperations.list",
    "compute.zones.get",
    "compute.zones.list",
  ]
}

resource "google_project_iam_member" "workers_com" {
  role   = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member = "serviceAccount:${google_service_account.workers_com.email}"
}

resource "google_service_account_key" "workers_com" {
  service_account_id = "${google_service_account.workers_com.email}"
}

resource "google_project_iam_member" "workers_com_free" {
  role   = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member = "serviceAccount:${google_service_account.workers_com_free.email}"
}

resource "google_service_account_key" "workers_com_free" {
  service_account_id = "${google_service_account.workers_com_free.email}"
}

resource "google_project_iam_member" "workers_org" {
  role   = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member = "serviceAccount:${google_service_account.workers_org.email}"
}

resource "google_service_account_key" "workers_org" {
  service_account_id = "${google_service_account.workers_org.email}"
}

data "template_file" "cloud_config_com" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../../../assets"
    gce_account_json = "${base64decode(google_service_account_key.workers_com.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_com}"

    worker_config = <<EOF
${var.config_com}
export TRAVIS_WORKER_GCE_RATE_LIMIT_REDIS_URL=redis://${google_redis_instance.worker_rate_limit.host}:${google_redis_instance.worker_rate_limit.port}
EOF

    cloud_init_env = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "null_resource" "worker_com_validation" {
  triggers {
    config_signature = "${sha256(data.template_file.cloud_config_com.rendered)}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-worker-verify-config \
  "${base64encode(data.template_file.cloud_config_com.rendered)}"
EOF
  }
}

resource "google_compute_instance_template" "worker_com" {
  name_prefix = "${var.env}-${var.index}-worker-com-"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "com", "paid"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "${var.worker_image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  service_account {
    email = "${google_service_account.workers_com.email}"

    scopes = [
      "cloud-platform",
      "storage-full",
      "compute-rw",
      "trace-append",
    ]
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_com.rendered}"
  }

  depends_on = ["null_resource.worker_com_validation"]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["metadata.user-data"]
  }
}

resource "google_compute_region_instance_group_manager" "worker_com" {
  base_instance_name = "${var.env}-${var.index}-worker-com-gce"
  instance_template  = "${google_compute_instance_template.worker_com.self_link}"
  name               = "worker-com"
  target_size        = "${var.managed_instance_count_com}"
  update_strategy    = "NONE"
  region             = "${var.region}"

  distribution_policy_zones = "${formatlist("${var.region}-%s", var.zones)}"
}

data "template_file" "cloud_config_com_free" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../../../assets"
    gce_account_json = "${base64decode(google_service_account_key.workers_com_free.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_com}"

    worker_config = <<EOF
${var.config_com_free}
export TRAVIS_WORKER_GCE_RATE_LIMIT_REDIS_URL=redis://${google_redis_instance.worker_rate_limit.host}:${google_redis_instance.worker_rate_limit.port}
EOF

    cloud_init_env = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "null_resource" "worker_com_free_validation" {
  triggers {
    config_signature = "${sha256(data.template_file.cloud_config_com_free.rendered)}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-worker-verify-config \
  "${base64encode(data.template_file.cloud_config_com_free.rendered)}"
EOF
  }
}

resource "google_compute_instance_template" "worker_com_free" {
  name_prefix = "${var.env}-${var.index}-worker-com-free-"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "com", "free"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "${var.worker_image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  service_account {
    email = "${google_service_account.workers_com_free.email}"

    scopes = [
      "cloud-platform",
      "storage-full",
      "compute-rw",
      "trace-append",
    ]
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_com_free.rendered}"
  }

  depends_on = ["null_resource.worker_com_free_validation"]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["metadata.user-data"]
  }
}

resource "google_compute_region_instance_group_manager" "worker_com_free" {
  base_instance_name = "${var.env}-${var.index}-worker-com-free-gce"
  instance_template  = "${google_compute_instance_template.worker_com_free.self_link}"
  name               = "worker-com-free"
  target_size        = "${var.managed_instance_count_com_free}"
  update_strategy    = "NONE"
  region             = "${var.region}"

  distribution_policy_zones = "${formatlist("${var.region}-%s", var.zones)}"
}

data "template_file" "cloud_config_org" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../../../assets"
    gce_account_json = "${base64decode(google_service_account_key.workers_org.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_org}"

    worker_config = <<EOF
${var.config_org}
export TRAVIS_WORKER_GCE_RATE_LIMIT_REDIS_URL=redis://${google_redis_instance.worker_rate_limit.host}:${google_redis_instance.worker_rate_limit.port}
EOF

    cloud_init_env = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF

    docker_env = <<EOF
export TRAVIS_DOCKER_DISABLE_DIRECT_LVM=1
EOF

    github_users_env = <<EOF
export GITHUB_USERS='${var.github_users}'
EOF
  }
}

resource "null_resource" "worker_org_validation" {
  triggers {
    config_signature = "${sha256(data.template_file.cloud_config_org.rendered)}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/travis-worker-verify-config \
  "${base64encode(data.template_file.cloud_config_org.rendered)}"
EOF
  }
}

resource "google_compute_instance_template" "worker_org" {
  name_prefix = "${var.env}-${var.index}-worker-org-"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "org"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "${var.worker_image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  service_account {
    email = "${google_service_account.workers_org.email}"

    scopes = [
      "cloud-platform",
      "storage-full",
      "compute-rw",
      "trace-append",
    ]
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_org.rendered}"
  }

  depends_on = ["null_resource.worker_org_validation"]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["metadata.user-data"]
  }
}

resource "google_compute_region_instance_group_manager" "worker_org" {
  base_instance_name = "${var.env}-${var.index}-worker-org-gce"
  instance_template  = "${google_compute_instance_template.worker_org.self_link}"
  name               = "worker-org"
  target_size        = "${var.managed_instance_count_org}"
  update_strategy    = "NONE"
  region             = "${var.region}"

  distribution_policy_zones = "${formatlist("${var.region}-%s", var.zones)}"
}

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
