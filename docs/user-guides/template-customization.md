# Template Configuration for M365 Copilot Plugin

This file documents how to customize this template for new M365 Copilot plugins.

## 🔧 Quick Customization Checklist

### 1. Project Identity

- [ ] Update `README.md` title and description
- [ ] Change repository name in GitHub
- [ ] Update `azure.yaml` name field
- [ ] Modify `package.json` name (if added)

### 2. Plugin Configuration

- [ ] Edit `plugins/plugin_manifest.json`:
  - [ ] `name_for_human`
  - [ ] `description_for_human`
  - [ ] `description_for_model`
  - [ ] `contact_email`
  - [ ] `legal_info_url`
  - [ ] `privacy_policy_url`
  - [ ] `conversation_starters`

### 3. OpenAPI Specification  

- [ ] Update `plugins/openapi.yaml`:
  - [ ] `info.title`
  - [ ] `info.description`
  - [ ] `info.contact`
  - [ ] `servers` URLs
  - [ ] Custom endpoints in `paths`
  - [ ] Request/response schemas

### 4. Business Logic

- [ ] Replace example services in `src/main.py`:
  - [ ] `SearchService.search_data()`
  - [ ] `AnalysisService.analyze_content()`
  - [ ] Add your domain-specific logic

### 5. Infrastructure

- [ ] Customize `infra/main.bicep`:
  - [ ] Resource naming prefix
  - [ ] Tags and metadata  
  - [ ] Additional Azure resources
  - [ ] SKU/sizing requirements

### 6. Security & Auth

- [ ] Review `required-permissions.json`
- [ ] Update Azure AD permissions as needed
- [ ] Customize authentication in `SecurityMiddleware`

### 7. Development Environment

- [ ] Copy `local.settings.json.template` to `local.settings.json`
- [ ] Update environment variables
- [ ] Add any new Python dependencies to `requirements.txt`

### 8. CI/CD

- [ ] Review `.github/workflows/` files
- [ ] Update branch protection rules
- [ ] Configure deployment environments

### 9. Documentation

- [ ] Update `azure-ad-setup.md` with your specifics
- [ ] Customize `CONTRIBUTING.md`
- [ ] Add domain-specific documentation in `docs/`

### 10. Testing

- [ ] Add unit tests in `tests/`
- [ ] Test plugin registration process
- [ ] Validate with M365 Copilot

## 🎯 Common Customization Patterns

### Adding New Endpoints

1. **Define in OpenAPI** (`plugins/openapi.yaml`)
2. **Implement handler** in `src/main.py`
3. **Add service class** for business logic
4. **Update tests** in `tests/`

### Integrating External APIs

1. **Add API client** in new service class
2. **Store credentials** in Key Vault
3. **Add error handling** and retry logic
4. **Update telemetry** tracking

### Adding Database

1. **Define Bicep resource** in `infra/main.bicep`
2. **Add connection string** to Key Vault
3. **Create data access layer** in `src/`
4. **Update managed identity** permissions

## 🏷️ Template Variables to Replace

When using this template, search and replace these placeholders:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `copilot-plugin` | Project name prefix | `my-awesome-plugin` |
| `Company Data Plugin` | Human-readable name | `Sales Intelligence Plugin` |
| `support@company.com` | Contact email | `support@mycompany.com` |
| `https://company.com` | Company URLs | `https://mycompany.com` |
| `BoopasBagelDeli` | GitHub owner | `MyOrganization` |

## 📋 Validation Checklist

Before deploying your customized plugin:

- [ ] OpenAPI spec validates with Spectral
- [ ] All tests pass locally
- [ ] Azure resources deploy successfully
- [ ] Function App health check passes
- [ ] Azure AD app registration works
- [ ] Plugin registers with M365 Copilot
- [ ] End-to-end conversation test works

## 🚀 Ready-to-Use Templates

This template supports creating these types of plugins:

### 📊 Data Analytics Plugin

- Search organizational data
- Generate insights and reports
- Connect to BI systems

### 🎯 CRM Integration Plugin  

- Customer data lookup
- Lead scoring and analysis
- Sales pipeline insights

### 📋 Project Management Plugin

- Task and project search
- Resource allocation analysis
- Timeline and milestone tracking

### 🔍 Knowledge Base Plugin

- Document search and summarization
- FAQ assistance
- Expert recommendation

### 📈 Business Intelligence Plugin

- KPI monitoring and alerts
- Trend analysis
- Performance reporting

Each specialization requires customizing the services, endpoints, and data connections while keeping the core template structure intact.
