"""
Custom Checkov policies for Azure Storage Account security
These policies extend the default Checkov checks with project-specific requirements
"""

from checkov.common.models.enums import Severities, CheckCategories
from checkov.common.models.consts import CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class AzureStorageAccountCustomEncryption(BaseResourceCheck):
    """
    Custom check to ensure Storage Account uses customer-managed keys for encryption
    """
    def __init__(self):
        name = "Ensure Storage Account uses customer-managed keys for encryption"
        id = "CKV_AZURE_CUSTOM_1"
        supported_resources = ['azurerm_storage_account']
        categories = [CheckCategories.ENCRYPTION]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources,
                         severity=Severities.HIGH)

    def scan_resource_conf(self, conf):
        """
        Looks for customer_managed_key configuration in storage account
        """
        if 'customer_managed_key' in conf:
            cmk_config = conf['customer_managed_key'][0]
            if isinstance(cmk_config, dict):
                if 'key_vault_key_id' in cmk_config and cmk_config['key_vault_key_id']:
                    return CheckResult.PASSED
        return CheckResult.FAILED


class AzureStorageAccountNetworkRules(BaseResourceCheck):
    """
    Custom check to ensure Storage Account has proper network access rules
    """
    def __init__(self):
        name = "Ensure Storage Account has restrictive network access rules configured"
        id = "CKV_AZURE_CUSTOM_2"
        supported_resources = ['azurerm_storage_account']
        categories = [CheckCategories.NETWORKING]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources,
                         severity=Severities.MEDIUM)

    def scan_resource_conf(self, conf):
        """
        Checks for network_rules configuration with proper restrictions
        """
        if 'network_rules' in conf:
            network_rules = conf['network_rules'][0]
            if isinstance(network_rules, dict):
                # Check default action is Deny
                if 'default_action' in network_rules:
                    if network_rules['default_action'][0] == 'Deny':
                        # Check if there are specific allowed IPs or subnets
                        has_restrictions = (
                            ('ip_rules' in network_rules and network_rules['ip_rules']) or
                            ('virtual_network_subnet_ids' in network_rules and network_rules['virtual_network_subnet_ids'])
                        )
                        if has_restrictions:
                            return CheckResult.PASSED
        return CheckResult.FAILED


class AzureStorageAccountTags(BaseResourceCheck):
    """
    Custom check to ensure Storage Account has required tags
    """
    def __init__(self):
        name = "Ensure Storage Account has required project tags"
        id = "CKV_AZURE_CUSTOM_3"
        supported_resources = ['azurerm_storage_account']
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
check = AzureStorageAccountCustomEncryption()
check = AzureStorageAccountNetworkRules()
check = AzureStorageAccountTags()