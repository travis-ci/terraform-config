variable "config_com" {}
variable "config_com_free" {}
variable "config_org" {}
variable "env" {}
variable "github_users" {}
variable "index" {}
variable "instance_count_com" {}
variable "instance_count_com_free" {}
variable "instance_count_org" {}

variable "machine_type" {
  default = "n1-standard-1"
}

variable "project" {}
variable "region" {}
variable "subnetwork_workers" {}
variable "syslog_address_com" {}
variable "syslog_address_org" {}
variable "worker_docker_self_image" {}
variable "worker_image" {}

variable "zones" {
  default = ["a", "b", "c", "f"]
}

resource "google_service_account" "workers" {
  account_id   = "workers"
  display_name = "travis-worker processes"
  project      = "${var.project}"
}

resource "google_project_iam_custom_role" "worker" {
  role_id     = "worker"
  title       = "travis-worker"
  description = "A travis-worker process that can do travis-worky stuff"

  permissions = [
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

resource "google_project_iam_member" "workers" {
  project = "${var.project}"
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.worker.role_id}"
  member  = "serviceAccount:${google_service_account.workers.email}"
}

resource "google_service_account_key" "workers" {
  service_account_id = "${google_service_account.workers.email}"
}

data "template_file" "cloud_init_env_com" {
  template = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "cloud_config_com" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../assets"
    cloud_init_env   = "${data.template_file.cloud_init_env_com.rendered}"
    gce_account_json = "${base64decode(google_service_account_key.workers.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_com}"
    worker_config    = "${var.config_com}"

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
  count = "${length(var.zones)}"
  name  = "${var.env}-${var.index}-worker-com-${element(var.zones, count.index)}-template-${substr(sha256("${var.worker_image}${data.template_file.cloud_config_com.rendered}"), 0, 7)}"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "com", "paid"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = "${var.worker_image}"
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_com.rendered}"
  }

  # TODO: port null_resource.worker_com_validation to instance group

  lifecycle {
    ignore_changes = ["disk", "boot_disk"]
  }
}

resource "google_compute_instance_group_manager" "worker_com" {
  count = "${length(var.zones)}"

  base_instance_name = "${var.env}-${var.index}-worker-com-${element(var.zones, count.index)}"
  instance_template  = "${element(google_compute_instance_template.worker_com.*.self_link, count.index)}"
  name               = "worker-com-${element(var.zones, count.index)}"
  target_size        = "${var.instance_count_com}"
  update_strategy    = "NONE"
  zone               = "${var.region}-${element(var.zones, count.index)}"
}

resource "google_compute_instance" "worker_com" {
  count = "${var.instance_count_com}"
  name  = "${var.env}-${var.index}-worker-com-${element(var.zones, count.index % length(var.zones))}-${(count.index / length(var.zones)) + 1}-gce"

  machine_type = "${var.machine_type}"
  zone         = "${var.region}-${element(var.zones, count.index % length(var.zones))}"
  tags         = ["worker", "${var.env}", "com", "paid"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.worker_image}"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_com.rendered}"
  }

  depends_on = ["null_resource.worker_com_validation"]

  lifecycle {
    ignore_changes = ["disk", "boot_disk"]
  }
}

data "template_file" "cloud_init_env_com_free" {
  template = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "cloud_config_com_free" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../assets"
    cloud_init_env   = "${data.template_file.cloud_init_env_com_free.rendered}"
    gce_account_json = "${base64decode(google_service_account_key.workers.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_com}"
    worker_config    = "${var.config_com_free}"

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
  count = "${length(var.zones)}"
  name  = "${var.env}-${var.index}-worker-com-free-${element(var.zones, count.index)}-template-${substr(sha256("${var.worker_image}${data.template_file.cloud_config_com_free.rendered}"), 0, 7)}"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "com", "free"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = "${var.worker_image}"
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_com_free.rendered}"
  }

  # TODO: port null_resource.worker_com_validation to instance group

  lifecycle {
    ignore_changes = ["disk", "boot_disk"]
  }
}

resource "google_compute_instance_group_manager" "worker_com_free" {
  count = "${length(var.zones)}"

  base_instance_name = "${var.env}-${var.index}-worker-com-free-${element(var.zones, count.index)}"
  instance_template  = "${element(google_compute_instance_template.worker_com_free.*.self_link, count.index)}"
  name               = "worker-com-free-${element(var.zones, count.index)}"
  target_size        = "${var.instance_count_com_free}"
  update_strategy    = "NONE"
  zone               = "${var.region}-${element(var.zones, count.index)}"
}

resource "google_compute_instance" "worker_com_free" {
  count = "${var.instance_count_com_free}"
  name  = "${var.env}-${var.index}-worker-com-free-${element(var.zones, count.index % length(var.zones))}-${(count.index / length(var.zones)) + 1}-gce"

  machine_type = "${var.machine_type}"
  zone         = "${var.region}-${element(var.zones, count.index % length(var.zones))}"
  tags         = ["worker", "${var.env}", "com", "free"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.worker_image}"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_com_free.rendered}"
  }

  depends_on = ["null_resource.worker_com_free_validation"]

  lifecycle {
    ignore_changes = ["disk", "boot_disk"]
  }
}

data "template_file" "cloud_init_env_org" {
  template = <<EOF
export TRAVIS_WORKER_SELF_IMAGE="${var.worker_docker_self_image}"
EOF
}

data "template_file" "cloud_config_org" {
  template = "${file("${path.module}/cloud-config.yml.tpl")}"

  vars {
    assets           = "${path.module}/../../assets"
    cloud_init_env   = "${data.template_file.cloud_init_env_org.rendered}"
    gce_account_json = "${base64decode(google_service_account_key.workers.private_key)}"
    here             = "${path.module}"
    syslog_address   = "${var.syslog_address_org}"
    worker_config    = "${var.config_org}"

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
  count = "${length(var.zones)}"
  name  = "${var.env}-${var.index}-worker-org-${element(var.zones, count.index)}-template-${substr(sha256("${var.worker_image}${data.template_file.cloud_config_org.rendered}"), 0, 7)}"

  machine_type = "${var.machine_type}"
  tags         = ["worker", "${var.env}", "org"]
  project      = "${var.project}"

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = "${var.worker_image}"
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_org.rendered}"
  }

  # TODO: port null_resource.worker_org_validation to instance group

  lifecycle {
    ignore_changes = ["disk", "boot_disk"]
  }
}

resource "google_compute_instance_group_manager" "worker_org" {
  count = "${length(var.zones)}"

  base_instance_name = "${var.env}-${var.index}-worker-org-${element(var.zones, count.index)}"
  instance_template  = "${element(google_compute_instance_template.worker_org.*.self_link, count.index)}"
  name               = "worker-org-${element(var.zones, count.index)}"
  target_size        = "${var.instance_count_org}"
  update_strategy    = "NONE"
  zone               = "${var.region}-${element(var.zones, count.index)}"
}

resource "google_compute_instance" "worker_org" {
  count = "${var.instance_count_org}"
  name  = "${var.env}-${var.index}-worker-org-${element(var.zones, count.index % length(var.zones))}-${(count.index / length(var.zones)) + 1}-gce"

  machine_type = "${var.machine_type}"
  zone         = "${var.region}-${element(var.zones, count.index % length(var.zones))}"
  tags         = ["worker", "${var.env}", "org"]
  project      = "${var.project}"

  boot_disk {
    auto_delete = true

    initialize_params {
      image = "${var.worker_image}"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "${var.subnetwork_workers}"

    access_config {
      # ephemeral ip
    }
  }

  metadata {
    "block-project-ssh-keys" = "true"
    "user-data"              = "${data.template_file.cloud_config_org.rendered}"
  }

  depends_on = ["null_resource.worker_org_validation"]

  lifecycle {
    ignore_changes = ["disk", "boot_disk"]
  }
}

output "workers_service_account_email" {
  value = "${google_service_account.workers.email}"
}

output "workers_service_account_name" {
  value = "${google_service_account.workers.name}"
}
