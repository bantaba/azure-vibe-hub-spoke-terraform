# https://www.expertnetworkconsultant.com/infrastructure-as-code/how-to-create-azure-standard-load-balancer-with-backend-pools-in-terraform/
# https://github.com/Azure/terraform-azurerm-loadbalancer
resource "azurerm_lb" "standard-lb" {
  name = var.lb_name
  location = var.lb_location
  resource_group_name = var.lb_resource_group_name
  sku = "Standard"
  sku_tier = "Regional"
  
  frontend_ip_configuration {       // check if private/public IP var.env == "test" ? var.private_ip : null
    name = var.lb_fe_ip_config_name
    subnet_id = var.subnet_id
    private_ip_address_allocation = "Dynamic"  
    # var.private_ip_address_allocation == "Dynamic" ? var.private_ip_address_allocation : null
    
  }


  # dynamic "frontend_ip_configuration" {
  #   for_each = [ "value" ]
  #   content {
  #     name = 
  #     subnet_id = 
  #     private_ip_address_allocation = 
  #     public_ip_address_id = 
  #     zones = [ "" ]
  #   }
  # }
  
  # frontend_ip_configuration {
  #   name = var.lb_fe_ip_config_name
  #   public_ip_address_id = var.loadBalancerPIPAddress_id
  #   zones = [ "Zone-redundant" ]
  # }

  tags = var.tags
}


resource "azurerm_lb_backend_address_pool" "beap" {
  name = var.lb_be_address_pool_name
  loadbalancer_id = azurerm_lb.standard-lb.id

  depends_on = [ azurerm_lb.standard-lb ]
}

# resource "azurerm_lb_backend_address_pool_address" "beapa" {
#   name = var.loadBalancerBackendAddressPoolAddressName
#   backend_address_pool_id = var.lb_backend_address_pool_id
#   backend_address_ip_configuration_id = var.lb_backend_address_ip_configuration_id
# }

resource "azurerm_lb_probe" "lb-probe" {
  name = var.probe_name
  loadbalancer_id = azurerm_lb.standard-lb.id
  port = var.lb_probe_port
  protocol = var.protocol

  # interval_in_seconds = 5
  # number_of_probes = 
  # probe_threshold =  
  depends_on = [ azurerm_lb.standard-lb ]
}

resource "azurerm_lb_rule" "lb-rule" {
  name = var.lb_rule_name
  idle_timeout_in_minutes        = 4
  loadbalancer_id = azurerm_lb.standard-lb.id
  protocol = var.protocol
  frontend_port = var.lb_rule_fe_port
  backend_port = var.lb_rule_be_port
  frontend_ip_configuration_name = azurerm_lb.standard-lb.frontend_ip_configuration[0].name #var.lb_fe_config_name
  probe_id = azurerm_lb_probe.lb-probe.id
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.beap.id ]
  disable_outbound_snat          = true
  enable_floating_ip             = false
  enable_tcp_reset               = false
  load_distribution              = "Default"
  timeouts {}

  depends_on = [
    azurerm_lb_backend_address_pool.beap
  ]
}

# If VMss no pool_association is required
resource "azurerm_network_interface_backend_address_pool_association" "test-backend_address_assoc" {
  # lifecycle {
    
  #   postcondition {
  #     # pretest condition
  #     condition = var.nic_ip_config_name != null
  #     error_message = "value"
  #   }
  # }
  backend_address_pool_id = azurerm_lb_backend_address_pool.beap.id
  ip_configuration_name = var.nic_ip_config_name 
  network_interface_id = each.value != null ? each.value : null 

}

/*
can use
  https://github.com/HighwayofLife/terraform-azurerm-load-balancer/blob/master/main.tf
*/

