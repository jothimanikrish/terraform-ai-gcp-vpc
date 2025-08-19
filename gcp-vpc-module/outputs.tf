# VPC Network outputs
output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.network.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.network.id
}

output "network_self_link" {
  description = "The URI of the VPC network"
  value       = google_compute_network.network.self_link
}

output "network_gateway_ipv4" {
  description = "The gateway address for default routing out of the network"
  value       = google_compute_network.network.gateway_ipv4
}

output "network_numeric_id" {
  description = "The unique identifier for the resource. This identifier is defined by the server"
  value       = google_compute_network.network.network_id
}

output "network_routing_mode" {
  description = "The network-wide routing mode"
  value       = google_compute_network.network.routing_mode
}

output "network_mtu" {
  description = "The network MTU"
  value       = google_compute_network.network.mtu
}

# Subnets outputs
output "subnets" {
  description = "A map of subnet name => subnet info"
  value = {
    for subnet in google_compute_subnetwork.subnetwork : subnet.name => {
      name               = subnet.name
      id                 = subnet.id
      self_link          = subnet.self_link
      ip_cidr_range      = subnet.ip_cidr_range
      gateway_address    = subnet.gateway_address
      region             = subnet.region
      creation_timestamp = subnet.creation_timestamp
      purpose            = subnet.purpose
      role               = subnet.role
      stack_type         = subnet.stack_type
      ipv6_cidr_range    = subnet.ipv6_cidr_range
      internal_ipv6_prefix = subnet.internal_ipv6_prefix
      secondary_ip_ranges = subnet.secondary_ip_range
    }
  }
}

output "subnets_names" {
  description = "The names of the subnets being created"
  value       = [for subnet in google_compute_subnetwork.subnetwork : subnet.name]
}

output "subnets_ids" {
  description = "The IDs of the subnets being created"
  value       = [for subnet in google_compute_subnetwork.subnetwork : subnet.id]
}

output "subnets_ips" {
  description = "The IPs and CIDRs of the subnets being created"
  value       = [for subnet in google_compute_subnetwork.subnetwork : subnet.ip_cidr_range]
}

output "subnets_self_links" {
  description = "The self-links of subnets being created"
  value       = [for subnet in google_compute_subnetwork.subnetwork : subnet.self_link]
}

output "subnets_regions" {
  description = "The region where the subnets reside"
  value       = [for subnet in google_compute_subnetwork.subnetwork : subnet.region]
}

output "subnets_private_access" {
  description = "Whether the subnets have access to Google API's without external IP"
  value       = [for subnet in google_compute_subnetwork.subnetwork : subnet.private_ip_google_access]
}

output "subnets_flow_logs" {
  description = "Whether the subnets have VPC flow logs enabled"
  value = {
    for subnet in google_compute_subnetwork.subnetwork : subnet.name => length(subnet.log_config) > 0
  }
}

output "subnets_secondary_ranges" {
  description = "The secondary ranges associated with these subnets"
  value = {
    for subnet in google_compute_subnetwork.subnetwork : subnet.name => [
      for secondary_range in subnet.secondary_ip_range : {
        range_name    = secondary_range.range_name
        ip_cidr_range = secondary_range.ip_cidr_range
      }
    ]
  }
}

# IPv6 outputs (when applicable)
output "network_internal_ipv6_range" {
  description = "The internal IPv6 range assigned to this network"
  value       = google_compute_network.network.internal_ipv6_range
}

output "subnets_ipv6_cidr_ranges" {
  description = "The IPv6 CIDR ranges of the subnets"
  value = {
    for subnet in google_compute_subnetwork.subnetwork : subnet.name => subnet.ipv6_cidr_range
  }
}
