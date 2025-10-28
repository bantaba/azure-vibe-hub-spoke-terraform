# Security Scan Launcher
# Simple entry point for security scanning with guided workflow

param(
    [string]$Mode = "interactive"  # Options: interactive, quick, comprehensive, remediation
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "Cyan" = [ConsoleColor]::Cyan
        "Magenta" = [ConsoleColor]::Magenta
        "Gray" = [ConsoleColor]::Gray
        "White" = [ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

# Function to display main menu
function Show-MainMenu {
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                Security Scan Launcher                       ║" "Cyan"
    Write-ColorOutput "║            Terraform Security Enhancement Suite             ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-ColorOutput ""
    
    Write-ColorOutput "Select an option:" "Yellow"
    Write-ColorOutput ""
    Write-ColorOutput "1. 🔍 Quick Security Scan" "White"
    Write-ColorOutput "   Run all SAST tools with summary output" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "2. 📊 Comprehensive Security Assessment" "White"
    Write-ColorOutput "   Detailed scan with full reporting and remediation guidance" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "3. 🔧 Remediation Assistant" "White"
    Write-ColorOutput "   Interactive tool for fixing security issues" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "4. 📈 Generate Security Report" "White"
    Write-ColorOutput "   Create detailed HTML/Markdown reports from existing scans" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "5. ⚙️  Install/Update SAST Tools" "White"
    Write-ColorOutput "   Install or update Checkov, TFSec, and Terrascan" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "6. 📚 View Documentation" "White"
    Write-ColorOutput "   Open security scripts documentation" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "7. 🚪 Exit" "White"
    Write-ColorOutput ""
    
    Write-ColorOutput "Enter your choice (1-7): " "Cyan" -NoNewline
    return Read-Host
}

# Function to run quick scan
function Invoke-QuickScan {
    Write-ColorOutput "`n🔍 Starting Quick Security Scan..." "Blue"
    Write-ColorOutput "This will run all SAST tools with summary output.`n" "Gray"
    
    try {
        & "$script:ScriptPath\local-security-scan.ps1" -OutputFormat summary -Interactive:$false
        
        Write-ColorOutput "`n✅ Quick scan completed!" "Green"
        Write-ColorOutput "Check security/reports/ for detailed results." "Yellow"
        
        Write-ColorOutput "`nWould you like to:" "Cyan"
        Write-ColorOutput "1. View remediation guidance" "White"
        Write-ColorOutput "2. Generate HTML report" "White"
        Write-ColorOutput "3. Return to main menu" "White"
        
        Write-ColorOutput "`nEnter choice (1-3): " "Cyan" -NoNewline
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Invoke-RemediationAssistant }
            "2" { Invoke-ReportGeneration }
            "3" { return }
        }
    } catch {
        Write-ColorOutput "Error during quick scan: $_" "Red"
        Read-Host "`nPress Enter to continue"
    }
}

# Function to run comprehensive assessment
function Invoke-ComprehensiveAssessment {
    Write-ColorOutput "`n📊 Starting Comprehensive Security Assessment..." "Blue"
    Write-ColorOutput "This will run detailed scans with full reporting and remediation guidance.`n" "Gray"
    
    try {
        # Run detailed scan
        Write-ColorOutput "Step 1/3: Running detailed security scan..." "Yellow"
        & "$script:ScriptPath\local-security-scan.ps1" -OutputFormat detailed -ShowRemediation -GenerateBaseline
        
        # Generate HTML report
        Write-ColorOutput "`nStep 2/3: Generating comprehensive report..." "Yellow"
        & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat html -IncludeRemediation
        
        # Launch remediation assistant
        Write-ColorOutput "`nStep 3/3: Launching remediation assistant..." "Yellow"
        Write-ColorOutput "Press Enter to continue to remediation guidance, or Ctrl+C to exit..." "Cyan"
        Read-Host
        
        & "$script:ScriptPath\remediation-assistant.ps1"
        
        Write-ColorOutput "`n✅ Comprehensive assessment completed!" "Green"
    } catch {
        Write-ColorOutput "Error during comprehensive assessment: $_" "Red"
        Read-Host "`nPress Enter to continue"
    }
}

# Function to run remediation assistant
function Invoke-RemediationAssistant {
    Write-ColorOutput "`n🔧 Launching Remediation Assistant..." "Blue"
    Write-ColorOutput "This will help you fix identified security issues.`n" "Gray"
    
    try {
        & "$script:ScriptPath\remediation-assistant.ps1"
    } catch {
        Write-ColorOutput "Error launching remediation assistant: $_" "Red"
        Read-Host "`nPress Enter to continue"
    }
}

# Function to generate reports
function Invoke-ReportGeneration {
    Write-ColorOutput "`n📈 Security Report Generation..." "Blue"
    Write-ColorOutput ""
    
    Write-ColorOutput "Select report format:" "Yellow"
    Write-ColorOutput "1. HTML (Interactive web report)" "White"
    Write-ColorOutput "2. Markdown (Documentation format)" "White"
    Write-ColorOutput "3. JSON (Machine readable)" "White"
    Write-ColorOutput "4. All formats" "White"
    
    Write-ColorOutput "`nEnter choice (1-4): " "Cyan" -NoNewline
    $choice = Read-Host
    
    try {
        switch ($choice) {
            "1" {
                & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat html -OpenReport
            }
            "2" {
                & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat markdown
            }
            "3" {
                & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat json
            }
            "4" {
                Write-ColorOutput "`nGenerating all report formats..." "Yellow"
                & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat html
                & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat markdown
                & "$script:ScriptPath\generate-security-report.ps1" -ReportFormat json
            }
            default {
                Write-ColorOutput "Invalid choice." "Red"
                return
            }
        }
        
        Write-ColorOutput "`n✅ Report generation completed!" "Green"
        Read-Host "`nPress Enter to continue"
    } catch {
        Write-ColorOutput "Error generating reports: $_" "Red"
        Read-Host "`nPress Enter to continue"
    }
}

# Function to install/update tools
function Invoke-ToolInstallation {
    Write-ColorOutput "`n⚙️  SAST Tools Installation/Update..." "Blue"
    Write-ColorOutput ""
    
    Write-ColorOutput "This will install or update:" "Yellow"
    Write-ColorOutput "• Checkov (Infrastructure as Code security scanner)" "Gray"
    Write-ColorOutput "• TFSec (Terraform security scanner)" "Gray"
    Write-ColorOutput "• Terrascan (Policy as Code security validation)" "Gray"
    Write-ColorOutput ""
    
    Write-ColorOutput "Continue with installation? (y/n): " "Cyan" -NoNewline
    $response = Read-Host
    
    if ($response -eq "y" -or $response -eq "yes") {
        try {
            & "$script:ScriptPath\install-all-sast-tools.ps1"
            Write-ColorOutput "`n✅ Tool installation completed!" "Green"
        } catch {
            Write-ColorOutput "Error during tool installation: $_" "Red"
        }
    } else {
        Write-ColorOutput "Installation cancelled." "Yellow"
    }
    
    Read-Host "`nPress Enter to continue"
}

# Function to view documentation
function Show-Documentation {
    Write-ColorOutput "`n📚 Security Scripts Documentation" "Blue"
    Write-ColorOutput ""
    
    $readmePath = "$script:ScriptPath\README.md"
    
    if (Test-Path $readmePath) {
        Write-ColorOutput "Opening documentation..." "Yellow"
        try {
            Start-Process $readmePath
            Write-ColorOutput "Documentation opened in default application." "Green"
        } catch {
            Write-ColorOutput "Could not open documentation automatically." "Yellow"
            Write-ColorOutput "Please open manually: $readmePath" "Gray"
        }
    } else {
        Write-ColorOutput "Documentation file not found: $readmePath" "Red"
    }
    
    Write-ColorOutput "`nQuick Reference:" "Cyan"
    Write-ColorOutput "• local-security-scan.ps1 - Enhanced local scanning" "Gray"
    Write-ColorOutput "• generate-security-report.ps1 - Report generation" "Gray"
    Write-ColorOutput "• remediation-assistant.ps1 - Interactive remediation" "Gray"
    Write-ColorOutput "• install-all-sast-tools.ps1 - Tool installation" "Gray"
    
    Read-Host "`nPress Enter to continue"
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." "Blue"
    
    $issues = @()
    
    # Check if source directory exists
    if (!(Test-Path "src/")) {
        $issues += "Source directory 'src/' not found"
    }
    
    # Check if reports directory exists or can be created
    if (!(Test-Path "security/reports/")) {
        try {
            New-Item -ItemType Directory -Path "security/reports/" -Force | Out-Null
            Write-ColorOutput "Created reports directory" "Yellow"
        } catch {
            $issues += "Cannot create reports directory"
        }
    }
    
    # Check PowerShell execution policy
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        $issues += "PowerShell execution policy is Restricted. Run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    }
    
    if ($issues.Count -gt 0) {
        Write-ColorOutput "`nPrerequisite issues found:" "Red"
        foreach ($issue in $issues) {
            Write-ColorOutput "  • $issue" "Red"
        }
        Write-ColorOutput "`nPlease resolve these issues before continuing." "Yellow"
        return $false
    }
    
    Write-ColorOutput "Prerequisites check passed ✓" "Green"
    return $true
}

# Main execution function
function Start-SecurityLauncher {
    # Check prerequisites
    if (!(Test-Prerequisites)) {
        Read-Host "`nPress Enter to exit"
        exit 1
    }
    
    # Handle non-interactive modes
    switch ($Mode.ToLower()) {
        "quick" {
            Invoke-QuickScan
            return
        }
        "comprehensive" {
            Invoke-ComprehensiveAssessment
            return
        }
        "remediation" {
            Invoke-RemediationAssistant
            return
        }
    }
    
    # Interactive mode
    while ($true) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            "1" {
                Invoke-QuickScan
            }
            "2" {
                Invoke-ComprehensiveAssessment
            }
            "3" {
                Invoke-RemediationAssistant
            }
            "4" {
                Invoke-ReportGeneration
            }
            "5" {
                Invoke-ToolInstallation
            }
            "6" {
                Show-Documentation
            }
            "7" {
                Write-ColorOutput "`nThank you for using the Security Scan Launcher!" "Green"
                Write-ColorOutput "Stay secure! 🛡️" "Cyan"
                exit 0
            }
            default {
                Write-ColorOutput "`nInvalid choice. Please select 1-7." "Red"
                Start-Sleep 2
            }
        }
    }
}

# Execute main function
Start-SecurityLauncher