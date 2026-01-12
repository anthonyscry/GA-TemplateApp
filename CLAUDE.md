# CLAUDE.md - GA-TemplateApp Project Reference

## Project Overview

**GA-TemplateApp** is a [DESCRIPTION OF YOUR APP]. Created by [AUTHOR NAME] ([ROLE], GA-ASI).

**Purpose:**
- [PRIMARY PURPOSE 1]
- [PRIMARY PURPOSE 2]
- [PRIMARY PURPOSE 3]

**Target Platforms:** Windows 10/11, Windows Server 2019+

## Technology Stack

- **Pure PowerShell** (5.1+) - no external dependencies
- **WPF/XAML** for GUI (embedded in PowerShell)
- **PS2EXE** for executable compilation
- **Pester 5.x** for unit testing
- **AutoIt** for GUI automation testing
- **PSScriptAnalyzer** for code quality

## Project Structure

```
GA-TemplateApp/
├── GA-TemplateApp.exe               # Standalone portable executable (main entry)
├── GA-TemplateApp.psd1              # PowerShell module manifest
├── GA-TemplateApp.psm1              # Root module with wrapper functions
├── README.md                        # Full documentation
├── CHANGELOG.md                     # Version history
├── LICENSE                          # License file
├── .gitignore                       # Git exclusions
├── PSScriptAnalyzerSettings.psd1    # Code analysis settings
│
├── .github/
│   └── workflows/
│       ├── build.yml                # Main CI/CD pipeline
│       └── codacy.yml               # Security scanning
│
├── .claude/
│   ├── settings.local.json          # Claude Code permissions
│   └── commands/                    # Custom slash commands
│
├── build/
│   ├── Build-App.ps1                # Full build orchestrator
│   ├── Build-GUI.ps1                # GUI executable compilation
│   ├── Build-Distribution.ps1       # ZIP package creator
│   ├── Invoke-LocalValidation.ps1   # Pre-commit validation
│   └── Publish-ToGallery.ps1        # PowerShell Gallery publishing
│
├── src/
│   ├── Core/                        # Core workflow scripts
│   │   └── Start-AppWorkflow.ps1    # Main entry point
│   ├── GUI/
│   │   ├── GA-TemplateApp-Portable.ps1  # WPF GUI application
│   │   └── AsyncHelpers.psm1        # Async execution module
│   └── Modules/                     # Reusable PowerShell modules
│       ├── Common.psm1              # Shared functions
│       ├── ErrorHandling.psm1       # Standardized error handling
│       └── Config.psd1              # Centralized configuration
│
├── Tests/
│   ├── *.Tests.ps1                  # Pester unit tests
│   ├── Fixtures/                    # Test data files
│   └── GUI/
│       ├── GA-TemplateApp-GUI-Test.au3  # AutoIt test script
│       ├── Run-GUITests.bat         # Test runner
│       └── README.md                # Test documentation
│
├── assets/                          # Icons and images
│   └── app-icon.ico                 # Application icon
│
├── config/                          # Configuration files
│   └── app-config.json              # Application settings
│
├── docs/                            # Additional documentation
│   └── Developer-Guide.md           # Development handbook
│
└── dist/                            # Distribution packages (git-tracked)
    └── GA-TemplateApp-v1.0.0.zip    # Release package
```

## Build Commands

### Quick Reference

```powershell
# Pre-commit validation (ALWAYS run before committing)
.\build\Invoke-LocalValidation.ps1

# Build GUI executable
.\build\Build-GUI.ps1

# Full build (validate + test + package)
.\build\Build-App.ps1

# Build targets
.\build\Build-App.ps1 -Target Validate   # Lint only
.\build\Build-App.ps1 -Target Test       # Tests only
.\build\Build-App.ps1 -Target Package    # Package only
.\build\Build-App.ps1 -Target Clean      # Remove artifacts

# Skip options
.\build\Build-App.ps1 -SkipTests
.\build\Build-App.ps1 -SkipValidation

# CI mode (strict, fails on any issue)
.\build\Build-App.ps1 -CI
```

## Development Workflow

### 1. Make Changes
Edit scripts in `src/` directory following established patterns.

### 2. Validate Locally
```powershell
.\build\Invoke-LocalValidation.ps1
```
This runs:
- PSScriptAnalyzer (code quality)
- XAML validation (GUI syntax)
- Pester tests (unit tests)

### 3. Build & Test
```powershell
.\build\Build-GUI.ps1
```
This:
- Compiles GUI to EXE
- Creates distribution ZIP
- Auto-updates dist/ folder

### 4. Commit & Push
```powershell
git add -A
git commit -m "feat: description"
git push
```

### 5. Create Release (when ready)
```powershell
gh release create v1.0.0 "dist/GA-TemplateApp-v1.0.0.zip" --title "v1.0.0" --notes "Release notes"
```

## Code Conventions

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Functions | Verb-Noun (approved verbs) | `Get-AppConfig` |
| Variables | camelCase | `$configPath` |
| Script Variables | $script:camelCase | `$script:appVersion` |
| Parameters | PascalCase | `-OutputPath` |
| Constants | UPPER_CASE | `$MAX_RETRIES` |

### Approved Verbs
Get, Set, New, Remove, Test, Invoke, Start, Stop, Import, Export, Initialize, Update

### Documentation Standards

All public functions require comment-based help:
```powershell
<#
.SYNOPSIS
    One-line description.
.DESCRIPTION
    Detailed explanation.
.PARAMETER ParamName
    Parameter documentation.
.OUTPUTS
    Return type documentation.
.EXAMPLE
    Usage example.
#>
```

### Color Output Standards

Use standardized output functions from Common.psm1:
- `Write-Success` - Green (success messages)
- `Write-Failure` - Red (error messages)
- `Write-Warning` - Yellow (warnings)
- `Write-Info` - Cyan (information)

## Testing

### Pester Unit Tests
```powershell
# Run all tests
Invoke-Pester -Path .\Tests

# Run specific test file
Invoke-Pester -Path .\Tests\Common.Tests.ps1

# With code coverage
Invoke-Pester -Path .\Tests -CodeCoverage .\src\Modules\*.psm1
```

### AutoIt GUI Tests
```powershell
# Run via batch file
.\Tests\GUI\Run-GUITests.bat

# Direct execution
& "C:\Program Files (x86)\AutoIt3\AutoIt3.exe" .\Tests\GUI\GA-TemplateApp-GUI-Test.au3
```

## GUI Development

### Built-in Features (Template Defaults)

The GUI template includes these features out-of-the-box:

1. **DPI Awareness**: Automatic high-DPI display support (per-monitor aware)
2. **Async Operations**: Use `AsyncHelpers.psm1` for background tasks without UI freezing
3. **Error Handling**: Graceful crash handling with error dialogs and logging
4. **Test Mode**: Run with `-Test` flag for automated validation

### Using AsyncHelpers for Background Tasks

```powershell
# Import the module
Import-Module "$PSScriptRoot\AsyncHelpers.psm1"

# Run a long operation without freezing the UI
Start-AsyncTask -ScriptBlock {
    # Your long-running code here
    Get-ChildItem C:\ -Recurse
} -Window $window -OnComplete {
    param($result)
    # Update UI with results (runs on UI thread)
    $listBox.ItemsSource = $result
} -OnError {
    param($error)
    Write-Log "Operation failed: $error" -Level Error
}

# Cancel running tasks on window close
$window.Add_Closing({ Stop-AllAsyncTasks })
```

### Common Issues and Solutions

1. **Blank Operation Windows**: Show dialogs BEFORE switching panels
2. **Curly Braces in Output**: Suppress return values with `$null =`
3. **Event Handler Scope**: Pass data via `-MessageData`, not script-scope
4. **UI Updates from Background**: Use `$window.Dispatcher.Invoke()` or `Invoke-OnUIThread`
5. **Closure Variable Capture**: Use `.GetNewClosure()` in handlers
6. **Concurrent Operations**: Use operation flag to prevent conflicts
7. **ESC Key Not Closing Dialogs**: Add KeyDown event handler
8. **UI Freezing**: Use `Start-AsyncTask` for operations > 100ms

### GUI Testing Checklist

Before committing GUI changes:
- [ ] All operations show dialogs BEFORE switching panels
- [ ] All function return values suppressed
- [ ] Event handlers use Dispatcher.Invoke() for UI updates
- [ ] Click handlers use .GetNewClosure()
- [ ] Concurrent operation blocking in place
- [ ] Cancel button properly kills processes
- [ ] All dialogs close with ESC key
- [ ] Build passes: `.\build\Build-App.ps1`
- [ ] Manual test each affected operation

## Version Management

### Update Version In:
1. `build\Build-GUI.ps1` - `$Version = "X.Y.Z"`
2. `src\GUI\GA-TemplateApp-Portable.ps1` - `$Script:AppVersion = "X.Y.Z"`
3. `GA-TemplateApp.psd1` - `ModuleVersion = 'X.Y.Z'`
4. `CHANGELOG.md` - Add new version section

### Semantic Versioning
- **MAJOR** (X): Breaking changes
- **MINOR** (Y): New features, backwards compatible
- **PATCH** (Z): Bug fixes, backwards compatible

## Security Practices

### Input Validation
- Validate all user inputs
- Use `Test-Path` for file paths
- Escape paths in commands

### Credential Handling
- Never store plaintext passwords
- Use `[SecureString]` or Windows Credential Manager
- Avoid `ConvertTo-SecureString` with plaintext

### Code Quality
- No hardcoded credentials
- No `Invoke-Expression` with user input
- Handle errors explicitly (no empty catch blocks)

## CI/CD Pipeline

### GitHub Actions (`.github/workflows/build.yml`)

**Triggers:**
- Push to main/master/develop
- Pull requests to main/master
- Manual dispatch

**Jobs:**
1. **code-review**: PSScriptAnalyzer + security rules + XAML validation
2. **test**: Pester tests with code coverage
3. **build**: Compile EXE + validate + benchmark startup + create distribution packages
4. **release**: Create GitHub release (manual trigger only)

### EXE Validation (Automated)
The build pipeline automatically validates compiled EXEs:
- **Size check**: Warns if EXE exceeds 50 MB
- **Startup benchmark**: Measures time to first window, warns if > 5 seconds
- **Crash detection**: Fails build if EXE crashes on launch

### Local Validation Mirror
`Invoke-LocalValidation.ps1` mirrors CI checks locally:
- Same PSScriptAnalyzer rules
- Same Pester configuration
- XAML validation
- EXE validation and startup benchmark (if built)

## Troubleshooting

### Build Fails
1. Check PSScriptAnalyzer output for errors
2. Run tests individually to find failures
3. Verify PS2EXE module is installed

### Tests Fail
1. Check test output for specific failures
2. Run individual test file for details
3. Check Fixtures/ for missing test data

### GUI Not Working
1. Check XAML syntax errors
2. Verify event handlers bound correctly
3. Test in PowerShell ISE for debugging

## Additional Resources

- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Pester Documentation](https://pester.dev/docs/quick-start)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules/README.md)
- [AutoIt Documentation](https://www.autoitscript.com/autoit3/docs/)
