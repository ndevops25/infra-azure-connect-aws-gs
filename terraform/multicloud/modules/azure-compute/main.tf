# Network Interface para VM
resource "azurerm_network_interface" "main" {
  name                = "nic-${var.vm_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.main[0].id : null
  }

  tags = var.tags
}

# Public IP (opcional, para acesso SSH)
resource "azurerm_public_ip" "main" {
  count = var.create_public_ip ? 1 : 0
  
  name                = "pip-${var.vm_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Basic"  # Mais barato que Standard
  
  tags = var.tags
}

# Network Security Group básico
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.vm_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SSH básico
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ICMP para testes
  security_rule {
    name                       = "ICMP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.allowed_source_cidr
    destination_address_prefix = "*"
  }

  # HTTP básico (se necessário)
  dynamic "security_rule" {
    for_each = var.allow_http ? [1] : []
    content {
      name                       = "HTTP"
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# Associar NSG ao NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine Linux básica
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s"
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key_path != null ? var.ssh_public_key_path : file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Mais barato que Premium
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Script básico de inicialização
  custom_data = base64encode(templatefile("${path.module}/scripts/init.sh", {
    admin_username = var.admin_username
  }))

  tags = var.tags
}