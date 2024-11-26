data "openstack_networking_network_v2" "external" {
  name = "external"
}

data "openstack_networking_subnet_v2" "external4" {
  name = "external4"
}

resource "openstack_networking_network_v2" "private" {
  name           = "${local.prefix}_private"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "private" {
  name       = "${local.prefix}_private"
  cidr       = var.subnet_cidr
  ip_version = 4
  network_id = openstack_networking_network_v2.private.id
}

resource "openstack_networking_router_v2" "router" {
  name                = "${local.prefix}_router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "router" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private.id
}
