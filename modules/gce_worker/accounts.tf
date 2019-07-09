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
