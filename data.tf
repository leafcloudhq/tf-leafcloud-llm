data "openstack_identity_auth_scope_v3" "current" {
  name = "current"
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu-24.04"
  most_recent = true
}
