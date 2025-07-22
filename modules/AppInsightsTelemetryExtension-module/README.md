# AppInsightsTelemetryExtension Module

Enterprise-grade Application Insights telemetry extension for M365 Copilot plugins with advanced monitoring, analytics, and best practices implementation.

## 🚀 Features

### Core Capabilities

- **Custom Event Tracking**: Structured telemetry events with rich metadata
- **Performance Monitoring**: Operation timing, thresholds, and insights
- **User Behavior Analytics**: Session analysis and engagement scoring
- **Real-time Dashboards**: Dynamic telemetry visualization and alerting
- **Secure Configuration**: Azure Key Vault integration for secrets
- **Enterprise Logging**: Structured logging with correlation IDs

### Best Practices Implementation

- ✅ Structured event data with standardized schemas
- ✅ Performance threshold monitoring and alerting
- ✅ User privacy and data compliance considerations
- ✅ Scalable telemetry aggregation patterns
- ✅ Error tracking and diagnostic correlation
- ✅ Resource-efficient data collection strategies

## 📋 Prerequisites

- Azure subscription with Application Insights resource
- Azure Key Vault for secure configuration storage
- Python 3.8+ runtime environment
- Azure Functions Core Tools (for deployment)

## 🛠️ Installation

1. **Install Dependencies**

   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Azure Resources**

   ```bash
   # Set up Application Insights
   az monitor app-insights component create \
     --app MyApp \
     --location eastus \
     --resource-group MyResourceGroup

   # Configure Key Vault
   az keyvault create \
     --name kvf46zzw7hdeclarat \
     --resource-group MyResourceGroup \
     --location eastus
   ```

3. **Deploy to Azure Functions**

   ```bash
   func azure functionapp publish MyTelemetryApp
   ```

## 🔧 Configuration

### Environment Variables

```bash
# Azure Key Vault Configuration
AZURE_KEY_VAULT_URL=https://kvf46zzw7hdeclarat.vault.azure.net/

# Application Insights Configuration  
APPINSIGHTS_INSTRUMENTATIONKEY=your-instrumentation-key
APPINSIGHTS_CONNECTION_STRING=your-connection-string

# Plugin Configuration
PLUGIN_VERSION=1.0.0
ENVIRONMENT=production
```

### Key Vault Secrets

Store sensitive configuration in Azure Key Vault:

- `appinsights-connection-string`: Application Insights connection string
- `telemetry-api-key`: API key for telemetry services
- `dashboard-access-token`: Token for dashboard generation

## � API Reference

### Track Custom Event

```http
POST /api/appinsightstelemetryextension?operation=track_custom_event
Content-Type: application/json

{
  "event_name": "user_action_completed",
  "user_id": "user123",
  "properties": {
    "action_type": "document_analysis",
    "document_size": 1024,
    "processing_mode": "fast"
  },
  "metrics": {
    "processing_time_ms": 250.5,
    "confidence_score": 0.95
  }
}
```

**Response:**

```json
{
  "success": true,
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_name": "user_action_completed",
  "timestamp": "2025-01-22T08:55:14.123Z",
  "processing_time_ms": 12.5,
  "properties_count": 3,
  "metrics_count": 2
}
```

### Track Performance Metrics

```http
POST /api/appinsightstelemetryextension?operation=track_performance_metrics
Content-Type: application/json

{
  "operation_name": "document_processing",
  "duration_ms": 1250,
  "success": true,
  "additional_metrics": {
    "memory_usage_mb": 45.2,
    "cpu_percentage": 12.5
  }
}
```

### Analyze User Behavior

```http
POST /api/appinsightstelemetryextension?operation=analyze_user_behavior
Content-Type: application/json

{
  "user_id": "user123",
  "session_duration": 45,
  "actions": [
    {"type": "search", "timestamp": "2025-01-22T08:30:00Z"},
    {"type": "edit", "timestamp": "2025-01-22T08:32:15Z"},
    {"type": "save", "timestamp": "2025-01-22T08:35:30Z"}
  ],
  "feature_usage": ["search", "edit", "save", "export"]
}
```

### Generate Telemetry Dashboard

```http
POST /api/appinsightstelemetryextension?operation=generate_telemetry_dashboard
Content-Type: application/json

{
  "time_range": 24,
  "metrics": ["requests", "errors", "performance", "users"]
}
```

## 📈 Dashboard Examples

### Request Volume Dashboard

```json
{
  "dashboard_id": "dashboard-123",
  "widgets": [
    {
      "type": "line_chart",
      "title": "Request Volume",
      "metric": "requests_per_minute",
      "timeframe": "last_24_hours"
    },
    {
      "type": "gauge", 
      "title": "Average Response Time",
      "metric": "avg_response_time_ms",
      "threshold": 1000
    }
  ],
  "alerts": [
    {
      "name": "High Error Rate",
      "condition": "error_rate > 5%",
      "severity": "warning"
    }
  ]
}
```

## 🔍 Monitoring and Alerting

### Performance Thresholds

- **Response Time**: Alert if > 1000ms average
- **Error Rate**: Alert if > 5% of requests fail
- **Memory Usage**: Alert if > 80% of allocated memory
- **CPU Usage**: Alert if > 90% sustained for 5+ minutes

### User Engagement Metrics

- **Session Duration**: Track average session length
- **Feature Adoption**: Monitor feature usage patterns
- **User Retention**: Analyze return user patterns
- **Conversion Funnel**: Track user journey completion

## 🛡️ Security and Compliance

### Data Privacy

- PII data is hashed or tokenized before telemetry
- User consent mechanisms integrated
- GDPR-compliant data retention policies
- Secure data transmission (TLS 1.3)

### Access Control

- Azure AD integration for authentication
- Role-based access control (RBAC)
- API key rotation and management
- Audit logging for all access

## 🧪 Testing

### Unit Tests

```bash
# Run unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ --cov=appinsightstelemetryextension_service
```

### Integration Tests

```bash
# Test Azure Functions integration
pytest tests/integration/ -v

# Test Key Vault connectivity
pytest tests/integration/test_keyvault.py -v
```

### Load Testing

```bash
# Performance testing with Azure Load Testing
az load test create \
  --name telemetry-load-test \
  --resource-group MyResourceGroup \
  --test-plan load-test-config.yaml
```

## 📚 Best Practices Guide

### 1. Event Design Patterns

```python
# ✅ Good: Structured event with clear taxonomy
{
  "event_name": "copilot_suggestion_accepted",
  "event_category": "user_interaction", 
  "properties": {
    "suggestion_type": "code_completion",
    "confidence_score": 0.95,
    "user_context": "code_editor"
  }
}

# ❌ Avoid: Unstructured or overly verbose events
{
  "event_name": "stuff_happened",
  "data": "lots of unstructured text here..."
}
```

### 2. Performance Optimization

```python
# ✅ Batch telemetry events for efficiency
telemetry_batch = [event1, event2, event3]
service.track_batch_events(telemetry_batch)

# ❌ Avoid: Individual API calls for each event
for event in events:
    service.track_custom_event(event)  # Too many API calls
```

### 3. Error Handling

```python
# ✅ Comprehensive error tracking
try:
    result = risky_operation()
    service.track_custom_event({
        "event_name": "operation_success",
        "metrics": {"duration_ms": duration}
    })
except Exception as e:
    service.track_custom_event({
        "event_name": "operation_failure",
        "properties": {
            "error_type": type(e).__name__,
            "error_message": str(e)[:200]  # Truncate long messages
        }
    })
    raise
```

## 📞 Support and Troubleshooting

### Common Issues

**Issue**: Azure SDK import errors
**Solution**: Ensure Azure SDK packages are installed:

```bash
pip install azure-identity azure-keyvault-secrets azure-functions
```

**Issue**: Key Vault authentication failures
**Solution**: Verify Azure CLI authentication:

```bash
az login
az account show
```

**Issue**: High telemetry latency
**Solution**: Enable batching and adjust collection intervals:

```python
# Configure batching for better performance
service.configure_batching(batch_size=100, flush_interval=30)
```

### Debug Mode

```python
# Enable debug logging
import logging
logging.getLogger('appinsightstelemetryextension_service').setLevel(logging.DEBUG)
```

### Contact Information

- **Development Team**: [Your Team Contact]
- **Documentation**: [Your Documentation URL]
- **Issue Tracking**: [Your GitHub Issues URL]

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Follow coding standards (Black, Flake8, MyPy)
5. Submit a pull request

---

**Generated by M365 Copilot Plugin Framework v2.0.0**  
*Enterprise-grade telemetry for the modern workplace*

## 🏗️ Architecture

### Files Structure

```
AppInsightsTelemetryExtension-module/
├── connector-definition.json          # OpenAPI specification
├── connector-definition-secure.json   # Secure version with Key Vault
├── connector-properties.json          # Power Platform properties
├── connector-properties-secure.json   # Secure properties
├── deploy-appinsightstelemetryextension.ps1              # Deployment script
├── business-logic/                    # Implementation
│   └── appinsightstelemetryextension_service.py          # Service implementation
├── tests/                             # Test suite
├── docs/                              # Documentation
└── README.md                          # This file
```

### Security Features

- ✅ **Azure Key Vault Integration**: All secrets stored securely
- ✅ **Managed Identity**: Zero credential management
- ✅ **RBAC Permissions**: Proper access controls
- ✅ **OAuth 2.0**: Azure AD authentication
- ✅ **Enterprise Compliance**: Audit trail and monitoring

---

## 🔧 Customization

### Adding New Operations

1. **Update OpenAPI** (connector-definition.json)
2. **Implement Handler** (usiness-logic/appinsightstelemetryextension_service.py)
3. **Add Tests** ( ests/)
4. **Redeploy** using deployment script

### Integrating External Systems

1. **Add API Client** in service class
2. **Store Credentials** in Azure Key Vault
3. **Update Authentication** scopes if needed
4. **Test Integration** end-to-end

---

## 🧪 Testing

### Manual Testing

```powershell
# Test health endpoint
Invoke-RestMethod -Uri "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/appinsightstelemetryextension/health"

# Test operation endpoint
$body = @{ query = "test"; limit = 5 } | ConvertTo-Json
Invoke-RestMethod -Uri "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/appinsightstelemetryextension/searchcontacts" -Method POST -Body $body -ContentType "application/json"
```

### Power Platform Testing

1. Open your connector in Power Platform
2. Go to **Test** tab
3. Create a new connection
4. Test each operation with sample data

---

## 📊 Monitoring

### Application Insights

Monitor your plugin usage and performance:

- **Function App**: <https://portal.azure.com/#@BoopasBagelDeli.onmicrosoft.com/resource/subscriptions/0098349c-01ee-4e71-aecf-a312e1ca1074/resourceGroups/rg-declarative-agent-plugin/providers/Microsoft.Web/sites/copilot-plugin-func-f46zzw7hhsh2q>
- **Application Insights**: Telemetry and performance metrics
- **Key Vault**: Security audit logs

### Health Monitoring

The plugin includes health check endpoints for monitoring:

- **Health Check**: /api/appinsightstelemetryextension/health
- **Status**: Returns plugin status and timestamp

---

## 🎯 Usage Examples

### In Power Automate

1. Create a new flow
2. Add **AppInsightsTelemetryExtension** connector action
3. Configure authentication
4. Use operations in your workflow

### In Power Apps

1. Add **AppInsightsTelemetryExtension** as data source
2. Use operations in Power Fx formulas
3. Display results in your app

### In M365 Copilot

The plugin operations are available in M365 Copilot context for natural language interactions.

---

## 🤝 Support

- **Documentation**: See docs/ folder for detailed guides
- **Issues**: Use project issue tracking
- **Security**: Report security issues through proper channels

---

**Generated by Plugin Generator Framework**  
**Template Version**: 1.0.0  
**Framework**: M365 Copilot Plugin Ecosystem
