# Install Git Hooks Script
# This script installs pre-commit hooks for Terraform security scanning

param(
    [switch]$Force = $false,
    [switch]$Verbose = $false
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

# Function to check if we're in a git repository
function Test-GitRepository {
    try {
        git rev-parse --git-dir | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Function to backup existing hook
function Backup-ExistingHook {
    param([string]$HookPath)
    
    if (Test-Path $HookPath) {
        $backupPath = "$HookPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $HookPath $backupPath
        Write-ColorOutput "Backed up existing hook to: $backupPath" "Yellow"
        return $true
    }
    return $false
}

# Function to install pre-commit hook
function Install-PreCommitHook {
    $sourceHook = "scripts/git/pre-commit"
    $targetHook = ".git/hooks/pre-commit"
    
    if (!(Test-Path $sourceHook)) {
        Write-ColorOutput "Source hook not found: $sourceHook" "Red"
        return $false
    }
    
    # Check if hook already exists
    if (Test-Path $targetHook) {
        if (!$Force) {
            Write-ColorOutput "Pre-commit hook already exists. Use -Force to overwrite." "Yellow"
            return $false
        } else {
            Backup-ExistingHook $targetHook | Out-Null
        }
    }
    
    try {
        # Copy the hook
        Copy-Item $sourceHook $targetHook -Force
        
        # Make it executable (on Unix-like systems)
        if ($IsLinux -or $IsMacOS) {
            chmod +x $targetHook
        }
        
        Write-ColorOutput "✅ Pre-commit hook installed successfully" "Green"
        return $true
    } catch {
        Write-ColorOutput "❌ Failed to install pre-commit hook: $_" "Red"
        return $false
    }
}

# Function to test hook installation
function Test-HookInstallation {
    $hookPath = ".git/hooks/pre-commit"
    
    if (!(Test-Path $hookPath)) {
        Write-ColorOutput "❌ Pre-commit hook not found" "Red"
        return $false
    }
    
    # Test if the hook is executable
    try {
        if ($IsWindows) {
            # On Windows, test by trying to read the file
            Get-Content $hookPath -TotalCount 1 | Out-Null
        } else {
            # On Unix-like systems, check if it's executable
            $permissions = stat -c "%a" $hookPath 2>/dev/null
            if ($permissions -match "^[0-9]*[1357]$") {
                Write-ColorOutput "✅ Hook is executable" "Green"
            } else {
                Write-ColorOutput "⚠️  Hook may not be executable" "Yellow"
            }
        }
        
        Write-ColorOutput "✅ Pre-commit hook is properly installed" "Green"
        return $true
    } catch {
        Write-ColorOutput "❌ Error testing hook installation: $_" "Red"
        return $false
    }
}

# Function to configure git settings
function Set-GitConfiguration {
    Write-ColorOutput "`n=== Configuring Git Settings ===" "Blue"
    
    try {
        # Set core.hooksPath if needed (optional)
        # git config core.hooksPath .git/hooks
        
        # Ensure proper line endings for hooks
        git config core.autocrlf false
        
        Write-ColorOutput "✅ Git configuration updated" "Green"
        return $true
    } catch {
        Write-ColorOutput "⚠️  Warning: Could not update git configuration: $_" "Yellow"
        return $false
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "`n=== Checking Prerequisites ===" "Blue"
    
    $allGood = $true
    
    # Check Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVersion = git --version
        Write-ColorOutput "✅ Git found: $gitVersion" "Green"
    } else {
        Write-ColorOutput "❌ Git not found" "Red"
        $allGood = $false
    }
    
    # Check PowerShell
    if ($PSVersionTable.PSVersion) {
        Write-ColorOutput "✅ PowerShell found: $($PSVersionTable.PSVersion)" "Green"
    } else {
        Write-ColorOutput "⚠️  PowerShell version detection failed" "Yellow"
    }
    
    # Check Terraform (optional)
    if (Get-Command terraform -ErrorAction SilentlyContinue) {
        $terraformVersion = terraform version | Select-Object -First 1
        Write-ColorOutput "✅ Terraform found: $terraformVersion" "Green"
    } else {
        Write-ColorOutput "⚠️  Terraform not found - install for full functionality" "Yellow"
    }
    
    # Check security tools (optional)
    $securityTools = @("checkov", "tfsec", "terrascan")
    $foundTools = @()
    
    foreach ($tool in $securityTools) {
        if (Get-Command $tool -ErrorAction SilentlyContinue) {
            $foundTools += $tool
        }
    }
    
    if ($foundTools.Count -gt 0) {
        Write-ColorOutput "✅ Security tools found: $($foundTools -join ', ')" "Green"
    } else {
        Write-ColorOutput "⚠️  No security tools found - install for enhanced scanning" "Yellow"
        Write-ColorOutput "   Run scripts/security/install-all-sast-tools.ps1 to install" "Gray"
    }
    
    return $allGood
}

# Function to show usage instructions
function Show-Usage {
    Write-ColorOutput "`n=== Usage Instructions ===" "Cyan"
    Write-ColorOutput "The pre-commit hook will now run automatically before each commit." "White"
    Write-ColorOutput ""
    Write-ColorOutput "Hook features:" "Yellow"
    Write-ColorOutput "  • Terraform format checking" "Gray"
    Write-ColorOutput "  • Terraform validation" "Gray"
    Write-ColorOutput "  • Sensitive data detection" "Gray"
    Write-ColorOutput "  • File size limits" "Gray"
    Write-ColorOutput "  • Quick security scanning (if tools available)" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "To skip hooks temporarily:" "Yellow"
    Write-ColorOutput "  git commit --no-verify" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "To run hook manually:" "Yellow"
    Write-ColorOutput "  .git/hooks/pre-commit" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "To uninstall hooks:" "Yellow"
    Write-ColorOutput "  scripts/git/uninstall-hooks.ps1" "Gray"
}

# Main execution
Write-ColorOutput "🔧 Installing Git Pre-commit Hooks" "Cyan"
Write-ColorOutput "===================================" "Cyan"

# Check if we're in a git repository
if (!(Test-GitRepository)) {
    Write-ColorOutput "❌ Not in a git repository. Please run this script from the project root." "Red"
    exit 1
}

# Check prerequisites
if (!(Test-Prerequisites)) {
    Write-ColorOutput "`n❌ Prerequisites check failed. Please install required tools." "Red"
    exit 1
}

# Configure git settings
Set-GitConfiguration | Out-Null

# Install hooks
Write-ColorOutput "`n=== Installing Hooks ===" "Blue"

$success = $true

# Install pre-commit hook
if (!(Install-PreCommitHook)) {
    $success = $false
}

# Test installation
if ($success) {
    Write-ColorOutput "`n=== Testing Installation ===" "Blue"
    if (!(Test-HookInstallation)) {
        $success = $false
    }
}

# Show results
Write-ColorOutput "`n=== Installation Summary ===" "Cyan"

if ($success) {
    Write-ColorOutput "✅ Git hooks installed successfully!" "Green"
    Show-Usage
} else {
    Write-ColorOutput "❌ Hook installation failed. Please check the errors above." "Red"
    exit 1
}

Write-ColorOutput "`nFor more information, see: scripts/git/README.md" "Gray"