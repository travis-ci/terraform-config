variable "iam_user_name" {}
variable "s3_bucket_name" {}

resource "aws_iam_user" "s3_user" {
  name = "${var.iam_user_name}"
}

resource "aws_iam_access_key" "s3_user" {
  user       = "${aws_iam_user.s3_user.name}"
  depends_on = ["aws_iam_user.s3_user"]
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "${aws_iam_user.s3_user.name}_policy"
  user = "${aws_iam_user.s3_user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${var.s3_bucket_name}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": ["arn:aws:s3:::${var.s3_bucket_name}/*"]
    }
  ]
}
EOF

  depends_on = ["aws_iam_user.s3_user"]
}

output "bucket" {
  value = "${var.s3_bucket_name}"
}

output "id" {
  value = "${aws_iam_access_key.s3_user.id}"
}

output "secret" {
  value = "${aws_iam_access_key.s3_user.secret}"
}
