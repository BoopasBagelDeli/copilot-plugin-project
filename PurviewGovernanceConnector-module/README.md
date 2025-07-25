# 🛡️ PurviewGovernanceConnector Module

## 🎯 Overview

Microsoft Purview governance and compliance for M365 Copilot

**Category**: Governance & Compliance  
**Generated**: 2025-07-22 09:19:04  
**Type**: Governance Plugin Module  

---

## 🔌 Available Operations

This plugin provides the following operations for M365 Copilot and Power Platform:
- **GetDataClassification**: G e t D a t a C l a s s i f i c a t i o n
- **CheckCompliance**: C h e c k C o m p l i a n c e
- **AuditDataAccess**: A u d i t D a t a A c c e s s
- **GetGovernancePolicies**: G e t G o v e r n a n c e P o l i c i e s
- **GenerateComplianceReport**: G e n e r a t e C o m p l i a n c e R e p o r t
- **TrackDataLineage**: T r a c k D a t a L i n e a g e

---

## 🚀 Quick Start

### 1. Deploy to Power Platform

```powershell
# Deploy with enterprise security (recommended)
.\deploy-purviewgovernanceconnector.ps1 -UseSecureConnector

# Test deployment
.\deploy-purviewgovernanceconnector.ps1 -Environment "your-environment-id"
```

### 2. Access Your Connector

- **Power Platform**: https://make.powerapps.com/environments/de96b383-5f31-4895-9b41-88f3b7435919/customconnectors
- **Power Automate**: https://make.powerautomate.com/
- **Power Apps**: https://make.powerapps.com/

### 3. Test Operations

Each operation accepts a JSON request:

```json
{
  "query": "search terms or operation parameters",
  "limit": 10
}
```

---

## 🏗️ Architecture

### Files Structure

```
PurviewGovernanceConnector-module/
├── connector-definition.json          # OpenAPI specification
├── connector-definition-secure.json   # Secure version with Key Vault
├── connector-properties.json          # Power Platform properties
├── connector-properties-secure.json   # Secure properties
├── deploy-purviewgovernanceconnector.ps1              # Deployment script
├── business-logic/                    # Implementation
│   └── purviewgovernanceconnector_service.py          # Service implementation
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
2. **Implement Handler** (usiness-logic/purviewgovernanceconnector_service.py)
3. **Add Tests** (	ests/)
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
Invoke-RestMethod -Uri "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/purviewgovernanceconnector/health"

# Test operation endpoint
$body = @{ query = "test"; limit = 5 } | ConvertTo-Json
Invoke-RestMethod -Uri "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/purviewgovernanceconnector/searchcontacts" -Method POST -Body $body -ContentType "application/json"
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

- **Function App**: https://portal.azure.com/#@BoopasBagelDeli.onmicrosoft.com/resource/subscriptions/0098349c-01ee-4e71-aecf-a312e1ca1074/resourceGroups/rg-declarative-agent-plugin/providers/Microsoft.Web/sites/copilot-plugin-func-f46zzw7hhsh2q
- **Application Insights**: Telemetry and performance metrics
- **Key Vault**: Security audit logs

### Health Monitoring

The plugin includes health check endpoints for monitoring:

- **Health Check**: /api/purviewgovernanceconnector/health
- **Status**: Returns plugin status and timestamp

---

## 🎯 Usage Examples

### In Power Automate

1. Create a new flow
2. Add **PurviewGovernanceConnector** connector action
3. Configure authentication
4. Use operations in your workflow

### In Power Apps

1. Add **PurviewGovernanceConnector** as data source
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
