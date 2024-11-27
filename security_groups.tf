resource "openstack_compute_secgroup_v2" "llm" {
  name        = "${local.prefix}_llm"
  description = "Allow Services"

  # SSH
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = var.vm_cidr_whitelist
  }

  # ICMP Ping
  rule {
    from_port   = 8
    to_port     = 0
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
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
