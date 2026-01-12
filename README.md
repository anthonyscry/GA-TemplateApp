# GA-TemplateApp

A template application for GA PowerShell tools with modern WPF GUI.

## Features

- Modern dark-themed WPF GUI
- Portable executable (single .exe file)
- Keyboard shortcuts for navigation
- Output logging panel
- Standardized build and test workflow

## Requirements

- Windows 10/11 or Windows Server 2019+
- PowerShell 5.1 or later
- .NET Framework 4.7.2 or later

## Quick Start

### Run the GUI

```powershell
# Run directly (PowerShell)
.\src\GUI\GA-TemplateApp-Portable.ps1

# Or run the compiled executable
.\GA-TemplateApp.exe
```

### Build from Source

```powershell
# Run validation before committing
.\build\Invoke-LocalValidation.ps1

# Build GUI executable
.\build\Build-GUI.ps1

# Full build (validate + test + package)
.\build\Build-App.ps1
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1 | Dashboard |
| Ctrl+2 | Page 1 |
| Ctrl+3 | Page 2 |
| Ctrl+, | Settings |
| F1 | Help |

## Project Structure

```
GA-TemplateApp/
├── build/                  # Build scripts
├── src/
│   ├── Core/              # Core functionality
│   ├── GUI/               # WPF GUI application
│   └── Modules/           # Reusable modules
├── Tests/                 # Pester and AutoIt tests
├── config/                # Configuration files
├── assets/                # Icons and images
├── docs/                  # Documentation
└── dist/                  # Distribution packages
```

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development documentation.

### Prerequisites

```powershell
# Install required modules
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser
Install-Module -Name ps2exe -Scope CurrentUser
```

### Build Commands

```powershell
# Validate code quality
.\build\Invoke-LocalValidation.ps1

# Build executable
.\build\Build-GUI.ps1

# Full build with tests
.\build\Build-App.ps1

# Skip tests for faster builds
.\build\Build-App.ps1 -SkipTests
```

## License

[Add your license here]

## Author

[Your Name]
[Your Role]
General Atomics
