workspace = {
    lseg-test = {
        rg = {
            name = "Test_RG"
            location = "francecentral"
        }
        vnet = {
            main_vnet = {
                name = "main_vnet"
                adress_space = "10.108.0.0/16"
            },
        }

        subnet = {
            web_subnet = {
                name = "web_subnet"
                vnet_name = "main_vnet"
                adress_prefixes = "10.108.1.0/24"
            },
            app_subnet = {
                name = "appsubnet"
                vnet_name = "main_vnet"
                adress_prefixes = "10.108.2.0/24"
            },
            db_subnet = {
                name = "db_subnet"
                vnet_name = "main_vnet"
                adress_prefixes = "10.108.3.0/24"
            },
        }

        vmnic = {
            web1_nic = {
                name = "Web1_VMNic"
                ipconfig_name = "ipconfig1"
                subnet_id = "web_subnet"
                ipconfig_private_ip_address_allocation = "Dynamic"
            },
            web2_nic = {
                name = "Web2_VMNic"
                ipconfig_name = "ipconfig1"
                subnet_id = "web_subnet"
                ipconfig_private_ip_address_allocation = "Dynamic"
            },
            app1_nic = {
                name = "App1_VMNic"
                ipconfig_name = "ipconfig1"
                subnet_id = "app_subnet"
                ipconfig_private_ip_address_allocation = "Dynamic"
            },
            app2_nic = {
                name = "App2_VMNic"
                ipconfig_name = "ipconfig1"
                subnet_id = "app_subnet"
                ipconfig_private_ip_address_allocation = "Dynamic"
            },
            db1_nic = {
                name = "DB1_VMNic"
                ipconfig_name = "ipconfig1"
                subnet_id = "db_subnet"
                ipconfig_private_ip_address_allocation = "Dynamic"
            },
        }

        avset = {
            web_avset = {
                name = "Web_Set"
            },
            app_avset = {
                name = "App_Set"
            },
        }

        compute = {
            web1 = {
                name       = "Web1_VM"
                vm_size    = "Standard_D4s_v5"
                vmnic_name = "web1_nic"
                avset_id   = "web_avset"
                os = {
                  publisher = "Canonical"
                  offer     = "0001-com-ubuntu-server-focal"
                  sku       = "20_04-lts-gen2"
                  version   = "latest"
                },
                osdisk = {
                  name              = "Web1_VM_osdisk"
                  caching           = "ReadWrite"
                  create_option     = "FromImage"
                  managed_disk_type = "StandardSSD_LRS"
                  disk_size_gb      = 256
                },
                osprofile = {
                  admin_username = "testadmin"

                },
              },
              web2 = {
                name       = "Web2_VM"
                vm_size    = "Standard_D4s_v5"
                vmnic_name = "web2_nic"
                avset_id   = "web_avset"
                os = {
                  publisher = "Canonical"
                  offer     = "0001-com-ubuntu-server-focal"
                  sku       = "20_04-lts-gen2"
                  version   = "latest"
                },
                osdisk = {
                  name              = "Web2_VM_osdisk"
                  caching           = "ReadWrite"
                  create_option     = "FromImage"
                  managed_disk_type = "StandardSSD_LRS"
                  disk_size_gb      = 256
                },
                osprofile = {
                  admin_username = "testadmin"

                },
              },
              app1 = {
                name       = "App1_VM"
                vm_size    = "Standard_D2s_v5"
                vmnic_name = "app1_nic"
                avset_id   = "app_avset"
                os = {
                  publisher = "Canonical"
                  offer     = "0001-com-ubuntu-server-focal"
                  sku       = "20_04-lts-gen2"
                  version   = "latest"
                },
                osdisk = {
                  name              = "App1_VM_osdisk"
                  caching           = "ReadWrite"
                  create_option     = "FromImage"
                  managed_disk_type = "StandardSSD_LRS"
                  disk_size_gb      = 256
                },
                osprofile = {
                  admin_username = "testadmin"

                },
              },
              app2 = {
                name       = "App2_VM"
                vm_size    = "Standard_D8s_v5"
                vmnic_name = "app2_nic"
                avset_id   = "app_avset"
                os = {
                  publisher = "Canonical"
                  offer     = "0001-com-ubuntu-server-focal"
                  sku       = "20_04-lts-gen2"
                  version   = "latest"
                },
                osdisk = {
                  name              = "App2_VM_osdisk"
                  caching           = "ReadWrite"
                  create_option     = "FromImage"
                  managed_disk_type = "StandardSSD_LRS"
                  disk_size_gb      = 256
                },
                osprofile = {
                  admin_username = "testadmin"

                },
              },
              db1 = {
                name       = "DB1_VM"
                vm_size    = "Standard_D8s_v5"
                vmnic_name = "db1_nic"
                # avset_id   = "db_avset"
                os = {
                  publisher = "Canonical"
                  offer     = "0001-com-ubuntu-server-focal"
                  sku       = "20_04-lts-gen2"
                  version   = "latest"
                },
                osdisk = {
                  name              = "DB1_VM_osdisk"
                  caching           = "ReadWrite"
                  create_option     = "FromImage"
                  managed_disk_type = "Premium_LRS"
                  disk_size_gb      = 512
                },
                osprofile = {
                  admin_username = "testadmin"

                },
              },
        }

        int_load_balancer = {
            web_lb = {
                name = "Web_LB"
                ipconfig = "Web_LB_ipconfig"
                subnet_id = "web_subnet"
            },
        }

        backend_pool = {
            web_bp = {
                name = "Web_backend_pool"
                lb_id = "web_lb"
            },
        }

        backend_resources = [
            {
                vmnic_ref = "web1_nic"
                backend_pool_ref = "web_bp"
            }
        ]

        lb_rule = [
            {
                name = "Web_Rule_443"
                probe = "Web_health_probe_443"
                lb_id = "web_lb"
                backend_pool_ref = "web_bp"
                port = 443
                load_distribution = "SourceIP"
            },
            {
                name = "Web_Rule_80"
                probe = "Web_health_probe_80"
                lb_id = "web_lb"
                backend_pool_ref = "web_bp"
                port = 80
                backport = 8080
                load_distribution = "SourceIP"
            },

        ]

    }
}