# Create the VPC network
resource "google_compute_network" "network" {
  name    = var.network_name
  project = var.project_id

  # Basic network configuration
  description                                   = var.description
  auto_create_subnetworks                       = var.auto_create_subnetworks
  routing_mode                                  = var.routing_mode
  mtu                                          = var.mtu
  delete_default_routes_on_create              = var.delete_default_routes_on_create
  network_firewall_policy_enforcement_order    = var.network_firewall_policy_enforcement_order

  # IPv6 configuration
  enable_ula_internal_ipv6 = var.enable_ula_internal_ipv6
  internal_ipv6_range     = var.internal_ipv6_range

  # BGP configuration
  bgp_best_path_selection_mode = var.bgp_best_path_selection_mode
  bgp_always_compare_med      = var.bgp_always_compare_med
  bgp_inter_region_cost       = var.bgp_inter_region_cost

  # Resource manager tags
  dynamic "params" {
    for_each = length(var.resource_manager_tags) > 0 ? [1] : []
    content {
      resource_manager_tags = var.resource_manager_tags
    }
  }

  # Ensure network is created before subnets
  lifecycle {
    create_before_destroy = true
  }
}

# Create subnets
resource "google_compute_subnetwork" "subnetwork" {
  for_each = {
    for subnet in var.subnets :
    "${subnet.subnet_region}/${subnet.subnet_name}" => subnet
  }

  name    = each.value.subnet_name
  project = var.project_id
  region  = each.value.subnet_region
  network = google_compute_network.network.id

  # IP configuration
  ip_cidr_range = each.value.subnet_ip
  description   = each.value.description

  # Advanced configuration
  purpose                          = each.value.purpose
  role                            = each.value.role
  stack_type                      = each.value.stack_type
  ipv6_access_type               = each.value.ipv6_access_type
  private_ip_google_access       = each.value.private_ip_google_access
  private_ipv6_google_access     = each.value.private_ipv6_google_access
  # Note: allow_subnet_cidr_routes_overlap is only available with google-beta provider

  # Secondary IP ranges
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  # VPC Flow Logs configuration
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
      metadata_fields      = log_config.value.metadata_fields
      filter_expr          = log_config.value.filter_expr
    }
  }

  depends_on = [google_compute_network.network]
}
