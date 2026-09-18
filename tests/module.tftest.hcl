mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      name     = "rg-vm"
      location = "eastus2"
    }
  }

  mock_data "azurerm_virtual_network" {
    defaults = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-vm/providers/Microsoft.Network/virtualNetworks/vnet-vm"
      name                = "vnet-vm"
      resource_group_name = "rg-vm"
    }
  }

  mock_data "azurerm_subnet" {
    defaults = {
      id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-vm/providers/Microsoft.Network/virtualNetworks/vnet-vm/subnets/snet-vm"
      name             = "snet-vm"
      address_prefixes = ["10.42.1.0/24"]
    }
  }

  mock_data "azurerm_network_security_group" {
    defaults = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-vm/providers/Microsoft.Network/networkSecurityGroups/nsg-vm"
      name                = "nsg-vm"
      resource_group_name = "rg-vm"
    }
  }

  mock_data "azurerm_storage_account" {
    defaults = {
      name                  = "vmtestdiag"
      primary_blob_endpoint = "https://vmtestdiag.blob.core.windows.net/"
    }
  }
}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "generated-vm-name"
    }
  }
}

variables {
  location                             = "eastus2"
  deploy_environment                   = "test"
  workload_name                        = "vm"
  org_name                             = "rox"
  existing_resource_group_name         = "rg-vm"
  existing_virtual_network_name        = "vnet-vm"
  existing_subnet_name                 = "snet-vm"
  existing_network_security_group_name = "nsg-vm"
  admin_password                       = "P@ssword123456789"
  disable_password_authentication      = false
  admin_ssh_key_data                   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCtestkey terraform-test"
}

run "custom_name_override_precedence" {
  command = plan

  variables {
    os_type                  = "linux"
    custom_linux_vm_name     = "custom-linux-vm"
    custom_nic_name          = "custom-nic"
    custom_public_ip_name    = "custom-pip"
    custom_ipconfig_name     = "custom-ipcfg"
    os_disk_custom_name      = "custom-data-disk"
    enable_public_ip_address = true
    data_disks = [
      {
        name                 = "data01"
        storage_account_type = "StandardSSD_LRS"
        disk_size_gb         = 64
      }
    ]
  }

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm[0].name == "custom-linux-vm"
    error_message = "custom_linux_vm_name must override the generated Linux VM name."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].name == "custom-nic"
    error_message = "custom_nic_name must override the generated NIC name."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].ip_configuration[0].name == "ipconfig-customipcfg1"
    error_message = "custom_ipconfig_name must override the generated IP configuration name before sanitizing."
  }

  assert {
    condition     = azurerm_public_ip.pip[0].name == "custom-pip-01"
    error_message = "custom_public_ip_name must override the generated public IP prefix."
  }

  assert {
    condition     = azurerm_managed_disk.data_disk["data01"].name == "custom-data-disk-0"
    error_message = "os_disk_custom_name must override the generated data disk name prefix."
  }
}

run "empty_custom_names_fall_through_to_generated_names" {
  command = plan

  variables {
    os_type                  = "linux"
    custom_linux_vm_name     = ""
    custom_nic_name          = ""
    custom_public_ip_name    = ""
    custom_ipconfig_name     = ""
    os_disk_custom_name      = ""
    enable_public_ip_address = true
    data_disks = [
      {
        name                 = "data01"
        storage_account_type = "StandardSSD_LRS"
        disk_size_gb         = 32
      }
    ]
  }

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm[0].name == "generated-vm-name"
    error_message = "An empty custom_linux_vm_name must fall through to the generated VM name."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].name == "generated-vm-name"
    error_message = "An empty custom_nic_name must fall through to the generated NIC name."
  }

  assert {
    condition     = azurerm_public_ip.pip[0].name == "generated-vm-name-01"
    error_message = "An empty custom_public_ip_name must fall through to the generated public IP name."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].ip_configuration[0].name == "ipconfig-vmnicipconfig1"
    error_message = "An empty custom_ipconfig_name must fall through to the default IP configuration name."
  }

  assert {
    condition     = azurerm_managed_disk.data_disk["data01"].name == "generated-vm-name-0"
    error_message = "An empty os_disk_custom_name must fall through to the generated disk name."
  }
}

run "disabled_feature_conditionals_omit_optional_resources" {
  command = plan

  variables {
    os_type                          = "linux"
    enable_public_ip_address         = false
    enable_vm_availability_set       = false
    enable_proximity_placement_group = false
    deploy_log_analytics_agent       = false
    aad_login_enabled                = false
    backup_policy_id                 = null
    maintenance_configuration_ids    = []
    data_disks                       = []
    additional_nic_configuration     = null
  }

  assert {
    condition     = length(azurerm_public_ip.pip) == 0
    error_message = "Disabling public IPs must omit public IP resources."
  }

  assert {
    condition     = length(azurerm_availability_set.aset) == 0 && length(azurerm_proximity_placement_group.appgrp) == 0
    error_message = "Disabling availability set and proximity placement group must omit those resources."
  }

  assert {
    condition     = length(azurerm_virtual_machine_extension.linux_aad_ssh_login) == 0 && length(azurerm_role_assignment.rbac_user_login) == 0 && length(azurerm_role_assignment.rbac_admin_login) == 0
    error_message = "Disabling AAD login must omit login extensions and role assignments."
  }

  assert {
    condition     = length(azurerm_backup_protected_vm.backup) == 0 && length(azurerm_maintenance_assignment_virtual_machine.maintenance_configurations) == 0
    error_message = "Absent backup and maintenance inputs must omit backup and maintenance resources."
  }

  assert {
    condition     = length(azurerm_managed_disk.data_disk) == 0 && length(azurerm_network_interface.secondary_nic) == 0
    error_message = "Absent data disk and secondary NIC inputs must omit those resources."
  }
}

run "enabled_feature_conditionals_create_optional_resources" {
  command = plan

  variables {
    os_type                                    = "linux"
    enable_public_ip_address                   = true
    enable_vm_availability_set                 = true
    enable_proximity_placement_group           = true
    deploy_log_analytics_agent                 = true
    log_analytics_customer_id                  = "00000000-0000-0000-0000-000000000000"
    log_analytics_workspace_primary_shared_key = "workspace-key"
    aad_login_enabled                          = true
    aad_login_user_objects_ids                 = ["11111111-1111-1111-1111-111111111111"]
    aad_login_admin_objects_ids                = ["22222222-2222-2222-2222-222222222222"]
    backup_policy_id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-backup/providers/Microsoft.RecoveryServices/vaults/vault-vm/backupPolicies/default"
    maintenance_configuration_ids              = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-vm/providers/Microsoft.Maintenance/maintenanceConfigurations/patch-window"]
    additional_nic_configuration = {
      subnet_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-vm/providers/Microsoft.Network/virtualNetworks/vnet-vm/subnets/snet-secondary"
      private_ip_address = "10.42.2.10"
    }
    data_disks = [
      {
        name                 = "data01"
        storage_account_type = "StandardSSD_LRS"
        disk_size_gb         = 64
      }
    ]
  }

  assert {
    condition     = length(azurerm_public_ip.pip) == 1
    error_message = "Enabling public IPs must create one public IP per VM instance."
  }

  assert {
    condition     = length(azurerm_availability_set.aset) == 1 && length(azurerm_proximity_placement_group.appgrp) == 1
    error_message = "Enabling availability set and proximity placement group must create those resources."
  }

  assert {
    condition     = length(azurerm_virtual_machine_extension.linux_aad_ssh_login) == 1 && length(azurerm_role_assignment.rbac_user_login) == 1 && length(azurerm_role_assignment.rbac_admin_login) == 1
    error_message = "Enabling Linux AAD login must create extension and role assignment resources."
  }

  assert {
    condition     = length(azurerm_backup_protected_vm.backup) == 1 && length(azurerm_maintenance_assignment_virtual_machine.maintenance_configurations) == 1
    error_message = "Backup policy and maintenance IDs must create backup and maintenance resources."
  }

  assert {
    condition     = length(azurerm_managed_disk.data_disk) == 1 && length(azurerm_network_interface.secondary_nic) == 1
    error_message = "Data disks and secondary NIC configuration must create those resources."
  }
}

run "tags_and_location_are_preserved" {
  command = plan

  variables {
    os_type                  = "linux"
    enable_public_ip_address = true
    add_tags = {
      cost  = "shared-cost"
      owner = "platform"
    }
    nic_add_tags = {
      cost = "network-cost"
    }
    public_ip_add_tags = {
      owner = "network"
    }
  }

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm[0].location == "eastus2"
    error_message = "The VM location must pass through from the selected resource group."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].location == "eastus2" && azurerm_public_ip.pip[0].location == "eastus2"
    error_message = "NIC and public IP location must pass through from the selected resource group."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].tags["ResourceName"] == "generated-vm-name"
    error_message = "NIC tags must include the module's ResourceName tag."
  }

  assert {
    condition     = azurerm_network_interface.nic[0].tags["owner"] == "platform" && azurerm_network_interface.nic[0].tags["cost"] == "network-cost"
    error_message = "nic_add_tags must merge after and override shared add_tags."
  }

  assert {
    condition     = azurerm_public_ip.pip[0].tags["cost"] == "shared-cost" && azurerm_public_ip.pip[0].tags["owner"] == "network"
    error_message = "public_ip_add_tags must merge after and override shared add_tags."
  }
}

run "linux_marketplace_and_custom_image_branching" {
  command = plan

  variables {
    os_type = "linux"
    custom_image = {
      publisher = "CustomPublisher"
      offer     = "custom-offer"
      sku       = "custom-sku"
      version   = "1.2.3"
    }
    custom_image_plan = {
      name      = "plan-name"
      product   = "plan-product"
      publisher = "plan-publisher"
    }
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.linux_vm) == 1 && length(azurerm_windows_virtual_machine.win_vm) == 0
    error_message = "Linux os_type must create Linux VMs and omit Windows VMs."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm[0].source_image_reference[0].publisher == "CustomPublisher" && azurerm_linux_virtual_machine.linux_vm[0].source_image_reference[0].sku == "custom-sku"
    error_message = "custom_image must drive the Linux source_image_reference block."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm[0].plan[0].name == "plan-name" && azurerm_linux_virtual_machine.linux_vm[0].plan[0].product == "plan-product"
    error_message = "custom_image_plan must create the Linux plan block."
  }
}

run "source_image_id_omits_marketplace_reference" {
  command = plan

  variables {
    os_type         = "linux"
    source_image_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-images/providers/Microsoft.Compute/images/custom-linux"
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.linux_vm[0].source_image_reference) == 0
    error_message = "source_image_id must suppress the marketplace source_image_reference block."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.linux_vm[0].source_image_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-images/providers/Microsoft.Compute/images/custom-linux"
    error_message = "source_image_id must pass through to the Linux VM resource."
  }
}

run "windows_branching_and_update_setting" {
  command = plan

  variables {
    os_type                  = "windows"
    custom_windows_vm_name   = "custom-win-vm"
    custom_computer_name     = "customhost"
    enable_automatic_updates = true
  }

  assert {
    condition     = length(azurerm_windows_virtual_machine.win_vm) == 1 && length(azurerm_linux_virtual_machine.linux_vm) == 0
    error_message = "Windows os_type must create Windows VMs and omit Linux VMs."
  }

  assert {
    condition     = azurerm_windows_virtual_machine.win_vm[0].name == "custom-win-vm" && azurerm_windows_virtual_machine.win_vm[0].computer_name == "customhost"
    error_message = "Windows VM and computer name custom overrides must take precedence."
  }

  assert {
    condition     = azurerm_windows_virtual_machine.win_vm[0].automatic_updates_enabled == true
    error_message = "enable_automatic_updates must flow into automatic_updates_enabled for azurerm 5.x."
  }

  assert {
    condition     = azurerm_windows_virtual_machine.win_vm[0].source_image_reference[0].publisher == "MicrosoftWindowsServer"
    error_message = "Windows marketplace image settings must come from windows_distribution_list by default."
  }
}
