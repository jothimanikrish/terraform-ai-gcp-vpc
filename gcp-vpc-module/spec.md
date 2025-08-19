# GCP VPC Terraform Module - Technical Specification

This document serves as the technical specification and reference for the GCP VPC Terraform module. Use this specification as a blueprint when implementing, modifying, or extending the module.

## Module Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          GCP VPC Module                        │
├─────────────────────────────────────────────────────────────────┤
│  versions.tf  │  variables.tf  │  main.tf  │  outputs.tf       │
├─────────────────────────────────────────────────────────────────┤
│                        Core Resources                           │
│  ┌──────────────────┐    ┌─────────────────────────────────────┐│
│  │ google_compute_  │    │     google_compute_subnetwork      ││
│  │    network       │────┤          (for_each loop)           ││
│  │                  │    │                                     ││
│  │ - Network Config │    │ - Subnet Configuration             ││
│  │ - IPv6 Support   │    │ - Secondary IP Ranges              ││
│  │ - BGP Settings   │    │ - Flow Logs                        ││
│  │ - Firewall Policy│    │ - Private Google Access           ││
│  │ - Resource Tags  │    │ - IPv6 Configuration               ││
│  └──────────────────┘    └─────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Core Components Specification

### 1. Provider Configuration (`versions.tf`)

**Purpose**: Define Terraform and provider version constraints
**Dependencies**: None
**Resource Type**: Configuration Block

```hcl
terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.84, < 7"
    }
  }
}
```

**Implementation Rules**:
- Always pin major version boundaries to avoid breaking changes
- Minimum Terraform version should support optional object attributes
- Provider version should include latest stable features

### 2. Variable Definitions (`variables.tf`)

#### 2.1 Required Variables

| Variable | Type | Validation | Purpose |
|----------|------|------------|---------|
| `project_id` | string | None | GCP Project identifier |
| `network_name` | string | RFC1035 compliant | Network resource name |

#### 2.2 Network Configuration Variables

| Variable | Type | Default | Validation Rules | Purpose |
|----------|------|---------|------------------|---------|
| `description` | string | null | None | Network description |
| `routing_mode` | string | "GLOBAL" | ["GLOBAL", "REGIONAL"] | Network routing scope |
| `auto_create_subnetworks` | bool | false | None | Auto-subnet creation flag |
| `mtu` | number | 1460 | 1300-8896 range | Maximum transmission unit |
| `delete_default_routes_on_create` | bool | false | None | Default route cleanup |

#### 2.3 IPv6 Configuration Variables

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `enable_ula_internal_ipv6` | bool | false | Enable internal IPv6 |
| `internal_ipv6_range` | string | null | Custom IPv6 range |

#### 2.4 BGP Configuration Variables

| Variable | Type | Default | Validation | Purpose |
|----------|------|---------|------------|---------|
| `bgp_best_path_selection_mode` | string | null | ["LEGACY", "STANDARD"] | BGP algorithm |
| `bgp_always_compare_med` | bool | null | None | MED comparison setting |
| `bgp_inter_region_cost` | string | null | ["DEFAULT", "ADD_COST_TO_MED"] | Inter-region cost behavior |

#### 2.5 Security Configuration Variables

| Variable | Type | Default | Validation | Purpose |
|----------|------|---------|------------|---------|
| `network_firewall_policy_enforcement_order` | string | "AFTER_CLASSIC_FIREWALL" | ["BEFORE_CLASSIC_FIREWALL", "AFTER_CLASSIC_FIREWALL"] | Firewall policy order |
| `resource_manager_tags` | map(string) | {} | None | Resource tags |

#### 2.6 Subnet Configuration Variable

**Complex Object Structure**:
```hcl
variable "subnets" {
  type = list(object({
    # Required Fields
    subnet_name   = string
    subnet_ip     = string
    subnet_region = string
    
    # Optional Configuration
    description                 = optional(string)
    purpose                    = optional(string)
    role                       = optional(string)
    stack_type                 = optional(string)
    ipv6_access_type          = optional(string)
    private_ip_google_access  = optional(bool, false)
    private_ipv6_google_access = optional(string)
    
    # Secondary IP Ranges
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    
    # Flow Logs Configuration
    log_config = optional(object({
      aggregation_interval = optional(string)
      flow_sampling        = optional(number)
      metadata             = optional(string)
      metadata_fields      = optional(set(string))
      filter_expr          = optional(string)
    }))
  }))
}
```

### 3. Resource Implementation (`main.tf`)

#### 3.1 Primary Network Resource

**Resource Type**: `google_compute_network`
**Resource Name**: `network`
**Dependencies**: None

**Configuration Blocks**:
- Basic network configuration
- IPv6 configuration (conditional)
- BGP configuration (conditional)
- Resource manager tags (dynamic block)
- Lifecycle management

**Dynamic Blocks Implementation**:
```hcl
dynamic "params" {
  for_each = length(var.resource_manager_tags) > 0 ? [1] : []
  content {
    resource_manager_tags = var.resource_manager_tags
  }
}
```

#### 3.2 Subnet Resources

**Resource Type**: `google_compute_subnetwork`
**Resource Name**: `subnetwork`
**Dependencies**: `google_compute_network.network`

**For Each Implementation**:
```hcl
for_each = {
  for subnet in var.subnets :
  "${subnet.subnet_region}/${subnet.subnet_name}" => subnet
}
```

**Dynamic Blocks**:
1. `secondary_ip_range` - For secondary IP ranges
2. `log_config` - For VPC Flow Logs configuration

**Key Implementation Rules**:
- Use `each.value` to reference subnet configuration
- Include explicit `depends_on` for dependency management
- Handle optional configurations with conditional logic

### 4. Output Specifications (`outputs.tf`)

#### 4.1 Network-Level Outputs

| Output | Source Attribute | Purpose |
|--------|------------------|---------|
| `network_name` | `google_compute_network.network.name` | Network identifier |
| `network_id` | `google_compute_network.network.id` | Resource ID |
| `network_self_link` | `google_compute_network.network.self_link` | Resource URI |
| `network_gateway_ipv4` | `google_compute_network.network.gateway_ipv4` | Default gateway |
| `network_numeric_id` | `google_compute_network.network.network_id` | Numeric identifier |

#### 4.2 Subnet-Level Outputs

**Collection Outputs** (Arrays):
- `subnets_names` - List of subnet names
- `subnets_ids` - List of subnet IDs
- `subnets_ips` - List of CIDR ranges
- `subnets_self_links` - List of resource URIs
- `subnets_regions` - List of regions
- `subnets_private_access` - List of private access flags

**Detailed Output** (Map):
```hcl
output "subnets" {
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
```

## Implementation Guidelines

### 5.1 Resource Naming Convention

- **Network Resource**: Use descriptive names with environment/purpose prefix
- **Subnet Resources**: Include region and purpose in name
- **Variables**: Use snake_case following Terraform conventions
- **Outputs**: Descriptive names indicating data type and scope

### 5.2 Configuration Validation Rules

**Network Level**:
- MTU must be between 1300-8896
- Routing mode must be GLOBAL or REGIONAL
- BGP settings require specific combinations

**Subnet Level**:
- CIDR ranges must be valid RFC1918 ranges
- Region must be valid GCP region
- Secondary ranges must not overlap with primary

### 5.3 Dependencies and Relationships

```
Project (Required)
├── VPC Network (1)
    ├── Subnets (0..n)
    │   ├── Secondary Ranges (0..n)
    │   └── Flow Log Config (0..1)
    ├── BGP Configuration (0..1)
    ├── IPv6 Configuration (0..1)
    └── Resource Tags (0..n)
```

### 5.4 State Management

**Resource Creation Order**:
1. VPC Network
2. Subnets (parallel creation)

**Resource Destruction Order**:
1. Subnets
2. VPC Network

**Lifecycle Rules**:
- Network: `create_before_destroy = true`
- Subnets: Explicit dependency on network

## Modification Guidelines

### 6.1 Adding New Features

**Network-Level Features**:
1. Add variable to `variables.tf` with appropriate validation
2. Add configuration to network resource in `main.tf`
3. Add corresponding output in `outputs.tf`
4. Update documentation

**Subnet-Level Features**:
1. Add attribute to subnet object in `variables.tf`
2. Reference `each.value.new_attribute` in subnet resource
3. Add to subnet outputs if needed

### 6.2 Version Compatibility

**Provider Updates**:
- Review changelog for breaking changes
- Update version constraints in `versions.tf`
- Test with new provider version
- Update documentation

**Terraform Updates**:
- Verify syntax compatibility
- Update minimum version requirement
- Test state management operations

### 6.3 Security Considerations

**Network Security**:
- Validate CIDR ranges for overlaps
- Implement firewall policy enforcement
- Enable VPC Flow Logs for monitoring

**Access Control**:
- Use private Google access where appropriate
- Implement resource manager tags for governance
- Follow least privilege principles

## Testing Specification

### 7.1 Validation Tests

1. **Syntax Validation**: `terraform validate`
2. **Plan Generation**: `terraform plan` with sample variables
3. **Provider Compatibility**: Test with min/max provider versions
4. **Variable Validation**: Test edge cases and invalid inputs

### 7.2 Integration Tests

1. **Basic VPC Creation**: Single region, single subnet
2. **Multi-Region Setup**: Multiple subnets across regions
3. **Advanced Features**: IPv6, BGP, Flow Logs, Secondary ranges
4. **Resource Dependencies**: Ensure proper creation/destruction order

### 7.3 Performance Considerations

- **Large Scale**: Test with 50+ subnets
- **Parallel Operations**: Verify subnet creation parallelism
- **State Size**: Monitor state file growth with large configurations

## Troubleshooting Guide

### 8.1 Common Issues

**Provider Version Conflicts**:
- Symptom: Unsupported attributes
- Solution: Check provider version compatibility

**CIDR Overlap**:
- Symptom: Resource creation fails
- Solution: Validate IP ranges before applying

**Permission Errors**:
- Symptom: 403 Forbidden errors
- Solution: Verify service account permissions

### 8.2 Debug Information

**Useful Terraform Commands**:
```bash
terraform validate
terraform plan -detailed-exitcode
terraform show -json
terraform state list
```

**GCP CLI Commands**:
```bash
gcloud compute networks list
gcloud compute networks subnets list
```

This specification serves as the authoritative reference for implementing and modifying the GCP VPC Terraform module. Follow these guidelines to ensure consistency, maintainability, and reliability.
