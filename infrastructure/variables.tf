variable "service_name" {
  type        = string
  description = "Name of the service."
  default     = "dua_requester"
}

variable "otel_exporter_otlp_endpoint" {
  type        = string
  description = "OpenTelemetry OTLP endpoint"
  default     = "api.honeycomb.io:443"
}

variable "honeycomb_api_key" {
  type        = string
  description = "Honeycomb API key for authentication"
  sensitive   = true
}
