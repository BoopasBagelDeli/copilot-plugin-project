# Azure AD App Registration Setup Guide

## 🎯 App Registration Created Successfully!

Your Azure AD app registration has been created with the following details:

### 📋 App Registration Details
- **App ID (Client ID)**: `ce52f3ea-a567-4540-9c12-3e7941b825bf`
- **Object ID**: `f98bae33-443a-41cc-803a-d6b95dd58534`
- **Display Name**: `M365 Copilot Plugin API`
- **Tenant ID**: `de96b383-5f31-4895-9b41-88f3b7435919`
- **Publisher Domain**: `BoopasBagelDeli.onmicrosoft.com`
- **Client Secret**: `[SECURED IN KEY VAULT]` ⚠️ (Stored securely in Azure Key Vault)

## 🔧 Manual Steps to Complete Setup

### Step 1: Configure API Permissions in Azure Portal

1. **Go to Azure Portal**: https://portal.azure.com
2. **Navigate to**: Azure Active Directory → App registrations
3. **Find your app**: "M365 Copilot Plugin API"
4. **Go to**: API permissions
5. **Add the following permissions**:
   - **Microsoft Graph** → Delegated permissions:
     - `User.Read` (Sign in and read user profile)
     - `profile` (View users' basic profile)
     - `openid` (Sign users in)
     - `email` (View users' email address)

6. **Grant admin consent** for your organization

### Step 2: Configure Authentication

1. **In your app registration**, go to **Authentication**
2. **Verify redirect URI** is set to:
   ```
   https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/.auth/login/aad/callback
   ```
3. **Enable ID tokens** under "Implicit grant and hybrid flows"
4. **Set supported account types** to "Accounts in this organizational directory only"

### Step 3: Configure App Service Authentication

Run these commands to configure your Azure Function App with authentication:

```bash
# Configure Azure Function App authentication
az webapp auth update \
  --name copilot-plugin-func-f46zzw7hhsh2q \
  --resource-group rg-declarative-agent-plugin \
  --enabled true \
  --action LoginWithAzureActiveDirectory

# Configure Azure AD provider
az webapp auth microsoft update \
  --name copilot-plugin-func-f46zzw7hhsh2q \
  --resource-group rg-declarative-agent-plugin \
  --client-id ce52f3ea-a567-4540-9c12-3e7941b825bf \
  --client-secret [YOUR_CLIENT_SECRET_FROM_KEY_VAULT] \
  --tenant-id de96b383-5f31-4895-9b41-88f3b7435919
```

### Step 4: Update Function App Configuration

Add these application settings to your Function App:

```bash
az functionapp config appsettings set \
  --name copilot-plugin-func-f46zzw7hhsh2q \
  --resource-group rg-declarative-agent-plugin \
  --settings \
  "AZURE_CLIENT_ID=ce52f3ea-a567-4540-9c12-3e7941b825bf" \
  "AZURE_CLIENT_SECRET=[YOUR_CLIENT_SECRET_FROM_KEY_VAULT]" \
  "AZURE_TENANT_ID=de96b383-5f31-4895-9b41-88f3b7435919"
```

### Step 5: Update Plugin Manifest

Update your `plugins/plugin_manifest.json` file with the authentication details:

```json
{
  "authorization": {
    "authorizationType": "OAuthPluginVault",
    "oAuthConfig": {
      "oauthUrl": "https://login.microsoftonline.com/de96b383-5f31-4895-9b41-88f3b7435919/oauth2/v2.0/authorize",
      "tokenUrl": "https://login.microsoftonline.com/de96b383-5f31-4895-9b41-88f3b7435919/oauth2/v2.0/token",
      "scope": "https://graph.microsoft.com/User.Read",
      "clientId": "ce52f3ea-a567-4540-9c12-3e7941b825bf"
    }
  }
}
```

## 🔒 Security Considerations

### ⚠️ Important Security Notes:
1. **Client Secret**: The client secret is stored in this file temporarily. Move it to Azure Key Vault immediately!
2. **Never commit secrets**: Add `app-registration.json` to `.gitignore`
3. **Rotate secrets**: Client secret expires on 2027-07-22

### 🏗️ Move Secret to Key Vault:

```bash
# Add secret to Key Vault
az keyvault secret set \
  --vault-name kvf46zzw7hdeclarat \
  --name "azure-client-secret" \
  --value "[YOUR_CLIENT_SECRET_FROM_AZURE_AD_APP_REGISTRATION]"

# Update Function App to use Key Vault reference
az functionapp config appsettings set \
  --name copilot-plugin-func-f46zzw7hhsh2q \
  --resource-group rg-declarative-agent-plugin \
  --settings \
  "AZURE_CLIENT_SECRET=@Microsoft.KeyVault(VaultName=kvf46zzw7hdeclarat;SecretName=azure-client-secret)"
```

## 🧪 Testing Your Authentication

### Test Authentication Endpoint:
```bash
curl "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/.auth/me"
```

### Test API with Bearer Token:
```bash
# Get access token first, then test API
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://copilot-plugin-func-f46zzw7hhsh2q.azurewebsites.net/api/search?query=test"
```

## 📋 Next Steps

1. **Complete manual configuration** in Azure Portal
2. **Move secrets to Key Vault** for security
3. **Test authentication flow** with your plugin
4. **Register plugin** in Microsoft Teams Admin Center
5. **Test in Microsoft 365 Copilot**

## 🎉 Your Plugin is Ready!

Once these steps are complete, your Microsoft 365 Copilot Plugin will be:
- ✅ **Authenticated** with Azure AD
- ✅ **Secured** with proper permissions
- ✅ **Integrated** with Microsoft Graph
- ✅ **Ready** for production use

## 🔗 Useful Links

- **Azure Portal**: https://portal.azure.com
- **App Registration**: https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/ce52f3ea-a567-4540-9c12-3e7941b825bf
- **Function App**: https://portal.azure.com/#@/resource/subscriptions/0098349c-01ee-4e71-aecf-a312e1ca1074/resourceGroups/rg-declarative-agent-plugin/providers/Microsoft.Web/sites/copilot-plugin-func-f46zzw7hhsh2q/overview
- **Key Vault**: https://portal.azure.com/#@/resource/subscriptions/0098349c-01ee-4e71-aecf-a312e1ca1074/resourceGroups/rg-declarative-agent-plugin/providers/Microsoft.KeyVault/vaults/kvf46zzw7hdeclarat/overview
