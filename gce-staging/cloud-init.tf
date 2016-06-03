resource "template_file" "cloud_init_org" {
    template = "${file("${path.module}/cloud-init.tpl")}"

    vars {
        account_json = "${file("${path.module}/config/gce-account.json")}"
        worker_config = "${file("${path.module}/config/worker-env-org")}"
        chef_json = "${file("${path.module}/config/chef-org.json")}"
        ssh_keys = "${file("${path.module}/config/authorized_keys")}"
    }
}

resource "template_file" "cloud_init_com" {
    template = "${file("${path.module}/cloud-init.tpl")}"

    vars {
        account_json = "${file("${path.module}/config/gce-account.json")}"
        worker_config = "${file("${path.module}/config/worker-env-com")}"
        chef_json = "${file("${path.module}/config/chef-com.json")}"
        ssh_keys = "${file("${path.module}/config/authorized_keys")}"
    }
}
