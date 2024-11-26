resource "openstack_compute_secgroup_v2" "ssh" {
  name        = "${local.prefix}_ssh"
  description = "Allow SSH"
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = var.vm_cidr_whitelist
  }
}

resource "openstack_compute_secgroup_v2" "https" {
  name        = "${local.prefix}_https"
  description = "Allow HTTPS"
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = var.vm_cidr_whitelist
  }
}
