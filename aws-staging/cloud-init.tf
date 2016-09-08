data "template_file" "worker_cloud_init_org" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    worker_config = "${file("${path.module}/config/worker-env-org")}"
    chef_json = "${file("${path.module}/config/chef-org.json")}"
  }
}


data "template_file" "worker_cloud_init_com" {
  template = "${file("${path.module}/worker-cloud-init.tpl")}"

  vars {
    worker_config = "${file("${path.module}/config/worker-env-com")}"
    chef_json = "${file("${path.module}/config/chef-com.json")}"
  }
}
