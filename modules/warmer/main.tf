variable "env" {}
variable "heroku_org" {}
variable "honeycomb_key" {}
variable "index" {}
variable "project" {}

variable "redis_plan" {
  default = "premium-0"
}

variable "region" {}
variable "app_scale" {}
variable "app_version" {}

resource "random_string" "auth_token" {
  length           = 31
  special          = true
  override_special = "!#$%&()+-?@[]^_"
}

resource "google_project_iam_custom_role" "warmer" {
  role_id     = "warmer"
  title       = "Warmer"
  description = "A warmer that can do warmer stuff"

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

resource "google_service_account" "warmer" {
  account_id   = "warmer"
  display_name = "Warmer"
  project      = "${var.project}"
}

resource "google_project_iam_member" "warmer" {
  project = "${var.project}"
  role    = "projects/${var.project}/roles/${google_project_iam_custom_role.warmer.role_id}"
  member  = "serviceAccount:${google_service_account.warmer.email}"
}

resource "google_service_account_key" "warmer" {
  service_account_id = "${google_service_account.warmer.email}"
}

resource "heroku_app" "warmer" {
  name   = "travis-warmer-${var.env}-${var.index}"
  region = "us"

  organization {
    name = "${var.heroku_org}"
  }

  config_vars {
    BUILDPACK_URL      = "https://github.com/bundler/heroku-buildpack-bundler2"
    HONEYCOMB_WRITEKEY = "${var.honeycomb_key}"
    HONEYCOMB_DATASET  = "warmer"
    MANAGED_VIA        = "github.com/travis-ci/terraform-config"
    RACK_ENV           = "${var.env}"

    WARMER_AUTH_TOKENS               = "${random_string.auth_token.result}"
    WARMER_GOOGLE_CLOUD_KEYFILE_JSON = "${base64decode(google_service_account_key.warmer.private_key)}"
    WARMER_GOOGLE_CLOUD_PROJECT      = "${var.project}"
    WARMER_GOOGLE_CLOUD_REGION       = "${var.region}"
    WARMER_ORPHAN_THRESHOLD          = 20
    WARMER_POOL_CHECK_INTERVAL       = 30
    WARMER_VM_CREATION_TIMEOUT       = 120
  }
}

resource "heroku_addon" "redis" {
  app  = "${heroku_app.warmer.name}"
  plan = "heroku-redis:${var.redis_plan}"
}

resource "null_resource" "warmer" {
  triggers {
    config_signature = "${sha256(jsonencode(heroku_app.warmer.config_vars))}"
    heroku_id        = "${heroku_app.warmer.id}"
    ps_scale         = "${var.app_scale}"
    app_version      = "${var.app_version}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../../bin/heroku-wait-deploy-scale \
  --repo=travis-ci/warmer \
  --app="${heroku_app.warmer.id}" \
  --ps-scale="${var.app_scale}" \
  --deploy-version="${var.app_version}"
EOF
  }
}

output "service_account_emails" {
  value = [
    "${google_service_account.warmer.email}",
  ]
}

output "auth_token" {
  value     = "${random_string.auth_token.result}"
  sensitive = true
}

output "app_hostname" {
  value = "${heroku_app.warmer.heroku_hostname}"
}
