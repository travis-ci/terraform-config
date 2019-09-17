module "gce_workers" {
  source = "../gce_worker"

  aws_com_id           = "${var.aws_com_id}"
  aws_com_secret       = "${var.aws_com_secret}"
  aws_com_trace_bucket = "${var.aws_com_trace_bucket}"
  aws_org_id           = "${var.aws_org_id}"
  aws_org_secret       = "${var.aws_org_secret}"
  aws_org_trace_bucket = "${var.aws_org_trace_bucket}"
  k8s_namespace        = "${var.k8s_default_namespace}"
  project              = "${var.project}"
  region               = "${var.region}"
}
