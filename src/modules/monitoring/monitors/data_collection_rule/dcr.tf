resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = var.dcr_name 
  resource_group_name = var.dcr_rg_name
  location            = var.dcr_rg_location

  destinations {
    log_analytics {
      workspace_resource_id = var.law_id
      name                  = "test-destination-log"
    }

    azure_monitor_metrics {
      name = "test-destination-metrics" 
    }
  }

  data_flow {
    streams      = var.data_flow_streams
    destinations = var.data_flow_streams_destinations_metrics
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["test-destination-log"]
  }

  data_sources {
    syslog {
      facility_names = var.data_source_syslog_facility_name
      log_levels     = var.data_source_syslog_log_levels
      name           = "test-datasource-syslog"
    }

    performance_counter {
      streams                       = var.performance_counter_streams
      sampling_frequency_in_seconds = 60 
      name                          = "test-datasource-perfcounter"
      counter_specifiers            = var.counter_specifiers
    }

    windows_event_log {
      streams        = var.windows_event_log_streams
      x_path_queries = var.x_path_queries
      name           = "test-datasource-wineventlog"
    }

    extension {
      streams            = var.extension_streams
      input_data_sources = ["test-datasource-wineventlog"]
      extension_name     = "test-extension-name"
      extension_json = jsonencode({
        a = 1
        b = "hello"
      })
      name = "test-datasource-extension"
    }
  }

  description = "test data collection rule example"
  tags = var.tags
}

# associate to a Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "dcr_association" {
    name                    = "example1-dcra"
    for_each = var.target_resource_id
    target_resource_id      = each.key
    data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
    description             = "test-example-dcr-association"
}