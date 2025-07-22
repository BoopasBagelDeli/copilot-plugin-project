# Microsoft 365 Copilot Plugin Project

A declarative Microsoft 365 Copilot plugin that enables intelligent search and content analysis capabilities through Azure Functions and modern cloud architecture.

## 🚀 Quick Start

### Prerequisites

- Microsoft 365 E5 license
- Azure subscription
- GitHub account with Copilot enabled
- Azure DevOps organization (optional for CD)
- VS Code with extensions:
  - GitHub Copilot
  - Teams Toolkit
  - Azure Tools
  - YAML Support

### 🛠️ Setup

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd copilot-plugin-project
   ```

2. **Install dependencies**

   ```bash
   # Python dependencies
   pip install -r requirements.txt
   
   # Azure Functions Core Tools
   npm install -g azure-functions-core-tools@4
   
   # Azure Developer CLI
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

3. **Configure environment**

   ```bash
   # Initialize Azure Developer CLI
   azd init
   
   # Set environment variables
   cp local.settings.json.template local.settings.json
   # Edit local.settings.json with your values
   ```

4. **Deploy to Azure**

   ```bash
   azd up
   ```

## 📁 Project Structure

```
copilot-plugin-project/
├── src/                      # Plugin logic
│   ├── telemetry.py         # Application Insights integration
│   └── main.py              # Azure Functions endpoints
├── plugins/                  # OpenAPI + manifests
│   ├── openapi.yaml         # API specification
│   ├── plugin_manifest.json # Copilot plugin manifest
│   └── plugin_config.json   # Configuration settings
├── infra/                   # Azure infrastructure
│   ├── main.bicep          # Main Bicep template
│   └── main.parameters.json # Parameters file
├── .github/workflows/       # CI/CD pipelines
│   ├── ci.yml              # Continuous integration
│   └── validate_plugin.yml  # Plugin validation
├── docs/                    # Documentation
│   ├── README.md           # This file
│   ├── architecture.md     # Architecture overview
│   └── telemetry.md        # Telemetry guide
├── tests/                   # Test files
├── requirements.txt         # Python dependencies
├── host.json               # Azure Functions configuration
└── azure.yaml              # Azure Developer CLI configuration
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `AZURE_TENANT_ID` | Azure AD tenant ID | Yes |
| `AZURE_CLIENT_ID` | Application client ID | Yes |
| `APPLICATION_INSIGHTS_CONNECTION_STRING` | AI connection string | No |
| `KEY_VAULT_URL` | Key Vault URL | No |
| `ENVIRONMENT` | Deployment environment | No |
| `RATE_LIMIT_PER_MINUTE` | API rate limit | No |

### Plugin Configuration

Edit `plugins/plugin_config.json` to customize:

- API endpoints and base URLs
- Authentication settings
- Feature toggles
- Rate limiting
- Security policies

## 🧪 Testing

### Local Development

```bash
# Start Azure Functions locally
func start

# Run unit tests
pytest tests/

# Run integration tests
pytest tests/integration/

# Validate plugin
python scripts/validate_plugin.py
```

### CI/CD Pipeline

The project includes comprehensive GitHub Actions workflows:

- **CI Pipeline** (`ci.yml`): Linting, testing, security scans, build artifacts
- **Plugin Validation** (`validate_plugin.yml`): OpenAPI validation, Copilot compatibility checks

## 📊 Monitoring & Telemetry

The plugin includes comprehensive telemetry through Azure Application Insights:

- **Custom Events**: Plugin usage, function executions
- **Request Tracking**: HTTP requests with correlation IDs
- **Exception Tracking**: Error details with context
- **Dependency Tracking**: External service calls
- **Performance Metrics**: Response times, throughput

See [telemetry.md](docs/telemetry.md) for detailed configuration.

## 🔒 Security

### Authentication

- **Bearer Token**: JWT validation against Azure AD
- **Managed Identity**: Secure access to Azure resources
- **Key Vault Integration**: Secure secrets management

### Security Features

- HTTPS enforcement
- CORS configuration
- Content Security Policy
- Input validation and sanitization
- Rate limiting
- Request size limits

### Compliance

- Data classification support
- Audit logging
- Retention policies
- Governance integration

## 🚀 Deployment

### Azure Developer CLI (Recommended)

```bash
# Deploy infrastructure and application
azd up

# Update application only
azd deploy

# View deployment logs
azd logs
```

### Manual Deployment

```bash
# Deploy infrastructure
az deployment group create \
  --resource-group myResourceGroup \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json

# Deploy function app
func azure functionapp publish <function-app-name>
```

## 📚 API Endpoints

### Search Data

```http
GET /api/search?query={query}&limit={limit}&category={category}
Authorization: Bearer {token}
```

### Analyze Content

```http
POST /api/analyze
Authorization: Bearer {token}
Content-Type: application/json

{
  "content": "text to analyze",
  "analysisType": "sentiment|keywords|summary|insights",
  "options": {
    "language": "en-US",
    "includeConfidence": true
  }
}
```

### Health Check

```http
GET /api/health
```

## 🔄 Development Workflow

1. **Feature Development**
   - Create feature branch
   - Implement changes
   - Write tests
   - Update documentation

2. **Testing**
   - Run local tests
   - Validate plugin compatibility
   - Test with Copilot (if available)

3. **Deployment**
   - Create pull request
   - CI pipeline validation
   - Deploy to staging
   - Production deployment

4. **Monitoring**
   - Monitor telemetry
   - Review logs
   - Performance analysis
   - User feedback

## 🛡️ Governance

### Microsoft Purview Integration

- Sensitivity labels
- Retention policies
- Audit logging
- Data classification

### Power Platform Governance

- DLP policies
- Connector governance
- Flow management
- Admin center integration

## 🔧 Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Azure AD configuration
   - Check token scopes
   - Validate client credentials

2. **Deployment Failures**
   - Check Azure permissions
   - Verify resource quotas
   - Review deployment logs

3. **Plugin Not Working**
   - Validate OpenAPI specification
   - Check manifest configuration
   - Verify endpoint accessibility

### Debug Commands

```bash
# Check Azure Functions logs
func logs

# Validate OpenAPI spec
swagger-parser validate plugins/openapi.yaml

# Test endpoints locally
curl -X GET "http://localhost:7071/api/health"

# Check Azure resources
az resource list --resource-group <rg-name>
```

## 📈 Performance Optimization

- **Caching**: Redis or in-memory caching for frequent queries
- **Connection Pooling**: Efficient database connections
- **Async Processing**: Non-blocking operations
- **CDN Integration**: Static content delivery
- **Monitoring**: Continuous performance analysis

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: GitHub Issues
- **Documentation**: [Architecture Guide](docs/architecture.md)
- **Telemetry**: [Telemetry Guide](docs/telemetry.md)
- **Teams**: [Teams Integration Guide](docs/teams.md)

## 🔗 Useful Links

- [Microsoft 365 Copilot Documentation](https://docs.microsoft.com/copilot/)
- [Azure Functions Documentation](https://docs.microsoft.com/azure/azure-functions/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Azure Developer CLI](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
