#!/usr/bin/env python3
"""
Template initialization script for M365 Copilot Plugin
Helps customize the template for new plugin projects
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, Any


def get_user_input(prompt: str, default: str = "") -> str:
    """Get user input with optional default value"""
    if default:
        user_input = input(f"{prompt} [{default}]: ").strip()
        return user_input if user_input else default
    return input(f"{prompt}: ").strip()


def update_json_file(file_path: Path, updates: Dict[str, Any]) -> None:
    """Update JSON file with new values"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        for key, value in updates.items():
            if '.' in key:
                # Handle nested keys like "info.title"
                keys = key.split('.')
                current = data
                for k in keys[:-1]:
                    current = current.setdefault(k, {})
                current[keys[-1]] = value
            else:
                data[key] = value
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Updated {file_path}")
    except Exception as e:
        print(f"❌ Error updating {file_path}: {e}")


def update_yaml_file(file_path: Path, replacements: Dict[str, str]) -> None:
    """Update YAML file with string replacements"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        for old_value, new_value in replacements.items():
            content = content.replace(old_value, new_value)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Updated {file_path}")
    except Exception as e:
        print(f"❌ Error updating {file_path}: {e}")


def update_text_file(file_path: Path, replacements: Dict[str, str]) -> None:
    """Update text file with string replacements"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        for old_value, new_value in replacements.items():
            content = content.replace(old_value, new_value)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Updated {file_path}")
    except Exception as e:
        print(f"❌ Error updating {file_path}: {e}")


def main():
    """Main template initialization function"""
    print("🚀 M365 Copilot Plugin Template Initializer")
    print("=" * 50)
    
    # Get project root directory
    project_root = Path.cwd()
    
    # Verify we're in a template directory
    required_files = [
        'plugins/plugin_manifest.json',
        'plugins/openapi.yaml',
        'azure.yaml',
        'src/main.py'
    ]
    
    missing_files = [f for f in required_files if not (project_root / f).exists()]
    if missing_files:
        print(f"❌ Missing required template files: {missing_files}")
        print("Please run this script from the template root directory.")
        sys.exit(1)
    
    print("📝 Please provide the following information for your new plugin:")
    print()
    
    # Collect user input
    plugin_name = get_user_input("Plugin name (e.g., 'Sales Intelligence Plugin')", "My Copilot Plugin")
    plugin_description = get_user_input("Plugin description", f"A Microsoft 365 Copilot plugin for {plugin_name.lower()}")
    company_name = get_user_input("Company/Organization name", "My Company")
    contact_email = get_user_input("Contact email", "support@mycompany.com")
    company_domain = get_user_input("Company domain (without https://)", "mycompany.com")
    project_prefix = get_user_input("Project prefix for Azure resources", "my-plugin")
    
    # Generate derived values
    company_url = f"https://{company_domain}"
    
    print()
    print("🔄 Updating template files...")
    
    # Update plugin manifest
    manifest_updates = {
        "name_for_human": plugin_name,
        "description_for_human": plugin_description,
        "description_for_model": f"This plugin enables Microsoft 365 Copilot to {plugin_description.lower()}",
        "contact_email": contact_email,
        "legal_info_url": f"{company_url}/legal",
        "privacy_policy_url": f"{company_url}/privacy",
        "logo_url": f"{company_url}/logo.png"
    }
    
    update_json_file(project_root / 'plugins/plugin_manifest.json', manifest_updates)
    
    # Update OpenAPI specification
    openapi_replacements = {
        "M365 Copilot Plugin API": f"{plugin_name} API",
        "Declarative plugin for Microsoft 365 Copilot integration": plugin_description,
        "support@company.com": contact_email
    }
    
    update_yaml_file(project_root / 'plugins/openapi.yaml', openapi_replacements)
    
    # Update azure.yaml
    azure_replacements = {
        "copilot-plugin-project": project_prefix,
        "copilot-plugin@1.0.0": f"{project_prefix}@1.0.0"
    }
    
    update_yaml_file(project_root / 'azure.yaml', azure_replacements)
    
    # Update main.bicep
    bicep_replacements = {
        "copilot-plugin": project_prefix,
        "Copilot-Plugin": plugin_name
    }
    
    update_text_file(project_root / 'infra/main.bicep', bicep_replacements)
    
    # Update README.md
    readme_replacements = {
        "Microsoft 365 Copilot Plugin Project": plugin_name,
        "This project demonstrates the complete implementation of a declarative Microsoft 365 Copilot plugin": plugin_description,
        "support@company.com": contact_email
    }
    
    update_text_file(project_root / 'README.md', readme_replacements)
    
    print()
    print("✅ Template initialization complete!")
    print()
    print("📋 Next steps:")
    print("1. Review and customize the generated files")
    print("2. Update business logic in src/main.py")
    print("3. Add your specific API endpoints to plugins/openapi.yaml")
    print("4. Run 'azd init' to initialize Azure resources")
    print("5. Run 'azd up' to deploy to Azure")
    print()
    print("📚 See TEMPLATE_CUSTOMIZATION.md for detailed customization guide")


if __name__ == "__main__":
    main()
