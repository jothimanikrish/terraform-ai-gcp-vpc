variable "project_id" {
  description = "The ID of the project where this VPC will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the network being created"
  type        = string
}

variable "description" {
  description = "An optional description of this resource"
  type        = string
  default     = null
}

variable "routing_mode" {
  description = "The network routing mode (default 'GLOBAL')"
  type        = string
  default     = "GLOBAL"
  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.routing_mode)
    error_message = "routing_mode must be GLOBAL or REGIONAL."
  }
}

variable "auto_create_subnetworks" {
  description = "When set to true, the network is created in 'auto subnet mode' and it will create a subnet for each region automatically across the 10.128.0.0/9 address range. When set to false, the network is created in 'custom subnet mode' so the user can explicitly connect subnetwork resources."
  type        = bool
  default     = false
}

variable "mtu" {
  description = "The network MTU (If set to 0, meaning MTU is unset - defaults to '1460'). Recommended values: 1460 (default), 1500 (Internet default), or 8896 (for Jumbo packets). Given that this module creates a custom network, we can set it higher."
  type        = number
  default     = 1460
  validation {
    condition     = var.mtu >= 1300 && var.mtu <= 8896
    error_message = "mtu must be between 1300 and 8896."
  }
}

variable "delete_default_routes_on_create" {
  description = "If set, ensure that all routes within the network specified whose names begin with 'default-route' and with a next hop of 'default-internet-gateway' are deleted"
  type        = bool
  default     = false
}

variable "enable_ula_internal_ipv6" {
  description = "Enable ULA internal ipv6 on this network. Enabling this feature will assign a /48 from google defined ULA prefix fd20::/20."
  type        = bool
  default     = false
}

variable "internal_ipv6_range" {
  description = "When enabling ula internal ipv6, caller optionally can specify the /48 range they want from the google defined ULA prefix fd20::/20. The input must be a valid /48 ULA IPv6 address and must be within the fd20::/20. Operation will fail if the speficied /48 is already in used by another resource. If the field is not speficied, then a /48 range will be randomly allocated from fd20::/20 and returned via this field."
  type        = string
  default     = null
}

variable "network_firewall_policy_enforcement_order" {
  description = "Set the order that Firewall Rules and Firewall Policies are evaluated. Default value is AFTER_CLASSIC_FIREWALL. Possible values are: BEFORE_CLASSIC_FIREWALL, AFTER_CLASSIC_FIREWALL."
  type        = string
  default     = "AFTER_CLASSIC_FIREWALL"
  validation {
    condition     = contains(["BEFORE_CLASSIC_FIREWALL", "AFTER_CLASSIC_FIREWALL"], var.network_firewall_policy_enforcement_order)
    error_message = "network_firewall_policy_enforcement_order must be BEFORE_CLASSIC_FIREWALL or AFTER_CLASSIC_FIREWALL."
  }
}

variable "bgp_best_path_selection_mode" {
  description = "The BGP best selection algorithm to be employed. MODE can be LEGACY or STANDARD."
  type        = string
  default     = null
  validation {
    condition     = var.bgp_best_path_selection_mode == null || contains(["LEGACY", "STANDARD"], var.bgp_best_path_selection_mode)
    error_message = "bgp_best_path_selection_mode must be LEGACY or STANDARD."
  }
}

variable "bgp_always_compare_med" {
  description = "Enables/disables the comparison of MED across routes with different Neighbor ASNs. This value can only be set if the --bgp-best-path-selection-mode is STANDARD"
  type        = bool
  default     = null
}

variable "bgp_inter_region_cost" {
  description = "Choice of the behavior of inter-regional cost and MED in the BPS algorithm. Possible values are: DEFAULT, ADD_COST_TO_MED."
  type        = string
  default     = null
  validation {
    condition     = var.bgp_inter_region_cost == null || contains(["DEFAULT", "ADD_COST_TO_MED"], var.bgp_inter_region_cost)
    error_message = "bgp_inter_region_cost must be DEFAULT or ADD_COST_TO_MED."
  }
}

variable "subnets" {
  description = "The list of subnets being created"
  type = list(object({
    subnet_name                      = string
    subnet_ip                        = string
    subnet_region                    = string
    description                      = optional(string)
    purpose                          = optional(string)
    role                             = optional(string)
    stack_type                       = optional(string)
    ipv6_access_type                = optional(string)
    private_ip_google_access        = optional(bool, false)
    private_ipv6_google_access      = optional(string)
    secondary_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    log_config = optional(object({
      aggregation_interval = optional(string)
      flow_sampling        = optional(number)
      metadata             = optional(string)
      metadata_fields      = optional(set(string))
      filter_expr          = optional(string)
    }))
  }))
  default = []
}

variable "resource_manager_tags" {
  description = "Resource manager tags to be bound to the network. Tag keys and values have the same definition as resource manager tags. Keys must be in the format tagKeys/{tag_key_id}, and values are in the format tagValues/456."
  type        = map(string)
  default     = {}
}
