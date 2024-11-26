resource "tls_private_key" "ssh_key" {
  algorithm   = "ED25519" # Specify the key algorithm (RSA, ECDSA, etc.)
  rsa_bits    = 4096      # Specify the key size (bits) for RSA keys
  ecdsa_curve = "P256"    # For ECDSA keys, specify the curve type (P256, P384, P521, etc.)
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  file_permission = "0600"
  filename        = "${path.module}/id_rsa"
}

resource "local_file" "ssh_key_pub" {
  content         = tls_private_key.ssh_key.public_key_openssh
  file_permission = "0640"
  filename        = "${path.module}/id_rsa.pub"
}

resource "openstack_compute_keypair_v2" "ssh-key" {
  name       = "${local.prefix}-sshkey"
  public_key = tls_private_key.ssh_key.public_key_openssh
}
