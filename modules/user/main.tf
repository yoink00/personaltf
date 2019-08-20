data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "user" {
    name = "${var.username}"
    path = "/"
    force_destroy = true
}

resource "aws_iam_user_login_profile" "user" {
  user    = "${aws_iam_user.user.name}"
  pgp_key = "keybase:${var.keybase_username}"
}

resource "aws_iam_user_policy_attachment" "user" {
    user = "${aws_iam_user.user.name}"
    policy_arn = "${data.aws_iam_policy.admin.arn}"
}

resource "aws_iam_access_key" "user" {
  user    = "${aws_iam_user.user.name}"
  pgp_key = "keybase:${var.keybase_username}"
}

output "password" {
    value = "${aws_iam_user_login_profile.user.encrypted_password}"
}

output "access_key_id" {
  value = "${aws_iam_access_key.user.id}"
}

output "secret_access_key" {
  value = "${aws_iam_access_key.user.encrypted_secret}"
}
