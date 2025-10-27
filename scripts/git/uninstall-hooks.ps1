# Uninstall Git Hooks Script
# This script removes installed git hooks

param(
    [switch]$Force = $false,
    [switch]$KeepBackups = $false
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

# Function to remove hook
function Remove-Hook {
    param([string]$HookName)
    
    $hookPath = ".git/hooks/$HookName"
    
    if (!(Test-Path $hookPath)) {
        Write-ColorOutput "Hook not found: $HookName" "Yellow"
        return $true
    }
    
    try {
        Remove-Item $hookPath -Force
        Write-ColorOutput "✅ Removed hook: $HookName" "Green"
        return $true
    } catch {
        Write-ColorOutput "❌ Failed to remove hook $HookName`: $_" "Red"
        return $false
    }
}

# Function to restore backup
function Restore-Backup {
    param([string]$HookName)
    
    $hookPath = ".git/hooks/$HookName"
    $backupPattern = "$hookPath.backup.*"
    
    $backups = Get-ChildItem -Path ".git/hooks/" -Filter "$HookName.backup.*" -ErrorAction SilentlyContinue
    
    if ($backups.Count -eq 0) {
        return $false
    }
    
    # Get the most recent backup
    $latestBackup = $backups | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    try {
        Copy-Item $latestBackup.FullName $hookPath -Force
        Write-ColorOutput "✅ Restored backup: $($latestBackup.Name) -> $HookName" "Green"
        return $true
    } catch {
        Write-ColorOutput "❌ Failed to restore backup: $_" "Red"
        return $false
    }
}

# Function to clean up backups
function Remove-Backups {
    param([string]$HookName)
    
    $backups = Get-ChildItem -Path ".git/hooks/" -Filter "$HookName.backup.*" -ErrorAction SilentlyContinue
    
    if ($backups.Count -eq 0) {
        return $true
    }
    
    $success = $true
    foreach ($backup in $backups) {
        try {
            Remove-Item $backup.FullName -Force
            Write-ColorOutput "Removed backup: $($backup.Name)" "Gray"
        } catch {
            Write-ColorOutput "Warning: Could not remove backup $($backup.Name): $_" "Yellow"
            $success = $false
        }
    }
    
    return $success
}

# Function to confirm action
function Confirm-Action {
    param([string]$Message)
    
    if ($Force) {
        return $true
    }
    
    Write-ColorOutput $Message "Yellow"
    $response = Read-Host "Continue? (y/N)"
    return $response -match "^[Yy]"
}

# Main execution
Write-ColorOutput "🗑️  Uninstalling Git Pre-commit Hooks" "Cyan"
Write-ColorOutput "=====================================" "Cyan"

# Check if we're in a git repository
if (!(Test-GitRepository)) {
    Write-ColorOutput "❌ Not in a git repository. Please run this script from the project root." "Red"
    exit 1
}

# List of hooks to uninstall
$hooks = @("pre-commit")

# Check what's installed
Write-ColorOutput "`n=== Checking Installed Hooks ===" "Blue"
$installedHooks = @()
$hasBackups = @()

foreach ($hook in $hooks) {
    $hookPath = ".git/hooks/$hook"
    if (Test-Path $hookPath) {
        $installedHooks += $hook
        Write-ColorOutput "Found: $hook" "Yellow"
    }
    
    $backups = Get-ChildItem -Path ".git/hooks/" -Filter "$hook.backup.*" -ErrorAction SilentlyContinue
    if ($backups.Count -gt 0) {
        $hasBackups += $hook
        Write-ColorOutput "Backups found for: $hook ($($backups.Count) files)" "Gray"
    }
}

if ($installedHooks.Count -eq 0 -and $hasBackups.Count -eq 0) {
    Write-ColorOutput "No hooks or backups found to uninstall." "Green"
    exit 0
}

# Confirm uninstallation
if ($installedHooks.Count -gt 0) {
    $hookList = $installedHooks -join ", "
    if (!(Confirm-Action "This will remove the following hooks: $hookList")) {
        Write-ColorOutput "Uninstallation cancelled." "Yellow"
        exit 0
    }
}

# Remove hooks
Write-ColorOutput "`n=== Removing Hooks ===" "Blue"
$success = $true

foreach ($hook in $installedHooks) {
    # Check if we should restore backup
    $backups = Get-ChildItem -Path ".git/hooks/" -Filter "$hook.backup.*" -ErrorAction SilentlyContinue
    
    if ($backups.Count -gt 0) {
        Write-ColorOutput "Found backup(s) for $hook" "Gray"
        if (Confirm-Action "Restore original $hook from backup?") {
            if (!(Restore-Backup $hook)) {
                $success = $false
            }
        } else {
            if (!(Remove-Hook $hook)) {
                $success = $false
            }
        }
    } else {
        if (!(Remove-Hook $hook)) {
            $success = $false
        }
    }
}

# Handle backups
if ($hasBackups.Count -gt 0 -and !$KeepBackups) {
    Write-ColorOutput "`n=== Cleaning Up Backups ===" "Blue"
    
    if (Confirm-Action "Remove backup files?") {
        foreach ($hook in $hasBackups) {
            Remove-Backups $hook | Out-Null
        }
    } else {
        Write-ColorOutput "Keeping backup files (use -KeepBackups to skip this prompt)" "Gray"
    }
}

# Summary
Write-ColorOutput "`n=== Uninstallation Summary ===" "Cyan"

if ($success) {
    Write-ColorOutput "✅ Git hooks uninstalled successfully!" "Green"
    
    if ($installedHooks.Count -gt 0) {
        Write-ColorOutput "`nRemoved hooks:" "White"
        foreach ($hook in $installedHooks) {
            Write-ColorOutput "  • $hook" "Gray"
        }
    }
    
    Write-ColorOutput "`nTo reinstall hooks, run: scripts/git/install-hooks.ps1" "Gray"
} else {
    Write-ColorOutput "❌ Some operations failed. Please check the errors above." "Red"
    exit 1
}