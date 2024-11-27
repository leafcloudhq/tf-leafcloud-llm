locals {
  # Use the user part of the username if var.prefix is not set or empty.
  prefix = length(var.prefix) > 0 ? var.prefix : split("@", data.openstack_identity_auth_scope_v3.current.user_name)[0]
}

# Get a public ip-address, IPv6 soon available!
resource "openstack_networking_floatingip_v2" "external" {
  count = var.vm_total
  pool  = "external"
}

# Each vm has an additional disk
resource "openstack_blockstorage_volume_v3" "storage" {
  count = var.vm_total
  name  = "${local.prefix}-storage-${count.index}"
  size  = var.vm_additional_storage
}

resource "openstack_compute_instance_v2" "llm" {
  # The amount of instances you want to create
  count = var.vm_total

  name        = "${local.prefix}_llm_${count.index}"
  flavor_name = var.vm_flavor_name
  image_id    = data.openstack_images_image_v2.ubuntu.id
  key_pair    = openstack_compute_keypair_v2.ssh-key.name

  # Security groups (firewall)
  security_groups = [
    openstack_compute_secgroup_v2.llm.name,
    openstack_compute_secgroup_v2.https.name,
  ]

  # Here is where all the magic happens
  user_data = templatefile("templates/user_data.yaml.tpl", {
    additional_disk_name = "vdb"
  })

  network {
    name = openstack_networking_network_v2.private.name

    # Here we get the value of the count and add 10, 
    # so that each instance gets it's own unique IP
    fixed_ip_v4 = cidrhost(var.subnet_cidr, count.index + 10)
  }

  depends_on = [openstack_networking_router_v2.router, openstack_networking_network_v2.private]
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  count       = var.vm_total
  floating_ip = openstack_networking_floatingip_v2.external[count.index].address
  instance_id = openstack_compute_instance_v2.llm[count.index].id
}

resource "openstack_compute_volume_attach_v2" "llm" {
  count       = var.vm_total
  instance_id = openstack_compute_instance_v2.llm[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.storage[count.index].id
}

output "login_info" {
  value = [for ip in openstack_compute_floatingip_associate_v2.fip : "ssh -i id_rsa ubuntu@${ip.floating_ip}"]
}
