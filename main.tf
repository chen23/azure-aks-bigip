module "vnet" {
  source = "./vnet"
  #variables for resource creation
  location = "${var.location}"
  rg_name = "${var.prefix}-rg"
  network_cidr = "${var.network_cidr}"
  mgmt_subnet_prefix = "${var.mgmt_subnet_prefix}"
  external_subnet_prefix = "${var.external_subnet_prefix}"
  internal_subnet_prefix = "${var.internal_subnet_prefix}"
  # Configure the Azure Provider
  subscription_id = "${var.subscription_id}"
  tenant_id	    = "${var.tenant_id}"
  client_id	    = "${var.client_id}"
  client_secret   = "${var.client_secret}"
}

module "aks" {
  source = "./aks"
  #variables for resource creation
  int_subnet_id = "${module.vnet.internal_subnet_id}"
  location = "${module.vnet.rg_location}"
  rg_name = "${module.vnet.rg_name}"
  service_cidr = "172.16.0.0/16"
  dns_service_ip = "172.16.0.10"
  docker_bridge_cidr = "172.17.0.1/16"
  # Configure the Azure Provider
  subscription_id = "${var.subscription_id}"
  tenant_id	    = "${var.tenant_id}"
  client_id	    = "${var.client_id}"
  client_secret   = "${var.client_secret}"
}

module "bigip" {
  source = "./bigip"
  #variables for basic bigip setup
  location = "${module.vnet.rg_location}"
  rg_name = "${module.vnet.rg_name}"
  prefix = "${var.prefix}-bigipvm"
  #variables for networking
  mgmt_subnet_id = "${module.vnet.mgmt_subnet_id}"
  internal_subnet_id = "${module.vnet.internal_subnet_id}"
  external_subnet_id = "${module.vnet.external_subnet_id}"
  mgmt_gw    = "${cidrhost(module.vnet.mgmt_subnet_prefix, 1)}"
  ext_gw     = "${cidrhost(module.vnet.external_subnet_prefix, 1)}"
  int_gw     = "${cidrhost(module.vnet.internal_subnet_prefix, 1)}"
  f5vm01mgmt = "${cidrhost(module.vnet.mgmt_subnet_prefix, 4)}"
  f5vm02mgmt = "${cidrhost(module.vnet.mgmt_subnet_prefix, 5)}"
  f5vm01ext  = "${cidrhost(module.vnet.external_subnet_prefix, 10)}"
  f5vm01ext_sec = "${cidrhost(module.vnet.external_subnet_prefix, 100)}"
  f5vm02ext  = "${cidrhost(module.vnet.external_subnet_prefix, 11)}"
  f5vm02ext_sec = "${cidrhost(module.vnet.external_subnet_prefix, 101)}"
  f5vm01int  = "${cidrhost(module.vnet.internal_subnet_prefix, 10)}"
  f5vm02int  = "${cidrhost(module.vnet.internal_subnet_prefix, 11)}"
  #variables for onboard.tpl
  uname = "${var.uname}"
  upassword = "${var.upassword}"
  #variables for ServicePrincipal
  SP={
    "subscription_id":"${var.subscription_id}",
    "client_id":"${var.client_id}",
    "tenant_id":"${var.tenant_id}",
    "client_secret":"${var.client_secret}"
  }
}

module "cis" {
  source = "./cis"
  #variables for kubernetes provider
  kube_host              = "${module.aks.kube_host}"
  kube_username          = "${module.aks.kube_username}"
  kube_password          = "${module.aks.kube_password}"
  client_certificate     = "${module.aks.client_certificate}"
  client_key             = "${module.aks.client_key}"
  cluster_ca_certificate = "${module.aks.cluster_ca_certificate}"

  #variables for CIS configuration
  f5vm01int  = "${cidrhost(module.vnet.internal_subnet_prefix, 10)}"
  f5vm02int  = "${cidrhost(module.vnet.internal_subnet_prefix, 11)}"
  upassword = "${var.upassword}"
}

module "azureVoteApp" {
  source = "./azureVoteApp"
  #variables for kubernetes provider
  kube_host              = "${module.aks.kube_host}"
  kube_username          = "${module.aks.kube_username}"
  kube_password          = "${module.aks.kube_password}"
  client_certificate     = "${module.aks.client_certificate}"
  client_key             = "${module.aks.client_key}"
  cluster_ca_certificate = "${module.aks.cluster_ca_certificate}"

  #variables for k8s app
  f5vm01ext_sec = "${cidrhost(module.vnet.external_subnet_prefix, 100)}"
  f5vm02ext_sec = "${cidrhost(module.vnet.external_subnet_prefix, 101)}"
}
