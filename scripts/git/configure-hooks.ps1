# Configure Git Hooks Script
# This script allows customization of git hook behavior

param(
    [switch]$Interactive = $false,
    [switch]$ShowCurrent = $false,
    [string]$ConfigFile = ".git/hooks/config.json"
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color.ToLower()) {
        "red" { Write-Host $Message -ForegroundColor Red }
        "green" { Write-Host $Message -ForegroundColor Green }
        "yellow" { Write-Host $Message -ForegroundColor Yellow }
        "blue" { Write-Host $Message -ForegroundColor Blue }
        "cyan" { Write-Host $Message -ForegroundColor Cyan }
        "magenta" { Write-Host $Message -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

# Default configuration
$defaultConfig = @{
    preCommit = @{
        enabled = $true
        skipSecurity = $false
        skipFormat = $false
        skipValidation = $false
        skipSensitiveData = $false
        skipFileSize = $false
        verbose = $false
        maxFileSize = 1048576  # 1MB in bytes
        securityTools = @{
            checkov = @{
                enabled = $true
                timeout = 60
                args = @("--quiet", "--compact")
            }
            tfsec = @{
                enabled = $true
                timeout = 30
                args = @("--no-color", "--concise-output")
            }
            terrascan = @{
                enabled = $true
                timeout = 60
                args = @("--non-recursive", "--verbose")
            }
        }
        sensitivePatterns = @(
            @{ pattern = "password\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded password" }
            @{ pattern = "secret\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded secret" }
            @{ pattern = "api_key\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded API key" }
            @{ pattern = "access_key\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded access key" }
            @{ pattern = "private_key\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded private key" }
            @{ pattern = "token\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded token" }
            @{ pattern = "connection_string\s*=\s*[`"'][^`"']+[`"']"; description = "Hardcoded connection string" }
        )
    }
    metadata = @{
        version = "1.0.0"
        created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        lastModified = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
}

# Function to load configuration
function Get-HookConfiguration {
    if (Test-Path $ConfigFile) {
        try {
            $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json -AsHashtable
            Write-ColorOutput "✅ Loaded configuration from: $ConfigFile" "Green"
            return $config
        } catch {
            Write-ColorOutput "⚠️  Error loading config file, using defaults: $_" "Yellow"
            return $defaultConfig
        }
    } else {
        Write-ColorOutput "No configuration file found, using defaults" "Gray"
        return $defaultConfig
    }
}

# Function to save configuration
function Set-HookConfiguration {
    param([hashtable]$Config)
    
    try {
        # Update metadata
        $Config.metadata.lastModified = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        
        # Ensure directory exists
        $configDir = Split-Path $ConfigFile -Parent
        if (!(Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Save configuration
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Encoding UTF8
        Write-ColorOutput "✅ Configuration saved to: $ConfigFile" "Green"
        return $true
    } catch {
        Write-ColorOutput "❌ Error saving configuration: $_" "Red"
        return $false
    }
}

# Function to display current configuration
function Show-Configuration {
    param([hashtable]$Config)
    
    Write-ColorOutput "`n=== Current Hook Configuration ===" "Cyan"
    Write-ColorOutput "Configuration file: $ConfigFile" "Gray"
    Write-ColorOutput "Last modified: $($Config.metadata.lastModified)" "Gray"
    
    Write-ColorOutput "`nPre-commit Hook Settings:" "Yellow"
    Write-ColorOutput "  Enabled: $($Config.preCommit.enabled)" $(if ($Config.preCommit.enabled) { "Green" } else { "Red" })
    Write-ColorOutput "  Skip Security Scan: $($Config.preCommit.skipSecurity)" $(if ($Config.preCommit.skipSecurity) { "Yellow" } else { "Green" })
    Write-ColorOutput "  Skip Format Check: $($Config.preCommit.skipFormat)" $(if ($Config.preCommit.skipFormat) { "Yellow" } else { "Green" })
    Write-ColorOutput "  Skip Validation: $($Config.preCommit.skipValidation)" $(if ($Config.preCommit.skipValidation) { "Yellow" } else { "Green" })
    Write-ColorOutput "  Skip Sensitive Data Check: $($Config.preCommit.skipSensitiveData)" $(if ($Config.preCommit.skipSensitiveData) { "Yellow" } else { "Green" })
    Write-ColorOutput "  Skip File Size Check: $($Config.preCommit.skipFileSize)" $(if ($Config.preCommit.skipFileSize) { "Yellow" } else { "Green" })
    Write-ColorOutput "  Verbose Output: $($Config.preCommit.verbose)" $(if ($Config.preCommit.verbose) { "Yellow" } else { "Gray" })
    Write-ColorOutput "  Max File Size: $([math]::Round($Config.preCommit.maxFileSize / 1MB, 2)) MB" "Gray"
    
    Write-ColorOutput "`nSecurity Tools:" "Yellow"
    foreach ($tool in $Config.preCommit.securityTools.Keys) {
        $toolConfig = $Config.preCommit.securityTools[$tool]
        $status = if ($toolConfig.enabled) { "Enabled" } else { "Disabled" }
        $color = if ($toolConfig.enabled) { "Green" } else { "Red" }
        Write-ColorOutput "  $tool`: $status (timeout: $($toolConfig.timeout)s)" $color
    }
    
    Write-ColorOutput "`nSensitive Data Patterns: $($Config.preCommit.sensitivePatterns.Count) patterns configured" "Gray"
}

# Function for interactive configuration
function Start-InteractiveConfiguration {
    param([hashtable]$Config)
    
    Write-ColorOutput "`n🔧 Interactive Hook Configuration" "Cyan"
    Write-ColorOutput "==================================" "Cyan"
    
    # Pre-commit hook settings
    Write-ColorOutput "`n--- Pre-commit Hook Settings ---" "Yellow"
    
    $response = Read-Host "Enable pre-commit hook? (Y/n) [current: $($Config.preCommit.enabled)]"
    if ($response -match "^[Nn]") {
        $Config.preCommit.enabled = $false
    } elseif ($response -match "^[Yy]" -or $response -eq "") {
        $Config.preCommit.enabled = $true
    }
    
    if ($Config.preCommit.enabled) {
        $response = Read-Host "Skip security scanning? (y/N) [current: $($Config.preCommit.skipSecurity)]"
        $Config.preCommit.skipSecurity = $response -match "^[Yy]"
        
        $response = Read-Host "Skip format checking? (y/N) [current: $($Config.preCommit.skipFormat)]"
        $Config.preCommit.skipFormat = $response -match "^[Yy]"
        
        $response = Read-Host "Skip validation? (y/N) [current: $($Config.preCommit.skipValidation)]"
        $Config.preCommit.skipValidation = $response -match "^[Yy]"
        
        $response = Read-Host "Skip sensitive data check? (y/N) [current: $($Config.preCommit.skipSensitiveData)]"
        $Config.preCommit.skipSensitiveData = $response -match "^[Yy]"
        
        $response = Read-Host "Enable verbose output? (y/N) [current: $($Config.preCommit.verbose)]"
        $Config.preCommit.verbose = $response -match "^[Yy]"
        
        # Security tools configuration
        if (!$Config.preCommit.skipSecurity) {
            Write-ColorOutput "`n--- Security Tools Configuration ---" "Yellow"
            
            foreach ($tool in $Config.preCommit.securityTools.Keys) {
                $toolConfig = $Config.preCommit.securityTools[$tool]
                $response = Read-Host "Enable $tool? (Y/n) [current: $($toolConfig.enabled)]"
                
                if ($response -match "^[Nn]") {
                    $toolConfig.enabled = $false
                } elseif ($response -match "^[Yy]" -or $response -eq "") {
                    $toolConfig.enabled = $true
                    
                    $response = Read-Host "Timeout for $tool (seconds) [current: $($toolConfig.timeout)]"
                    if ($response -match "^\d+$") {
                        $toolConfig.timeout = [int]$response
                    }
                }
            }
        }
        
        # File size limit
        Write-ColorOutput "`n--- File Size Configuration ---" "Yellow"
        $currentSizeMB = [math]::Round($Config.preCommit.maxFileSize / 1MB, 2)
        $response = Read-Host "Maximum file size in MB [current: $currentSizeMB]"
        if ($response -match "^\d+(\.\d+)?$") {
            $Config.preCommit.maxFileSize = [int]([double]$response * 1MB)
        }
    }
    
    return $Config
}

# Function to reset to defaults
function Reset-Configuration {
    Write-ColorOutput "Resetting configuration to defaults..." "Yellow"
    return $defaultConfig.Clone()
}

# Function to validate configuration
function Test-Configuration {
    param([hashtable]$Config)
    
    $isValid = $true
    
    # Check required sections
    if (!$Config.ContainsKey("preCommit")) {
        Write-ColorOutput "❌ Missing preCommit section" "Red"
        $isValid = $false
    }
    
    if (!$Config.ContainsKey("metadata")) {
        Write-ColorOutput "❌ Missing metadata section" "Red"
        $isValid = $false
    }
    
    # Validate security tools
    if ($Config.preCommit.securityTools) {
        foreach ($tool in $Config.preCommit.securityTools.Keys) {
            $toolConfig = $Config.preCommit.securityTools[$tool]
            if (!$toolConfig.ContainsKey("enabled") -or !$toolConfig.ContainsKey("timeout")) {
                Write-ColorOutput "❌ Invalid configuration for tool: $tool" "Red"
                $isValid = $false
            }
        }
    }
    
    if ($isValid) {
        Write-ColorOutput "✅ Configuration is valid" "Green"
    }
    
    return $isValid
}

# Main execution
Write-ColorOutput "⚙️  Git Hooks Configuration" "Cyan"
Write-ColorOutput "===========================" "Cyan"

# Load current configuration
$config = Get-HookConfiguration

# Handle command line options
if ($ShowCurrent) {
    Show-Configuration $config
    exit 0
}

if ($Interactive) {
    $config = Start-InteractiveConfiguration $config
    
    Write-ColorOutput "`n=== Configuration Summary ===" "Cyan"
    Show-Configuration $config
    
    $response = Read-Host "`nSave this configuration? (Y/n)"
    if ($response -notmatch "^[Nn]") {
        if (Set-HookConfiguration $config) {
            Write-ColorOutput "✅ Configuration saved successfully!" "Green"
        } else {
            Write-ColorOutput "❌ Failed to save configuration" "Red"
            exit 1
        }
    } else {
        Write-ColorOutput "Configuration not saved" "Yellow"
    }
} else {
    # Show current configuration and options
    Show-Configuration $config
    
    Write-ColorOutput "`n=== Configuration Options ===" "Cyan"
    Write-ColorOutput "Run with -Interactive for guided configuration" "Gray"
    Write-ColorOutput "Run with -ShowCurrent to display current settings only" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "Manual configuration:" "Yellow"
    Write-ColorOutput "  Edit: $ConfigFile" "Gray"
    Write-ColorOutput "  Reset: Remove the config file to use defaults" "Gray"
}

Write-ColorOutput "`nConfiguration file location: $ConfigFile" "Gray"