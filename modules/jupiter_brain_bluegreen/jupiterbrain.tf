variable "ssh_ip_address" {}
variable "ssh_user" {}
variable "version" {}
variable "config_path" {}
variable "env" {}
variable "index" {}
variable "port_suffix" {}

resource "null_resource" "jupiter_brain" {
  triggers {
    version = "${var.version}"
    config_signature = "${sha256(file(var.config_path))}"
    name = "${var.env}-${var.index}"
    port_suffix = "${var.port_suffix}"
  }

  connection {
    host = "${var.ssh_ip_address}"
    user = "${var.ssh_user}"
    agent = true
  }

  provisioner "file" {
    source = "${var.config_path}"
    destination = "/tmp/etc-default-jupiter-brain-${var.env}"
  }

  provisioner "file" {
    content = <<EOF
export JUPITER_BRAIN_ADDR='127.0.0.1:908${var.port_suffix}'
export JUPITER_BRAIN_LIBRATO_SOURCE='jupiter-brain-${var.env}-${var.index}-blue'
EOF
    destination = "/tmp/etc-default-jupiter-brain-${var.env}-blue"
  }

  provisioner "file" {
    content = <<EOF
export JUPITER_BRAIN_ADDR='127.0.0.1:1008${var.port_suffix}'
export JUPITER_BRAIN_LIBRATO_SOURCE='jupiter-brain-${var.env}-${var.index}-green'
EOF
    destination = "/tmp/etc-default-jupiter-brain-${var.env}-green"
  }

  provisioner "file" {
    content = <<EOF
description "Jupiter Brain (jupiter-brain-${var.env})"

start on (started networking)
stop on runlevel [!2345]

instance $INST

setuid jupiter-brain
setgid nogroup

respawn
respawn limit 10 90

script
  JUPITER_BRAIN_RUN_DIR=/var/tmp/run/jupiter-brain

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  if [ -f /etc/default/$UPSTART_JOB-$INST ] ; then
    . /etc/default/$UPSTART_JOB-$INST
  fi

  cp -v /usr/local/bin/jb-server-${var.env} $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
  chmod u+x $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
  exec $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
end script

post-stop script
  JUPITER_BRAIN_RUN_DIR=/var/tmp/run/jupiter-brain

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  rm -f $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
end script

# vim:filetype=upstart
EOF
    destination = "/tmp/init-jupiter-brain-${var.env}.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "getent passwd jupiter-brain >/dev/null || sudo useradd -r -s /usr/bin/nologin jupiter-brain",
      "sudo mv /tmp/etc-default-jupiter-brain-${var.env} /etc/default/jupiter-brain-${var.env}",
      "sudo mv /tmp/etc-default-jupiter-brain-${var.env}-blue /etc/default/jupiter-brain-${var.env}-blue",
      "sudo mv /tmp/etc-default-jupiter-brain-${var.env}-green /etc/default/jupiter-brain-${var.env}-green",
      "sudo chown jupiter-brain /etc/default/jupiter-brain-${var.env} /etc/default/jupiter-brain-${var.env}-blue /etc/default/jupiter-brain-${var.env}-green",
      "sudo chmod 0600 /etc/default/jupiter-brain-${var.env} /etc/default/jupiter-brain-${var.env}-blue /etc/default/jupiter-brain-${var.env}-green",
      "sudo mkdir -p /var/tmp/run/jupiter-brain",
      "sudo chown jupiter-brain /var/tmp/run/jupiter-brain",
      "sudo mv /tmp/init-jupiter-brain-${var.env}.conf /etc/init/jupiter-brain-${var.env}.conf",
      "sudo wget -O /usr/local/bin/jb-server-${var.env} https://s3.amazonaws.com/jupiter-brain-artifacts/travis-ci/jupiter-brain/${var.version}/build/linux/amd64/jb-server",
      "sudo chmod 755 /usr/local/bin/jb-server-${var.env}",
    ]
  }
}
