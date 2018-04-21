resource "azurerm_resource_group" "datasync" {
  name     = "ascmc-euw-ds-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "datasync" {
  name                = "ascmc-euw-ds-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.datasync.location}"
  resource_group_name = "${azurerm_resource_group.datasync.name}"
}

resource "azurerm_subnet" "datasync" {
  name                 = "ascmc-euw-ds-subnet"
  resource_group_name  = "${azurerm_resource_group.datasync.name}"
  virtual_network_name = "${azurerm_virtual_network.datasync.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "datasync" {
  name                         = "ascmc-euw-ds-pip"
  location                     = "${azurerm_resource_group.datasync.location}"
  resource_group_name          = "${azurerm_resource_group.datasync.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_network_interface" "datasync" {
  name                = "ascmc-euw-ds-nic01"
  location            = "${azurerm_resource_group.datasync.location}"
  resource_group_name = "${azurerm_resource_group.datasync.name}"

  ip_configuration {
    name                          = "ascmc-euw-ds-nicipcfg01"
    subnet_id                     = "${azurerm_subnet.datasync.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.datasync.id}"
  }
}

resource "azurerm_managed_disk" "datasync" {
  name                 = "ascmc-euw-ds-disk01"
  location             = "${azurerm_resource_group.datasync.location}"
  resource_group_name  = "${azurerm_resource_group.datasync.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "512"
}

resource "azurerm_virtual_machine" "datasync" {
  name                  = "ascmc-euw-ds01"
  location              = "${azurerm_resource_group.datasync.location}"
  resource_group_name   = "${azurerm_resource_group.datasync.name}"
  network_interface_ids = ["${azurerm_network_interface.datasync.id}"]
  vm_size               = "Standard_A4_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "Standard"
    version   = "latest"
  }
  storage_os_disk {
    name              = "ascmc-euw-ds-osdisk01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_data_disk {
    name            = "${azurerm_managed_disk.datasync.name}"
    managed_disk_id = "${azurerm_managed_disk.datasync.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.datasync.disk_size_gb}"
  }
  os_profile {
    computer_name  = "ascmc-euw-ds01"
    admin_username = "datasyncadmin"
    admin_password = "Password1234!"
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
}
