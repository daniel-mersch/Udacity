provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "webserver-network" {
  name                = "webserver-network"
  address_space       = ["10.10.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "webserver-subnet" {
  name                 = "webserver-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.webserver-network.name
  address_prefixes     = ["10.10.10.0/24"]
}

resource "azurerm_network_security_group" "webserver-nsg" {
  name                = "webserver-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "10.10.10.0/24"
  }

  security_rule {
    name                       = "deny-internet"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "10.10.10.0/24"
  }

  security_rule {
    name                       = "allow-internal"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.10.10.0/24"
    destination_address_prefix = "10.10.10.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "webserver-nsg" {
  subnet_id                 = azurerm_subnet.webserver-subnet.id
  network_security_group_id = azurerm_network_security_group.webserver-nsg.id
}

resource "azurerm_public_ip" "webserver-lb-ip" {
  name                = "webserver-lb-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_lb_backend_address_pool" "webserver-backend-pool" {
  loadbalancer_id = azurerm_lb.webserver-lb.id
  name            = "webserver-backend-pool"
}

resource "azurerm_lb" "webserver-lb" {
  name                = "webserver-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "webserver-lb-ip"
    public_ip_address_id = azurerm_public_ip.webserver-lb-ip.id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "webserver-pool" {
  count                   = var.num_vm
  network_interface_id    = azurerm_network_interface.webserver-nic.*.id[count.index]
  ip_configuration_name   = azurerm_network_interface.webserver-nic.*.ip_configuration.0.name[count.index]
  backend_address_pool_id = azurerm_lb_backend_address_pool.webserver-backend-pool.id
}

resource "azurerm_lb_rule" "allow-http" {
  loadbalancer_id                = azurerm_lb.webserver-lb.id
  name                           = "allow-http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "webserver-lb-ip"
  probe_id                       = azurerm_lb_probe.webserver-hc.id
  backend_address_pool_ids        = ["${azurerm_lb_backend_address_pool.webserver-backend-pool.id}"]
}

resource "azurerm_lb_probe" "webserver-hc" {
  loadbalancer_id     = azurerm_lb.webserver-lb.id
  name                = "webserver-hc"
  protocol            = "Http"
  request_path        = "/" 
  port                = 80
}

resource "azurerm_availability_set" "webserver-avs" {
  name                         = "webserver-avs"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

data "azurerm_image" "webserver_image" {
   name                = var.image_name
   resource_group_name = var.image_rg
}

resource "azurerm_network_interface" "webserver-nic" {
  count = var.num_vm

  name                = "webserver-nic-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.webserver-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count = var.num_vm
  
  name                            = "webserver-vm-${count.index}"
  resource_group_name             = var.resource_group_name
  availability_set_id             = azurerm_availability_set.webserver-avs.id
  location                        = var.location
  size                            = var.vm_instance_type

  admin_username                  = "${var.admin-user}"
  admin_password                  = "${var.admin-password}"

  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.webserver-nic[count.index].id,
  ]

  source_image_id = data.azurerm_image.webserver_image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    env = var.env
  }
}