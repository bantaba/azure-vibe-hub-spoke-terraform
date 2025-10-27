"""
Custom Checkov policies for Azure Key Vault security
These policies extend the default Checkov checks with project-specific requirements
"""

from checkov.common.models.enums import Severities, CheckCategories
from checkov.common.models.consts import CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class AzureKeyVaultNetworkAcls(BaseResourceCheck):
    """
    Custom check to ensure Key Vault has proper network ACLs configured
    """
    def __init__(self):
        name = "Ensure Key Vault has restrictive network ACLs configured"
        id = "CKV_AZURE_CUSTOM_4"
        supported_resources = ['azurerm_key_vault']
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources,
                         severity=Severities.HIGH)

    def scan_resource_conf(self, conf):
        """
        Checks for network_acls configuration with proper restrictions
        """
        if 'network_acls' in conf:
            network_acls = conf['network_acls'][0]
            if isinstance(network_acls, dict):
                # Check default action is Deny
                if 'default_action' in network_acls:
                    if network_acls['default_action'][0] == 'Deny':
                        # Check if bypass is configured for Azure services
                        if 'bypass' in network_acls:
                            bypass_value = network_acls['bypass'][0]
                            if 'AzureServices' in bypass_value:
                                return CheckResult.PASSED
        return CheckResult.FAILED


class AzureKeyVaultAccessPolicy(BaseResourceCheck):
    """
    Custom check to ensure Key Vault access policies follow least privilege
    """
    def __init__(self):
        name = "Ensure Key Vault access policies follow least privilege principle"
        id = "CKV_AZURE_CUSTOM_5"
        supported_resources = ['azurerm_key_vault_access_policy']
        categories = [CheckCategories.IAM]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources,
                         severity=Severities.MEDIUM)

    def scan_resource_conf(self, conf):
        """
        Checks that access policies don't grant excessive permissions
        """
        excessive_permissions = ['*', 'all']
        
        # Check key permissions
        if 'key_permissions' in conf:
            key_perms = conf['key_permissions']
            if isinstance(key_perms, list):
                for perm in key_perms:
                    if isinstance(perm, list):
                        for p in perm:
                            if p.lower() in excessive_permissions:
                                return CheckResult.FAILED
                    elif perm.lower() in excessive_permissions:
                        return CheckResult.FAILED
        
        # Check secret permissions
        if 'secret_permissions' in conf:
            secret_perms = conf['secret_permissions']
            if isinstance(secret_perms, list):
                for perm in secret_perms:
                    if isinstance(perm, list):
                        for p in perm:
                            if p.lower() in excessive_permissions:
                                return CheckResult.FAILED
                    elif perm.lower() in excessive_permissions:
                        return CheckResult.FAILED
        
        # Check certificate permissions
        if 'certificate_permissions' in conf:
            cert_perms = conf['certificate_permissions']
            if isinstance(cert_perms, list):
                for perm in cert_perms:
                    if isinstance(perm, list):
                        for p in perm:
                            if p.lower() in excessive_permissions:
                                return CheckResult.FAILED
                    elif perm.lower() in excessive_permissions:
                        return CheckResult.FAILED
        
        return CheckResult.PASSED


class AzureKeyVaultRequiredTags(BaseResourceCheck):
    """
    Custom check to ensure Key Vault has required tags
    """
    def __init__(self):
        name = "Ensure Key Vault has required project tags"
        id = "CKV_AZURE_CUSTOM_6"
        supported_resources = ['azurerm_key_vault']
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources,
                         severity=Severities.LOW)

    def scan_resource_conf(self, conf):
        """
        Checks for required tags: deployed_via, owner, Team, Environment
        """
        required_tags = ['deployed_via', 'owner', 'Team', 'Environment']
        
        if 'tags' in conf:
            tags = conf['tags'][0]
            if isinstance(tags, dict):
                for required_tag in required_tags:
                    if required_tag not in tags:
                        return CheckResult.FAILED
                return CheckResult.PASSED
        return CheckResult.FAILED


# Register the checks
check = AzureKeyVaultNetworkAcls()
check = AzureKeyVaultAccessPolicy()
check = AzureKeyVaultRequiredTags()