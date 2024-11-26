provider "openstack" {
  auth_url    = "https://create.leaf.cloud:5000"
  region      = "europe-nl"
  use_octavia = true
}
