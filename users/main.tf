module "stuartwallace" {
  source = "../modules/user"
  username = "stuart.wallace"
  keybase_username = "yoink00"
}

output "stuartwallace_password" {
  value = "${module.stuartwallace.password}"
}

output "stuartwallace_access_key_id" {
  value = "${module.stuartwallace.access_key_id}"
}

output "stuartwallace_secret_access_key" {
  value = "${module.stuartwallace.secret_access_key}"
}

