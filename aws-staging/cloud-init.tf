resource "template_file" "cloud_init_org" {
    template = "${file("${path.module}/cloud-init.tpl")}"

    vars {
        queue = "docker"
        env = "${var.env}"
        site = "org"
        worker_yml = "${file("${path.module}/config/aws-workers-org-${var.env}.yml")}"
        docker_rsa = "${file("${path.module}/config/docker_rsa.key")}"
        papertrail_site = "${file("${path.module}/config/papertrail-site-org")}"
        docker_count = "1"
        ssh_keys = "${file("${path.module}/config/authorized_keys")}"
    }
}

resource "template_file" "cloud_init_com" {
    template = "${file("${path.module}/cloud-init.tpl")}"

    vars {
        queue = "docker"
        env = "${var.env}"
        site = "com"
        worker_yml = "${file("${path.module}/config/aws-workers-com-${var.env}.yml")}"
        docker_rsa = "${file("${path.module}/config/docker_rsa.key")}"
        papertrail_site = "${file("${path.module}/config/papertrail-site-com")}"
        docker_count = "1"
        ssh_keys = "${file("${path.module}/config/authorized_keys")}"
    }
}
