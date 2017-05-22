variable "ssh_host" {}
variable "ssh_user" {}

variable "script" {
  default = "sudo apt-get install -y ntp nmap"
}

variable "host_id" {}

resource "null_resource" "macstadium_host_utilities_install" {
  triggers {
    script_signature = "${sha256(var.script)}"
    host_id          = "${var.host_id}"
  }

  connection {
    host  = "${var.ssh_host}"
    user  = "${var.ssh_user}"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "${var.script}",
    ]
  }
}
