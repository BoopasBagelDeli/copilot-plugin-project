# M365 Copilot Plugin Template

## 🎯 Template Usage Guide

This repository serves as a complete template for building Microsoft 365 Copilot plugins with Azure Functions.

### 📋 Prerequisites

- Azure subscription with appropriate permissions
- GitHub account for CI/CD
- Azure Developer CLI (`azd`) installed
- Python 3.11+ for local development
- Visual Studio Code with Azure Functions extension

### 🚀 Quick Start from Template

#### 1. Use This Template

```bash
# Click "Use this template" in GitHub, or clone:
git clone https://github.com/BoopasBagelDeli/copilot-plugin-project.git my-new-plugin
cd my-new-plugin
```

#### 2. Customize Your Plugin

Edit these key files:

**`plugins/openapi.yaml`**

- Update API endpoints for your specific use case
- Modify operation IDs and descriptions
- Add your custom request/response schemas

**`src/main.py`**

- Replace `SearchService` and `AnalysisService` with your business logic
- Update endpoint implementations
- Customize authentication if needed

**`plugins/plugin_manifest.json`**

- Change plugin name and description
- Update contact information
- Modify conversation starters

**`infra/main.bicep`**

- Adjust resource naming and sizing
- Add additional Azure resources as needed
- Update tags and metadata

#### 3. Configure Environment

```bash
# Copy local settings template
cp local.settings.json.template local.settings.json

# Update with your values:
# - Tenant ID
# - Client ID  
# - Key Vault URL
```

#### 4. Deploy to Azure

```bash
# Initialize Azure resources
azd init

# Deploy infrastructure and code
azd up
```

#### 5. Register with M365 Copilot

- Follow `azure-ad-setup.md` for Azure AD configuration
- Register plugin in Microsoft Teams Admin Center
- Test with Microsoft 365 Copilot

## 🔧 Customization Examples

### Adding New Endpoints

1. **Update OpenAPI Specification** (`plugins/openapi.yaml`):

```yaml
paths:
  /api/my-custom-endpoint:
    post:
      operationId: myCustomOperation
      summary: My custom operation
      # ... rest of endpoint definition
```

2. **Implement in Python** (`src/main.py`):

```python
@app.route(route="my-custom-endpoint", methods=["POST"])
@SecurityMiddleware.require_bearer_token
def my_custom_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    # Your custom logic here
    pass
```

### Adding New Services

Create service classes following the pattern:

```python
class MyService:
    @staticmethod
    @track_function(telemetry, "my_operation")
    def my_operation(data: str) -> Dict[str, Any]:
        # Service implementation
        pass
```

### Adding Azure Resources

Update `infra/main.bicep`:

```bicep
resource myNewResource 'Microsoft.SomeService/resource@2023-01-01' = {
  name: 'my-resource-${resourceToken}'
  location: location
  tags: tags
  // ... resource configuration
}
```

## 📊 Template Features

### ✅ Included Features

- Complete Azure Functions Python app
- OpenAPI 3.0.1 specification
- Azure Bicep infrastructure
- Application Insights telemetry
- Key Vault integration
- Managed identity authentication
- GitHub Actions CI/CD
- Comprehensive documentation
- Example endpoints and services
- Security middleware
- Rate limiting
- Error handling
- Health monitoring

### 🔄 Customizable Components

- **Business Logic**: Replace example services with your domain logic
- **API Endpoints**: Add/modify endpoints in OpenAPI spec
- **Azure Resources**: Extend infrastructure as needed
- **Authentication**: Customize security requirements
- **Telemetry**: Add custom metrics and logging
- **CI/CD**: Adapt workflows for your deployment strategy

## 📚 Documentation Structure

- `README.md` - Main project documentation
- `azure-ad-setup.md` - Azure AD configuration guide
- `CONTRIBUTING.md` - Development guidelines
- `docs/architecture.md` - System architecture overview
- `docs/telemetry.md` - Monitoring and observability

## 🏷️ Template Versioning

This template follows semantic versioning:

- **Major**: Breaking changes to template structure
- **Minor**: New features and improvements
- **Patch**: Bug fixes and documentation updates

Current version: `1.0.0`

## 🤝 Contributing to Template

1. Fork the template repository
2. Create feature branch for improvements
3. Test with real plugin implementation
4. Submit pull request with clear description

## 📞 Support

- **Issues**: Use GitHub Issues for template bugs
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check `docs/` folder for detailed guides
