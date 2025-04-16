###Local Variables###
locals {
    env = var.workspace[terraform.workspace]
    tags = {
        project = "Test Project"
        owner   = "Andrei"        
    }

}

###Backend###
terraform{
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>3.90.0"
        }
      
    }
    backend "remote" {
        hostname    = "app.terraform.io"
        organization = "value"
        workspaces {
          name = "lseg-test"
        }
      
    }
}

###Providers###
provider "azurerm" {
  features {}
}


###Resource Group###
resource "azurerm_resource_group" "rg" {
  name     = local.env["rg"].name
  location = local.env["rg"].location
  tags = local.tags
}

##Network###
resource "azurerm_virtual_network" "vnet" {
  for_each = local.env["vnet"]

  name                = each.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [each.address_space]
}

resource "azurerm_subnet" "subnet" {
  for_each = local.env["subnet"]
  name                 = each.name
  virtual_network_name = each.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [each.address_prefixes]
}

resource "azurerm_network_interface" "vmnic" {
  for_each = local.env["vmnic"]

  name                          = each.value.name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name

  ip_configuration {
    name = each.value["ipconfig_name"]
    subnet_id = azurerm_subnet.subnet["${each.value.subnet_id}"].id
    private_ip_address_allocation = each.value["ipconfig_private_ip_address_allocation"]
  }

  tags = local.tags
}
###Availability Set###
resource "azurerm_availability_set" "avset" {
  for_each = local.env["avset"]

  name                = each.value["name"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

###Virtual Machines###
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "tls_private_key" {
  value     = tls_private_key.sshkey.private_key_pem
  sensitive = true
}
resource "azurerm_linux_virtual_machine" "compute" {
  for_each = local.env["compute"]

  name                  = each.value["name"]
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = ["${azurerm_network_interface.vmnic["${each.value.vmnic_name}"].id}"]
  size                  = each.value["vm_size"]
  availability_set_id   = each.value.avset_id == "" ? null : azurerm_availability_set.avset["${each.value.avset_id}"].id


  source_image_reference {
    publisher = each.value["os"]["publisher"]
    offer     = each.value["os"]["offer"]
    sku       = each.value["os"]["sku"]
    version   = each.value["os"]["version"]
  }
  os_disk {
    name                 = each.value["osdisk"]["name"]
    caching              = each.value["osdisk"]["caching"]
    storage_account_type = each.value["osdisk"]["managed_disk_type"]
    disk_size_gb         = each.value["osdisk"]["disk_size_gb"]
  }

  admin_username = each.value["osprofile"]["admin_username"]
  admin_password = each.value["osprofile"]["admin_password"]


  disable_password_authentication = true 
  admin_ssh_key {
    username = "testadmin"

    public_key = tls_private_key.sshkey.public_key_openssh

  }

  tags = local.tags
}

###Load Balancing###
resource "azurerm_lb" "int_load_balancer" {
  for_each = local.env["int_load_balancer"]

  name                = each.value["name"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = each.value["ip_config"]
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    subnet_id = azurerm_subnet.subnet["${each.value.subnet_id}"].id
  }

  tags = local.tags
}

resource "azurerm_lb_rule" "lb_rule" {
  for_each = contains(keys(local.env), "lb_rule") ? { for lbr in local.env["lb_rule"] : lbr.name => lbr } : {}

  loadbalancer_id                = azurerm_lb.int_load_balancer["${each.value.lb_id}"].id
  name                           = each.key
  protocol                       = "Tcp"
  frontend_port                  = each.value["port"]
  backend_port                   = try(each.value["backport"],each.value["port"]) #tries to use backport if defined, else uses the frontend port
  frontend_ip_configuration_name = azurerm_lb.int_load_balancer["${each.value.lb_id}"].frontend_ip_configuration.name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool["${each.value.backend_pool_ref}"].id]
  probe_id                       = azurerm_lb_probe.health_probe["${each.value.probe}"].id
  load_distribution              = each.value["load_distribution"]
}
resource "azurerm_lb_probe" "health_probe" {
  for_each = contains(keys(local.env), "lb_rule") ? { for hp in local.env["lb_rule"] : hp.probe => hp } : {}

  loadbalancer_id = azurerm_lb.int_load_balancer["${each.value.lb_id}"].id
  name            = each.key
  port            = try(each.value["backport"],each.value["port"])
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  for_each = local.env["backend_pool"]

  loadbalancer_id = azurerm_lb.int_load_balancer["${each.value.lb_id}"].id
  name            = each.value["name"]
}

resource "azurerm_network_interface_backend_address_pool_association" "backend_resources" {
  for_each = contains(keys(local.env), "backend_resources") ? { for bkr in local.env["backend_resources"] : bkr.vmnic_ref => bkr } : {}

  ip_configuration_name   = "ipconfig1"
  network_interface_id    = azurerm_network_interface.vmnic["${each.value.vmnic_ref}"].id
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool["${each.value.backend_pool_ref}"].id
}
