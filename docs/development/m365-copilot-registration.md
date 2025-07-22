# Microsoft 365 Copilot Plugin Registration Guide

## 🎯 Overview

Microsoft 365 Copilot plugins are registered through the Microsoft Teams Admin Center and Microsoft 365 admin center, **NOT** through Copilot Studio. Copilot Studio is for Power Platform copilots, while this is a declarative plugin for Microsoft 365 Copilot.

## 📋 Registration Steps

### Phase 1: Complete Azure AD Setup (Already Done ✅)

Your Azure AD app registration is complete:

- **App ID**: `ce52f3ea-a567-4540-9c12-3e7941b825bf`
- **Status**: ✅ Created and configured
- **Next**: Complete Azure Portal permissions setup

### Phase 2: Prepare Plugin Package

Create the plugin package for M365 Copilot registration:

#### 1. Plugin Manifest (Already Created ✅)

- **File**: `plugins/plugin_manifest.json`
- **Status**: ✅ Ready for registration
- **Contains**: Plugin identity, capabilities, OpenAPI spec reference

#### 2. Create App Package for Teams Admin Center

Create a Teams app package that references your plugin:

```json
{
  "manifestVersion": "1.17",
  "version": "1.0.0",
  "id": "ce52f3ea-a567-4540-9c12-3e7941b825bf",
  "packageName": "com.company.copilot-plugin",
  "developer": {
    "name": "Your Company",
    "websiteUrl": "https://company.com",
    "privacyUrl": "https://company.com/privacy",
    "termsOfUseUrl": "https://company.com/terms"
  },
  "icons": {
    "color": "color.png",
    "outline": "outline.png"
  },
  "name": {
    "short": "Company Data Plugin",
    "full": "Company Data Plugin for Microsoft 365 Copilot"
  },
  "description": {
    "short": "Search and analyze company data",
    "full": "A declarative plugin that helps users search and analyze company data through Microsoft 365 Copilot"
  },
  "accentColor": "#FFFFFF",
  "copilotExtensions": {
    "declarativeAgents": [
      {
        "id": "company-data-plugin",
        "file": "plugin_manifest.json"
      }
    ]
  }
}
```

### Phase 3: Register in Microsoft Teams Admin Center

#### Prerequisites

- ✅ Azure AD app registration complete
- ✅ Function App deployed and running
- ✅ Plugin manifest ready
- ⏳ API permissions granted in Azure Portal
- ⏳ Teams app package created

#### Registration Process

1. **Access Teams Admin Center**
   - Go to: <https://admin.teams.microsoft.com>
   - Sign in with Global Admin or Teams Administrator credentials

2. **Navigate to Apps Management**
   - Teams apps → Manage apps
   - Upload → Upload app package

3. **Upload Plugin Package**
   - Upload the .zip package containing:
     - `manifest.json` (Teams app manifest)
     - `plugin_manifest.json` (Copilot plugin manifest)
     - `color.png` and `outline.png` (app icons)

4. **Configure App Policies**
   - Set app availability for users/groups
   - Configure permission policies
   - Enable for Microsoft 365 Copilot

### Phase 4: Enable in Microsoft 365 Admin Center

1. **Access M365 Admin Center**
   - Go to: <https://admin.microsoft.com>
   - Navigate to Settings → Integrated apps

2. **Manage Copilot Plugins**
   - Find your uploaded plugin
   - Configure user access and permissions
   - Enable for Copilot integration

### Phase 5: User Experience

Once registered, users can:

1. **Discover the plugin** in Microsoft 365 Copilot
2. **Use natural language** to invoke plugin functions:
   - "Search for recent documents about quarterly review"
   - "Analyze the sentiment of this customer feedback"
   - "Find contacts in the sales department"

3. **Plugin responds** with data from your Azure Function endpoints

## 🔧 Current Status & Next Steps

### ✅ Completed

- Azure AD app registration
- Azure Function App deployment
- Plugin manifest creation
- Infrastructure setup

### ⏳ Remaining Tasks

1. **Complete Azure Portal Setup** (5 minutes)
   - Grant API permissions
   - Configure authentication settings

2. **Create Teams App Package** (10 minutes)
   - Teams app manifest
   - App icons
   - Package as .zip file

3. **Register in Teams Admin Center** (5 minutes)
   - Upload package
   - Configure policies

4. **Test with M365 Copilot** (ongoing)
   - Verify plugin discovery
   - Test conversation flows
   - Validate responses

## 📞 Support & Resources

### Microsoft Documentation

- [Declarative agents for Microsoft 365 Copilot](https://docs.microsoft.com/microsoft-365-copilot/extensibility/overview-declarative-agent)
- [Teams app manifest schema](https://docs.microsoft.com/microsoftteams/platform/resources/schema/manifest-schema)
- [Teams Admin Center](https://docs.microsoft.com/microsoftteams/manage-apps)

### Admin Portals

- **Teams Admin Center**: <https://admin.teams.microsoft.com>
- **M365 Admin Center**: <https://admin.microsoft.com>
- **Azure Portal**: <https://portal.azure.com>

## ⚠️ Important Notes

1. **NOT Copilot Studio**: This plugin is for M365 Copilot, not Power Platform Copilot Studio
2. **Admin Access Required**: Registration requires Teams/M365 administrator privileges
3. **Tenant Scope**: Plugin will be available to users in your Microsoft 365 tenant
4. **Security**: All authentication and permissions are managed through Azure AD
