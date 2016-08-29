data "template_file" "worker_cloud_init_org" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    account_json = "${file("${path.module}/config/gce-workers-staging.json")}"
    worker_config = "${file("${path.module}/config/worker-env-org")}"
    chef_json = "${file("${path.module}/config/chef-org.json")}"
  }
}

data "template_file" "worker_cloud_init_com" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    account_json = "${file("${path.module}/config/gce-workers-staging.json")}"
    worker_config = "${file("${path.module}/config/worker-env-com")}"
    chef_json = "${file("${path.module}/config/chef-com.json")}"
  }
}

data "template_file" "bastion_cloud_init" {
  template = "${file("${path.module}/bastion-cloud-init.tpl")}"

  vars {
    bastion_config = "${file("${path.module}/config/bastion-env")}"
  }
}
