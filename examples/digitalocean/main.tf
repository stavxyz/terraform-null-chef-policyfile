resource "tls_private_key" "default" {
  algorithm   = "RSA"
}

resource "digitalocean_ssh_key" "default" {
  name       = "default"
  public_key = tls_private_key.default.public_key_openssh
}

resource "digitalocean_droplet" "chef-node" {
  image  = "ubuntu-18-04-x64"
  name   = "chef-server"
  region = "nyc2"
  size   = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "local_file" "policyfile" {
  filename = "${path.cwd}/Policyfile.rb"
  content  = <<EOT
    name 'chef_client'
    default_source :supermarket
    cookbook 'chef-client', '~> 11.5.0', :supermarket
    run_list 'chef-client::default', 'managed_chef_server::managed_organization'
  EOT
}

module "provision" {
  source     = "../.."
  host       = digitalocean_droplet.chef-node.ipv4_address
  policyfile = local_file.policyfile.filename
  ssh_key    = tls_private_key.default.private_key_pem
}
