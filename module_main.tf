##########################################################################
#######    This is not full code, snippet of it
#########################################################################

resource "azurerm_application_gateway" "app_gateway" {
  location            = var.location
  resource_group_name = var.resource_group_name

  name = local.appgtw_name

  sku {
    capacity = var.autoscaling_parameters != null ? null : var.sku_capacity
    name     = var.sku
    tier     = var.sku_tier
  }

  #
  # Autoscaling
  #
  dynamic "autoscale_configuration" {
    for_each = toset(var.autoscaling_parameters != null ? ["fake"] : [])
    content {
      min_capacity = lookup(var.autoscaling_parameters, "min_capacity")
      max_capacity = lookup(var.autoscaling_parameters, "max_capacity", 5)
    }
  }

}

......
.....

  #
  # Backend address pool
  #
  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = lookup(backend_address_pool.value, "name", null)
      fqdns        = lookup(backend_address_pool.value, "fqdns", null)
      ip_addresses = lookup(backend_address_pool.value, "ip_addresses", null)
    }
  }

  #
  # Backend HTTP settings
  #
  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = lookup(backend_http_settings.value, "name", "")
      path                                = lookup(backend_http_settings.value, "path", "")
      probe_name                          = lookup(backend_http_settings.value, "probe_name", "")
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", "ApplicationGatewayAffinity")
      cookie_based_affinity               = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", true)
      host_name                           = lookup(backend_http_settings.value, "host_name", null)
      port                                = lookup(backend_http_settings.value, "port", 443)
      protocol                            = lookup(backend_http_settings.value, "protocol", "Https")
      request_timeout                     = lookup(backend_http_settings.value, "request_timeout", 20)
      trusted_root_certificate_names      = lookup(backend_http_settings.value, "trusted_root_certificate_names", [])
      dynamic "connection_draining" {
        for_each = lookup(backend_http_settings.value, "enable_connection_draining", false) ? [1] : []
        content {
          enabled           = true
          drain_timeout_sec = lookup(backend_http_settings.value, "drain_timeout_sec", 60)
        }
      }
    }
  }

  #
  # HTTP listener
  #
  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = lookup(http_listener.value, "name", null)
      frontend_ip_configuration_name = var.appgw_private ? local.frontend_priv_ip_config_name : local.frontend_ip_config_name
      frontend_port_name             = lookup(http_listener.value, "frontend_port_name", null)
      protocol                       = lookup(http_listener.value, "protocol", "Https")
      ssl_certificate_name           = lookup(http_listener.value, "ssl_certificate_name", null)
      host_name                      = lookup(http_listener.value, "host_name", null)
      host_names                     = lookup(http_listener.value, "host_names", null)
      require_sni                    = lookup(http_listener.value, "require_sni", null)
      firewall_policy_id             = lookup(http_listener.value, "firewall_policy_id", null)
      dynamic "custom_error_configuration" {
        for_each = lookup(http_listener.value, "custom_error_configuration", {})
        content {
          custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
          status_code           = lookup(custom_error_configuration.value, "status_code", null)
        }
      }
    }
  }

  #
  # Custom error configuration
  #
  dynamic "custom_error_configuration" {
    for_each = var.custom_error_configuration
    content {
      custom_error_page_url = lookup(custom_error_configuration.value, "custom_error_page_url", null)
      status_code           = lookup(custom_error_configuration.value, "status_code", null)
    }
  }

  #
  # SSL certificate
  #
  dynamic "ssl_certificate" {
    for_each = var.ssl_certificate_configs
    content {
      name                = lookup(ssl_certificate.value, "name", null)
      data                = lookup(ssl_certificate.value, "data", null)
      password            = lookup(ssl_certificate.value, "password", null)
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
    }
  }

  #
  # Trusted root certificate
  #
  dynamic "trusted_root_certificate" {
    for_each = var.trusted_root_certificate_configs
    content {
      name = lookup(trusted_root_certificate.value, "name", null)
      data = lookup(trusted_root_certificate.value, "data", null) == null ? filebase64(lookup(trusted_root_certificate.value, "filename", null)) : lookup(trusted_root_certificate.value, "data", null)
    }
  }

  #
  # Rewrite rule set
  #
  dynamic "rewrite_rule_set" {
    for_each = var.rewrite_rule_sets
    content {
      name = lookup(rewrite_rule_set.value, "name", null)
      dynamic "rewrite_rule" {
        for_each = lookup(rewrite_rule_set.value, "rewrite_rule", null)
        content {
          name          = lookup(rewrite_rule.value, "name", null)
          rule_sequence = lookup(rewrite_rule.value, "rule_sequence", null)

          dynamic "condition" {
            for_each = lookup(rewrite_rule.value, "conditions", null)
            content {
              ignore_case = lookup(condition.value, "ignore_case", null)
              negate      = lookup(condition.value, "negate", null)
              pattern     = lookup(condition.value, "pattern", null)
              variable    = lookup(condition.value, "variable", null)
            }
          }

          dynamic "response_header_configuration" {
            for_each = lookup(rewrite_rule.value, "response_header_config", null)
            content {
              header_name  = lookup(response_header_configuration.value, "header_name", null)
              header_value = lookup(response_header_configuration.value, "header_value", null)
            }
          }

          dynamic "request_header_configuration" {
            for_each = lookup(rewrite_rule.value, "request_header_config", null)
            content {
              header_name  = lookup(request_header_configuration.value, "header_name", null)
              header_value = lookup(request_header_configuration.value, "header_value", null)
            }
          }

          dynamic "url" {
            for_each = lookup(rewrite_rule.value, "url", null)
            content {
              path         = lookup(url.value, "url_path", null)
              query_string = lookup(url.value, "url_query_string", null)
              reroute      = lookup(url.value, "url_reroute", null)
            }
          }
        }
      }
    }
  }

  #
  # Request routing rule
  #
  #// Basic Rules
  dynamic "request_routing_rule" {
    for_each = var.basic_request_routing_rules
    content {
      name                       = request_routing_rule.value.name
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = request_routing_rule.value.backend_http_settings_name
      rewrite_rule_set_name      = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
    }
  }

  # // Redirect Rules
  dynamic "request_routing_rule" {
    for_each = var.redirect_request_routing_rules
    content {
      name                        = request_routing_rule.value.name
      rule_type                   = "Basic"
      http_listener_name          = request_routing_rule.value.http_listener_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
    }
  }

  # // Path based rules
  dynamic "request_routing_rule" {
    for_each = var.path_based_request_routing_rules
    content {
      name               = request_routing_rule.value.name
      rule_type          = "PathBasedRouting"
      http_listener_name = request_routing_rule.value.http_listener_name
      url_path_map_name  = request_routing_rule.value.url_path_map_name
    }
  }

  #
  # Probe
  #
  dynamic "probe" {
    for_each = var.probe_configs
    content {
      host                                      = lookup(probe.value, "host", null)
      interval                                  = lookup(probe.value, "interval", 30)
      name                                      = lookup(probe.value, "name", null)
      path                                      = lookup(probe.value, "path", "/")
      protocol                                  = lookup(probe.value, "protocol", "Https")
      timeout                                   = lookup(probe.value, "timeout", 30)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", false)
      port                                      = lookup(probe.value, "port", null)
      unhealthy_threshold                       = lookup(probe.value, "unhealthy_threshold", 3)
      match {
        body        = lookup(probe.value, "match_body", "")
        status_code = lookup(probe.value, "match_status_code", ["200-399"])
      }
    }
  }

  #
  # URL path map
  #
  dynamic "url_path_map" {
    for_each = var.url_path_map_configs
    content {
      name                                = lookup(url_path_map.value, "name", null)
      default_backend_address_pool_name   = lookup(url_path_map.value, "default_backend_address_pool_name", null)
      default_redirect_configuration_name = lookup(url_path_map.value, "default_redirect_configuration_name", null)
      default_backend_http_settings_name  = lookup(url_path_map.value, "default_backend_http_settings_name", lookup(url_path_map.value, "default_backend_address_pool_name", null))
      default_rewrite_rule_set_name       = lookup(url_path_map.value, "default_rewrite_rule_set_name", null)
      dynamic "path_rule" {
        for_each = lookup(url_path_map.value, "path_rule")
        content {
          name                       = lookup(path_rule.value, "path_rule_name", null)
          backend_address_pool_name  = lookup(path_rule.value, "backend_address_pool_name", lookup(path_rule.value, "path_rule_name", null))
          backend_http_settings_name = lookup(path_rule.value, "backend_http_settings_name", lookup(path_rule.value, "path_rule_name", null))
          paths                      = flatten([lookup(path_rule.value, "paths", null)])
          rewrite_rule_set_name      = lookup(path_rule.value, "rewrite_rule_set_name", null)
        }
      }
    }
  }

  #
  # Redirect configuration
  #
  dynamic "redirect_configuration" {
    for_each = var.redirect_configurations
    content {
      name                 = lookup(redirect_configuration.value, "name", null)
      redirect_type        = lookup(redirect_configuration.value, "redirect_type", "Permanent")
      target_listener_name = lookup(redirect_configuration.value, "target_listener_name", null)
      target_url           = lookup(redirect_configuration.value, "target_url", null)
      include_path         = lookup(redirect_configuration.value, "include_path", "true")
      include_query_string = lookup(redirect_configuration.value, "include_query_string", "true")
    }
  }

  #
  # Identity
  #

  dynamic "identity" {
    for_each = var.user_assigned_identity_id ? ["fake"] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.gw.id]
    }
  }
  ....
  ....
}
