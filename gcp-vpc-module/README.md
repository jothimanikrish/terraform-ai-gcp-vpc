# GCP VPC Terraform Module

This Terraform module creates a Google Cloud Platform (GCP) VPC network with customizable subnets, based on the latest GCP provider documentation.

## Features

- **VPC Network Creation**: Creates a custom VPC network with comprehensive configuration options
- **Flexible Subnets**: Support for multiple subnets across different regions with advanced features
- **IPv6 Support**: Optional ULA internal IPv6 configuration
- **BGP Configuration**: Advanced BGP settings for global routing
- **VPC Flow Logs**: Optional flow logging configuration for network monitoring
- **Secondary IP Ranges**: Support for secondary IP ranges on subnets
- **Firewall Policy Integration**: Network-level firewall policy enforcement
- **Resource Manager Tags**: Tag support for compliance and organization

## Requirements

- Terraform >= 1.3
- Google Cloud Provider >= 4.84, < 7.0
- Appropriate GCP permissions to create VPC networks and subnets

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "./gcp-vpc-module"

  project_id   = "my-gcp-project"
  network_name = "my-vpc-network"
  
  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "us-central1"
    },
    {
      subnet_name   = "subnet-02"
      subnet_ip     = "10.10.20.0/24"
      subnet_region = "us-west1"
    }
  ]
}
```

### Advanced Usage

```hcl
module "vpc" {
  source = "./gcp-vpc-module"

  project_id                = "my-gcp-project"
  network_name              = "production-vpc"
  description               = "Production VPC network"
  routing_mode              = "GLOBAL"
  mtu                       = 1500
  enable_ula_internal_ipv6  = true
  
  # BGP Configuration
  bgp_best_path_selection_mode = "STANDARD"
  bgp_always_compare_med      = true
  bgp_inter_region_cost       = "ADD_COST_TO_MED"
  
  subnets = [
    {
      subnet_name              = "web-subnet"
      subnet_ip                = "10.0.1.0/24"
      subnet_region            = "us-central1"
      description              = "Subnet for web servers"
      private_ip_google_access = true
      
      secondary_ranges = [
        {
          range_name    = "web-services"
          ip_cidr_range = "192.168.1.0/24"
        }
      ]
      
      log_config = {
        aggregation_interval = "INTERVAL_10_MIN"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    },
    {
      subnet_name              = "db-subnet"
      subnet_ip                = "10.0.2.0/24"
      subnet_region            = "us-west1"
      description              = "Subnet for databases"
      private_ip_google_access = true
      
      log_config = {
        aggregation_interval = "INTERVAL_5_MIN"
        flow_sampling        = 1.0
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  ]
  
  resource_manager_tags = {
    "tagKeys/1234567890" = "tagValues/0987654321"
  }
}
```

### IPv6 Configuration Example

```hcl
module "vpc" {
  source = "./gcp-vpc-module"

  project_id               = "my-gcp-project"
  network_name             = "ipv6-vpc"
  enable_ula_internal_ipv6 = true
  
  subnets = [
    {
      subnet_name      = "ipv6-subnet"
      subnet_ip        = "10.0.1.0/24"
      subnet_region    = "us-central1"
      stack_type       = "IPV4_IPV6"
      ipv6_access_type = "INTERNAL"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The ID of the project where this VPC will be created | `string` | n/a | yes |
| network_name | The name of the network being created | `string` | n/a | yes |
| description | An optional description of this resource | `string` | `null` | no |
| routing_mode | The network routing mode (default 'GLOBAL') | `string` | `"GLOBAL"` | no |
| auto_create_subnetworks | When set to true, the network is created in 'auto subnet mode' | `bool` | `false` | no |
| mtu | The network MTU. Recommended values: 1460 (default), 1500 (Internet default), or 8896 (for Jumbo packets) | `number` | `1460` | no |
| delete_default_routes_on_create | If set, ensure that all default routes are deleted | `bool` | `false` | no |
| enable_ula_internal_ipv6 | Enable ULA internal ipv6 on this network | `bool` | `false` | no |
| internal_ipv6_range | When enabling ULA internal ipv6, optionally specify the /48 range | `string` | `null` | no |
| network_firewall_policy_enforcement_order | Set the order that Firewall Rules and Firewall Policies are evaluated | `string` | `"AFTER_CLASSIC_FIREWALL"` | no |
| bgp_best_path_selection_mode | The BGP best selection algorithm to be employed | `string` | `null` | no |
| bgp_always_compare_med | Enables/disables the comparison of MED across routes with different Neighbor ASNs | `bool` | `null` | no |
| bgp_inter_region_cost | Choice of the behavior of inter-regional cost and MED in the BPS algorithm | `string` | `null` | no |
| subnets | The list of subnets being created | `list(object)` | `[]` | no |
| resource_manager_tags | Resource manager tags to be bound to the network | `map(string)` | `{}` | no |

### Subnet Object Structure

Each subnet in the `subnets` list supports the following attributes:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| subnet_name | The name of the subnet | `string` | n/a | yes |
| subnet_ip | The IP CIDR range for the subnet | `string` | n/a | yes |
| subnet_region | The region where the subnet will be created | `string` | n/a | yes |
| description | An optional description of the subnet | `string` | `null` | no |
| purpose | The purpose of the resource | `string` | `null` | no |
| role | The role of subnetwork | `string` | `null` | no |
| stack_type | The stack type for this subnet to identify whether the IPv6 feature is enabled | `string` | `null` | no |
| ipv6_access_type | The access type of IPv6 address this subnet holds | `string` | `null` | no |
| private_ip_google_access | When enabled, VMs in this subnetwork can access Google APIs | `bool` | `false` | no |
| private_ipv6_google_access | The private IPv6 google access type for the VMs in this subnet | `string` | `null` | no |
| secondary_ranges | An array of configurations for secondary IP ranges | `list(object)` | `[]` | no |
| log_config | VPC flow logging configuration | `object` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_name | The name of the VPC network |
| network_id | The ID of the VPC network |
| network_self_link | The URI of the VPC network |
| network_gateway_ipv4 | The gateway address for default routing out of the network |
| network_numeric_id | The unique identifier for the resource |
| network_routing_mode | The network-wide routing mode |
| network_mtu | The network MTU |
| subnets | A map of subnet name => subnet info |
| subnets_names | The names of the subnets being created |
| subnets_ids | The IDs of the subnets being created |
| subnets_ips | The IPs and CIDRs of the subnets being created |
| subnets_self_links | The self-links of subnets being created |
| subnets_regions | The region where the subnets reside |
| subnets_private_access | Whether the subnets have access to Google API's without external IP |
| subnets_flow_logs | Whether the subnets have VPC flow logs enabled |
| subnets_secondary_ranges | The secondary ranges associated with these subnets |
| network_internal_ipv6_range | The internal IPv6 range assigned to this network |
| subnets_ipv6_cidr_ranges | The IPv6 CIDR ranges of the subnets |

## Examples

### Multi-Region Setup with Flow Logs

```hcl
module "multi_region_vpc" {
  source = "./gcp-vpc-module"

  project_id   = "my-project-id"
  network_name = "multi-region-vpc"
  routing_mode = "GLOBAL"
  mtu          = 1500

  subnets = [
    {
      subnet_name              = "us-central1-subnet"
      subnet_ip                = "10.0.1.0/24"
      subnet_region            = "us-central1"
      private_ip_google_access = true
      log_config = {
        aggregation_interval = "INTERVAL_5_MIN"
        flow_sampling        = 0.8
        metadata             = "INCLUDE_ALL_METADATA"
      }
    },
    {
      subnet_name              = "europe-west1-subnet"
      subnet_ip                = "10.0.2.0/24"
      subnet_region            = "europe-west1"
      private_ip_google_access = true
      log_config = {
        aggregation_interval = "INTERVAL_5_MIN"
        flow_sampling        = 0.8
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}
```

### GKE-Ready VPC with Secondary Ranges

```hcl
module "gke_vpc" {
  source = "./gcp-vpc-module"

  project_id   = "my-project-id"
  network_name = "gke-vpc"

  subnets = [
    {
      subnet_name              = "gke-subnet"
      subnet_ip                = "10.0.0.0/22"
      subnet_region            = "us-central1"
      private_ip_google_access = true
      
      secondary_ranges = [
        {
          range_name    = "gke-pods"
          ip_cidr_range = "10.4.0.0/14"
        },
        {
          range_name    = "gke-services"
          ip_cidr_range = "10.8.0.0/20"
        }
      ]
    }
  ]
}
```

## Best Practices

1. **Use Private Google Access**: Enable `private_ip_google_access` for subnets that need to access Google APIs without external IPs
2. **Enable Flow Logs**: Use VPC Flow Logs for network monitoring and security analysis
3. **Plan IP Ranges**: Carefully plan your IP CIDR ranges to avoid conflicts with other networks
4. **Use Secondary Ranges**: For GKE clusters, configure secondary ranges for pods and services
5. **Regional Consideration**: Place subnets in regions close to your users and applications
6. **MTU Settings**: Consider increasing MTU to 8896 for internal-only networks to improve performance
7. **BGP Configuration**: Use STANDARD BGP best path selection mode for better routing control

## License

This module is released under the MIT License.
