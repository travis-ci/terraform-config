data "template_file" "worker_cloud_init_org" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    chef_json = "${file("${path.module}/config/chef-org.json")}"
    env = "${var.env}"
    site = "org"
    worker_config = "${file("${path.module}/config/worker-env-org")}"
  }
}


data "template_file" "worker_cloud_init_com" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    chef_json = "${file("${path.module}/config/chef-com.json")}"
    env = "${var.env}"
    site = "com"
    worker_config = "${file("${path.module}/config/worker-env-com")}"
  }
}

data "template_file" "bastion_cloud_init" {
  template = "${file("${path.module}/bastion-cloud-init.tpl")}"

  vars {
    bastion_config = "${file("${path.module}/config/bastion-env")}"
    env = "${var.env}"
  }
}
