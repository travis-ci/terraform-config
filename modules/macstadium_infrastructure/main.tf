variable "github_users" {
  default = ""
}

data "template_file" "user_data_txt" {
  template = <<EOF
export MSG="i'm a template file!"
EOF
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/iso/user-data.txt")}"

  vars {
    user_data_txt    = "${data.template_file.user_data_txt.rendered}"
    github_users_env = "export GITHUB_USERS='${var.github_users}'"
    here             = "${path.module}"

    #hostname_tmpl     = "___INSTANCE_ID___-${var.env}-${var.index}-worker-${var.site}-${var.worker_queue}.travisci.net"
  }
}

/*
data "template_cloudinit_config" "cloud_config" {
  part {
    filename     = "cloud-config"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
  }

  part {
    filename     = "cloud-init"
    content_type = "text/x-shellscript"
    content      = "${file("${path.module}/cloud-init.bash")}"
  }
}
*/

