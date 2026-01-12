<#
.SYNOPSIS
    Common utility functions for GA-TemplateApp

.DESCRIPTION
    Provides shared functions for logging, output formatting, path validation,
    and other common operations used across the application.
#>

#region Output Functions

function Write-Success {
    <#
    .SYNOPSIS
        Writes a success message in green
    #>
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Failure {
    <#
    .SYNOPSIS
        Writes an error message in red
    #>
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    <#
    .SYNOPSIS
        Writes an info message in cyan
    #>
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-AppWarning {
    <#
    .SYNOPSIS
        Writes a warning message in yellow
    #>
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-SectionHeader {
    <#
    .SYNOPSIS
        Writes a formatted section header
    #>
    param([string]$Title)
    $separator = '=' * 60
    Write-Host ''
    Write-Host $separator -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host $separator -ForegroundColor Cyan
    Write-Host ''
}

function Write-StepProgress {
    <#
    .SYNOPSIS
        Writes a step progress indicator
    #>
    param(
        [int]$Step,
        [int]$Total,
        [string]$Message
    )
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Yellow
}

#endregion

#region Path Validation

function Test-ValidPath {
    <#
    .SYNOPSIS
        Validates a file or directory path

    .PARAMETER Path
        The path to validate

    .PARAMETER Type
        Expected type: File or Directory

    .PARAMETER MustExist
        If true, path must exist

    .PARAMETER CreateIfMissing
        If true, create directory if missing (only for directories)

    .OUTPUTS
        Boolean indicating if path is valid
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('File', 'Directory')]
        [string]$Type = 'File',

        [switch]$MustExist,

        [switch]$CreateIfMissing
    )

    # Check for invalid characters
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    foreach ($char in $invalidChars) {
        if ($Path.Contains($char)) {
            return $false
        }
    }

    if ($MustExist) {
        if ($Type -eq 'File') {
            return Test-Path -Path $Path -PathType Leaf
        } else {
            return Test-Path -Path $Path -PathType Container
        }
    }

    if ($CreateIfMissing -and $Type -eq 'Directory') {
        if (-not (Test-Path $Path)) {
            try {
                New-Item -Path $Path -ItemType Directory -Force | Out-Null
            } catch {
                return $false
            }
        }
    }

    return $true
}

function Get-SafePath {
    <#
    .SYNOPSIS
        Escapes a path for safe use in commands

    .PARAMETER Path
        The path to escape

    .OUTPUTS
        Escaped path string
    #>
    param([string]$Path)

    # Wrap in quotes if contains spaces
    if ($Path -match '\s') {
        return "`"$Path`""
    }
    return $Path
}

#endregion

#region Configuration

function Get-AppConfig {
    <#
    .SYNOPSIS
        Loads application configuration from JSON file

    .PARAMETER ConfigPath
        Path to configuration file

    .OUTPUTS
        Configuration hashtable
    #>
    param(
        [string]$ConfigPath = ".\config\app-config.json"
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-AppWarning "Configuration file not found: $ConfigPath"
        return @{}
    }

    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
        return $config
    } catch {
        Write-Failure "Failed to load configuration: $_"
        return @{}
    }
}

function Save-AppConfig {
    <#
    .SYNOPSIS
        Saves application configuration to JSON file

    .PARAMETER Config
        Configuration hashtable to save

    .PARAMETER ConfigPath
        Path to configuration file
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [string]$ConfigPath = ".\config\app-config.json"
    )

    try {
        $configDir = Split-Path $ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        }

        $Config | ConvertTo-Json -Depth 10 | Out-File $ConfigPath -Encoding UTF8
        Write-Success "Configuration saved to $ConfigPath"
    } catch {
        Write-Failure "Failed to save configuration: $_"
    }
}

#endregion

#region Logging

$Script:LogPath = $null

function Start-AppLogging {
    <#
    .SYNOPSIS
        Starts logging to a file

    .PARAMETER LogPath
        Path for log file
    #>
    param(
        [string]$LogPath = ".\logs\app-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    )

    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $Script:LogPath = $LogPath
    Write-Log "Logging started"
}

function Stop-AppLogging {
    <#
    .SYNOPSIS
        Stops logging and closes log file
    #>
    Write-Log "Logging stopped"
    $Script:LogPath = $null
}

function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to the log file

    .PARAMETER Message
        Message to log

    .PARAMETER Level
        Log level: Info, Warning, Error, Debug
    #>
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )

    if (-not $Script:LogPath) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"

    try {
        Add-Content -Path $Script:LogPath -Value $logEntry
    } catch {
        # Silently fail if logging fails
    }
}

#endregion

#region Privilege Checking

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Tests if current session has administrator privileges

    .OUTPUTS
        Boolean indicating admin status
    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-AdminPrivileges {
    <#
    .SYNOPSIS
        Throws an error if not running as administrator
    #>
    if (-not (Test-AdminPrivileges)) {
        throw "This operation requires administrator privileges. Please run as Administrator."
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    # Output
    'Write-Success',
    'Write-Failure',
    'Write-Info',
    'Write-AppWarning',
    'Write-SectionHeader',
    'Write-StepProgress',

    # Path
    'Test-ValidPath',
    'Get-SafePath',

    # Config
    'Get-AppConfig',
    'Save-AppConfig',

    # Logging
    'Start-AppLogging',
    'Stop-AppLogging',
    'Write-Log',

    # Privileges
    'Test-AdminPrivileges',
    'Assert-AdminPrivileges'
)
