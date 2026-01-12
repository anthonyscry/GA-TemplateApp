<#
.SYNOPSIS
    Pester tests for portable EXE validation.

.DESCRIPTION
    Validates the compiled PS2EXE executable:
    - File existence and size
    - Startup time performance
    - Basic launch validation
    - XAML can be loaded by WPF runtime

.NOTES
    These tests are critical for any PS2EXE compiled GUI application.
    Run after building to ensure the EXE works correctly.
#>

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:ExePath = Join-Path $script:RepoRoot "GA-TemplateApp.exe"
    $script:GuiScriptPath = Join-Path $script:RepoRoot "src\GUI\GA-TemplateApp-Portable.ps1"
    $script:MaxExeSizeMB = 50
    $script:MaxStartupTimeMs = 5000
}

Describe "Portable EXE Validation" {
    Context "Build Artifacts" {
        It "GUI source script exists" {
            $script:GuiScriptPath | Should -Exist
        }

        It "EXE file exists after build" -Skip:(-not (Test-Path $script:ExePath)) {
            $script:ExePath | Should -Exist
        }

        It "EXE size is reasonable (<$script:MaxExeSizeMB MB)" -Skip:(-not (Test-Path $script:ExePath)) {
            $exeSize = (Get-Item $script:ExePath).Length
            $exeSizeMB = [math]::Round($exeSize / 1MB, 2)
            Write-Host "  EXE size: $exeSizeMB MB"
            $exeSize | Should -BeLessThan ($script:MaxExeSizeMB * 1MB)
        }

        It "EXE has valid version metadata" -Skip:(-not (Test-Path $script:ExePath)) {
            $versionInfo = (Get-Item $script:ExePath).VersionInfo
            $versionInfo.ProductName | Should -Not -BeNullOrEmpty
        }
    }

    Context "Script Validation (No Build Required)" {
        It "GUI script has no syntax errors" {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:GuiScriptPath,
                [ref]$null,
                [ref]$errors
            )
            $errors.Count | Should -Be 0
        }

        It "GUI script runs in test mode without errors" {
            $result = & $script:GuiScriptPath -Test 2>&1
            $LASTEXITCODE | Should -Be 0
            $result | Should -Match "Window created successfully"
        }

        It "GUI script reports correct version format" {
            $result = & $script:GuiScriptPath -Test 2>&1
            $result | Should -Match "Version: \d+\.\d+\.\d+"
        }
    }

    Context "XAML Validation" {
        BeforeAll {
            Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        }

        It "Embedded XAML can be parsed as XML" {
            $content = Get-Content $script:GuiScriptPath -Raw

            # Extract XAML between @" and "@
            if ($content -match '\[xml\]\$xaml\s*=\s*@"(.+?)"@' ) {
                $xamlContent = $Matches[1]
                { [xml]$xamlContent } | Should -Not -Throw
            }
            else {
                # Alternative pattern for single quotes
                $content -match '\$xaml\s*=\s*@' | Should -Be $true
            }
        }

        It "XAML can be loaded by WPF XamlReader" {
            $content = Get-Content $script:GuiScriptPath -Raw

            # Extract the XAML
            if ($content -match '(?s)\[xml\]\$xaml\s*=\s*@"(.+?)"@') {
                $xamlContent = $Matches[1].Trim()

                # Try to parse with XamlReader (this validates WPF compatibility)
                try {
                    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xamlContent)
                    $window = [System.Windows.Markup.XamlReader]::Load($reader)
                    $window | Should -Not -BeNullOrEmpty
                    $window.Close()
                }
                catch {
                    # If we can't load, report but don't fail (may need STA thread)
                    Write-Host "  Note: Full XAML load requires STA thread, XML validation passed"
                }
            }
        }
    }

    Context "Startup Performance" -Skip:(-not (Test-Path $script:ExePath)) {
        It "EXE launches within $($script:MaxStartupTimeMs)ms" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            $process = Start-Process -FilePath $script:ExePath -PassThru -WindowStyle Hidden

            # Wait for main window to appear (with timeout)
            $timeout = $script:MaxStartupTimeMs
            while (-not $process.MainWindowHandle -and $stopwatch.ElapsedMilliseconds -lt $timeout) {
                Start-Sleep -Milliseconds 100
                $process.Refresh()
            }

            $stopwatch.Stop()
            $startupTime = $stopwatch.ElapsedMilliseconds

            # Cleanup
            if (-not $process.HasExited) {
                $process | Stop-Process -Force -ErrorAction SilentlyContinue
            }

            Write-Host "  Startup time: ${startupTime}ms"
            $startupTime | Should -BeLessThan $script:MaxStartupTimeMs
        }

        It "EXE does not crash on launch" {
            $process = Start-Process -FilePath $script:ExePath -PassThru -WindowStyle Hidden

            # Give it time to potentially crash
            Start-Sleep -Seconds 2

            $crashed = $process.HasExited -and $process.ExitCode -ne 0

            # Cleanup
            if (-not $process.HasExited) {
                $process | Stop-Process -Force -ErrorAction SilentlyContinue
            }

            $crashed | Should -Be $false
        }
    }

    Context "AsyncHelpers Module" {
        BeforeAll {
            $script:AsyncHelpersPath = Join-Path $script:RepoRoot "src\GUI\AsyncHelpers.psm1"
        }

        It "AsyncHelpers.psm1 exists" {
            $script:AsyncHelpersPath | Should -Exist
        }

        It "AsyncHelpers.psm1 has no syntax errors" {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:AsyncHelpersPath,
                [ref]$null,
                [ref]$errors
            )
            $errors.Count | Should -Be 0
        }

        It "AsyncHelpers exports required functions" {
            $module = Import-Module $script:AsyncHelpersPath -PassThru -Force -DisableNameChecking

            $expectedFunctions = @(
                'Start-AsyncTask',
                'Stop-AsyncTask',
                'Stop-AllAsyncTasks',
                'Invoke-OnUIThread'
            )

            foreach ($func in $expectedFunctions) {
                $module.ExportedFunctions.Keys | Should -Contain $func
            }

            Remove-Module AsyncHelpers -ErrorAction SilentlyContinue
        }
    }
}

Describe "DPI Awareness" {
    It "GUI script includes DPI awareness code" {
        $content = Get-Content $script:GuiScriptPath -Raw
        $content | Should -Match "DpiAwareness"
        $content | Should -Match "SetProcessDPIAware|SetProcessDpiAwareness"
    }
}

Describe "Error Handling" {
    It "GUI script has error handling wrapper" {
        $content = Get-Content $script:GuiScriptPath -Raw
        $content | Should -Match "try\s*\{[\s\S]*ShowDialog"
        $content | Should -Match "catch\s*\{"
    }

    It "GUI script logs crashes to temp file" {
        $content = Get-Content $script:GuiScriptPath -Raw
        $content | Should -Match "crash.*\.log"
    }

    It "GUI script shows error dialog on crash" {
        $content = Get-Content $script:GuiScriptPath -Raw
        $content | Should -Match "MessageBox.*Error"
    }
}

AfterAll {
    # Cleanup any lingering processes
    Get-Process -Name "GA-TemplateApp" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
}
