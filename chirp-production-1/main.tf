variable "chirp_artifacts_bucket_name" {
  default = "travis-ci-chirp-artifacts"
}

variable "chirp_com_production_repo" {
  default = "travis-infrastructure/chirp-com-production"
}

variable "chirp_org_production_repo" {
  default = "travis-repos/chirp-org-production"
}

variable "chirp_repo" {
  default = "travis-ci/chirp"
}

variable "env" {
  default = "production"
}

variable "index" {
  default = 1
}

variable "region" {
  default = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "travis-terraform-state"
    key            = "terraform-config/chirp-production-1.tfstate"
    region         = "us-east-1"
    encrypt        = "true"
    dynamodb_table = "travis-terraform-state"
  }
}

provider "aws" {}

resource "aws_s3_bucket" "chirp_artifacts" {
  bucket = "${var.chirp_artifacts_bucket_name}"
}

resource "aws_iam_user" "chirp" {
  name = "chirp-${var.env}-${var.index}"
}

resource "aws_iam_access_key" "chirp" {
  user       = "${aws_iam_user.chirp.name}"
  depends_on = ["aws_iam_user.chirp"]
}

resource "aws_iam_user_policy" "chirp_actions" {
  name = "chirp_actions_${var.env}_${var.index}"
  user = "${aws_iam_user.chirp.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.chirp_artifacts.arn}",
        "${aws_s3_bucket.chirp_artifacts.arn}/*"
      ]
    }
  ]
}
EOF

  depends_on = ["aws_iam_user.chirp"]
}

resource "local_file" "chirp_key" {
  content = <<EOF
{
  "id": ${jsonencode(aws_iam_access_key.chirp.id)},
  "secret": ${jsonencode(aws_iam_access_key.chirp.secret)}
}
EOF

  filename = "${path.module}/../tmp/chirp-key.json"
}

resource "null_resource" "chirp_key_vars" {
  triggers {
    chirp_iam_access_key = "${sha256("${aws_iam_access_key.chirp.id}")}"
    chirp_iam_secret_key = "${sha256("${aws_iam_access_key.chirp.secret}")}"
  }

  provisioner "local-exec" {
    command = <<EOF
exec ${path.module}/../bin/chirp-assign-aws-creds \
  "${aws_iam_access_key.chirp.id}" \
  "${aws_iam_access_key.chirp.secret}" \
  "${var.chirp_repo}" \
  "${var.chirp_org_production_repo}" \
  "${var.chirp_com_production_repo}"
EOF
  }
}
