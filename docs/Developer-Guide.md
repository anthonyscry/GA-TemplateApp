# GA-TemplateApp Developer Guide

This guide covers development practices, architecture, and common patterns for GA-TemplateApp.

## Getting Started

### Prerequisites

1. **PowerShell 5.1+** (Windows native)
2. **PSScriptAnalyzer** - Code quality
   ```powershell
   Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
   ```
3. **Pester 5.0+** - Unit testing
   ```powershell
   Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser -Force
   ```
4. **PS2EXE** - Executable compilation
   ```powershell
   Install-Module -Name ps2exe -Scope CurrentUser
   ```
5. **AutoIt v3** (optional) - GUI testing
   - Download from https://www.autoitscript.com/

### Initial Setup

```powershell
# Clone the repository
git clone https://github.com/[org]/GA-TemplateApp.git
cd GA-TemplateApp

# Verify prerequisites
.\build\Invoke-LocalValidation.ps1 -SkipTests
```

## Project Structure

```
GA-TemplateApp/
├── build/                      # Build automation
│   ├── Build-App.ps1          # Main build orchestrator
│   ├── Build-GUI.ps1          # EXE compilation
│   ├── Build-Distribution.ps1 # ZIP packaging
│   └── Invoke-LocalValidation.ps1  # Pre-commit checks
├── src/
│   ├── Core/                  # Core business logic
│   ├── GUI/                   # WPF GUI application
│   │   └── GA-TemplateApp-Portable.ps1
│   └── Modules/               # Reusable PowerShell modules
│       └── Common.psm1
├── Tests/
│   ├── *.Tests.ps1           # Pester unit tests
│   ├── Fixtures/             # Test data
│   └── GUI/                  # AutoIt GUI tests
├── config/                   # Configuration files
├── assets/                   # Icons and images
├── docs/                     # Documentation
└── dist/                     # Distribution packages
```

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/my-feature
```

### 2. Make Changes

Edit files following the code conventions documented in CLAUDE.md.

### 3. Validate Changes

```powershell
# Run all validation
.\build\Invoke-LocalValidation.ps1

# Skip tests for quick check
.\build\Invoke-LocalValidation.ps1 -SkipTests
```

### 4. Build and Test GUI

```powershell
# Build executable
.\build\Build-GUI.ps1

# Test manually
.\GA-TemplateApp.exe

# Run automated GUI tests (requires AutoIt)
.\Tests\GUI\Run-GUITests.bat
```

### 5. Commit and Push

```bash
git add -A
git commit -m "feat: description of changes"
git push origin feature/my-feature
```

## GUI Development

### XAML Structure

The GUI uses WPF with XAML embedded in the PowerShell script:

```powershell
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
    <!-- XAML content -->
</Window>
"@
```

### Adding New Pages

1. Add XAML for the page in the `ContentArea` grid:
   ```xml
   <StackPanel x:Name="PageNewFeature" Visibility="Collapsed">
       <!-- Page content -->
   </StackPanel>
   ```

2. Add navigation button:
   ```xml
   <Button x:Name="NavNewFeature" Style="{StaticResource NavButton}"
           Content="New Feature" ToolTip="Ctrl+N"/>
   ```

3. Add navigation handler:
   ```powershell
   $NavNewFeature.Add_Click({ Show-Page 'NewFeature' })
   ```

4. Update `Show-Page` function to handle the new page.

### Common GUI Issues

| Issue | Solution |
|-------|----------|
| Blank windows | Show dialogs BEFORE switching panels |
| Curly braces in output | Suppress with `$null =` or `| Out-Null` |
| UI updates from background | Use `$window.Dispatcher.Invoke()` |
| Event handler scope | Pass data via `-MessageData` |
| Closure capture | Use `.GetNewClosure()` in handlers |

## Module Development

### Creating a New Module

1. Create file in `src/Modules/`:
   ```powershell
   # src/Modules/MyModule.psm1

   function Get-MyData {
       param([string]$Name)
       # Implementation
   }

   Export-ModuleMember -Function @('Get-MyData')
   ```

2. Add corresponding tests:
   ```powershell
   # Tests/MyModule.Tests.ps1

   BeforeAll {
       Import-Module "$PSScriptRoot\..\src\Modules\MyModule.psm1" -Force
   }

   Describe "Get-MyData" {
       It "Should return data" {
           $result = Get-MyData -Name "test"
           $result | Should -Not -BeNullOrEmpty
       }
   }
   ```

### Module Guidelines

- One module per logical domain
- Export only public functions
- Include comment-based help for all functions
- Write tests for all public functions

## Testing

### Pester Unit Tests

```powershell
# Run all tests
Invoke-Pester -Path .\Tests

# Run specific test
Invoke-Pester -Path .\Tests\Common.Tests.ps1

# With coverage
Invoke-Pester -Path .\Tests -CodeCoverage .\src\Modules\*.psm1
```

### AutoIt GUI Tests

```cmd
# Quick test
.\Tests\GUI\Run-GUITests.bat quick

# Full test
.\Tests\GUI\Run-GUITests.bat full
```

## Build System

### Build Targets

| Target | Command | Description |
|--------|---------|-------------|
| All | `.\build\Build-App.ps1` | Full build |
| Validate | `.\build\Build-App.ps1 -Target Validate` | Lint only |
| Test | `.\build\Build-App.ps1 -Target Test` | Tests only |
| Package | `.\build\Build-App.ps1 -Target Package` | Package only |
| Clean | `.\build\Build-App.ps1 -Target Clean` | Remove artifacts |

### Build Options

```powershell
# Skip tests for faster builds
.\build\Build-App.ps1 -SkipTests

# Skip validation
.\build\Build-App.ps1 -SkipValidation

# CI mode (strict)
.\build\Build-App.ps1 -CI

# Custom version
.\build\Build-GUI.ps1 -Version "2.0.0"
```

## Release Process

1. Update version in:
   - `build\Build-GUI.ps1`
   - `src\GUI\GA-TemplateApp-Portable.ps1` (`$Script:AppVersion`)
   - `CHANGELOG.md`

2. Run full build:
   ```powershell
   .\build\Build-App.ps1
   ```

3. Commit version bump:
   ```bash
   git add -A
   git commit -m "chore: bump version to X.Y.Z"
   git push
   ```

4. Create GitHub release:
   ```powershell
   gh release create vX.Y.Z "dist\GA-TemplateApp-vX.Y.Z.zip" --title "vX.Y.Z" --notes "Release notes"
   ```

## Troubleshooting

### Build Fails

1. Check PSScriptAnalyzer output for errors
2. Run tests individually to find failures
3. Verify PS2EXE module is installed

### Tests Fail

1. Run individual test for details:
   ```powershell
   Invoke-Pester -Path .\Tests\Failing.Tests.ps1 -Output Detailed
   ```
2. Check test fixtures exist

### GUI Not Working

1. Run script directly for error messages:
   ```powershell
   .\src\GUI\GA-TemplateApp-Portable.ps1
   ```
2. Check WPF assemblies load correctly
3. Verify XAML syntax

## Code Review Checklist

- [ ] Code follows naming conventions
- [ ] Functions have comment-based help
- [ ] No hardcoded credentials or secrets
- [ ] PSScriptAnalyzer passes with no errors
- [ ] All tests pass
- [ ] GUI changes manually tested
- [ ] CHANGELOG.md updated
