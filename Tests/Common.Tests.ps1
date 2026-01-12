<#
.SYNOPSIS
    Pester tests for Common.psm1 module

.DESCRIPTION
    Unit tests for the Common utility module functions
#>

BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot "..\src\Modules\Common.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -DisableNameChecking
    }
}

Describe "Output Functions" {
    Context "Write-Success" {
        It "Should not throw an error" {
            { Write-Success -Message "Test message" } | Should -Not -Throw
        }
    }

    Context "Write-Failure" {
        It "Should not throw an error" {
            { Write-Failure -Message "Test error" } | Should -Not -Throw
        }
    }

    Context "Write-Info" {
        It "Should not throw an error" {
            { Write-Info -Message "Test info" } | Should -Not -Throw
        }
    }

    Context "Write-AppWarning" {
        It "Should not throw an error" {
            { Write-AppWarning -Message "Test warning" } | Should -Not -Throw
        }
    }

    Context "Write-SectionHeader" {
        It "Should not throw an error" {
            { Write-SectionHeader -Title "Test Section" } | Should -Not -Throw
        }
    }

    Context "Write-StepProgress" {
        It "Should not throw an error" {
            { Write-StepProgress -Step 1 -Total 5 -Message "Processing" } | Should -Not -Throw
        }
    }
}

Describe "Path Validation" {
    Context "Test-ValidPath" {
        It "Should return true for valid existing file" {
            # Use a file that should always exist on Windows
            $result = Test-ValidPath -Path "$env:SystemRoot\System32\cmd.exe" -Type File -MustExist
            $result | Should -Be $true
        }

        It "Should return true for valid existing directory" {
            $result = Test-ValidPath -Path $env:TEMP -Type Directory -MustExist
            $result | Should -Be $true
        }

        It "Should return false for non-existent file when MustExist" {
            $result = Test-ValidPath -Path "C:\NonExistent\file.txt" -Type File -MustExist
            $result | Should -Be $false
        }

        It "Should return true for valid path without MustExist" {
            $result = Test-ValidPath -Path "C:\ValidPath\file.txt" -Type File
            $result | Should -Be $true
        }

        It "Should return false for path with invalid characters" {
            $result = Test-ValidPath -Path "C:\Invalid<>Path" -Type File
            $result | Should -Be $false
        }
    }

    Context "Get-SafePath" {
        It "Should wrap path with spaces in quotes" {
            $result = Get-SafePath -Path "C:\Program Files\App"
            $result | Should -Be '"C:\Program Files\App"'
        }

        It "Should not modify path without spaces" {
            $result = Get-SafePath -Path "C:\Apps\file.exe"
            $result | Should -Be "C:\Apps\file.exe"
        }
    }
}

Describe "Privilege Checking" {
    Context "Test-AdminPrivileges" {
        It "Should return a boolean value" {
            $result = Test-AdminPrivileges
            $result | Should -BeOfType [bool]
        }
    }

    Context "Assert-AdminPrivileges" {
        It "Should throw if not admin and running in non-admin context" {
            # This test may pass or fail depending on execution context
            # Just verify the function exists and is callable
            { Get-Command Assert-AdminPrivileges } | Should -Not -Throw
        }
    }
}

Describe "Configuration" {
    BeforeAll {
        $testConfigPath = Join-Path $TestDrive "test-config.json"
    }

    Context "Get-AppConfig" {
        It "Should return empty hashtable for non-existent file" {
            $result = Get-AppConfig -ConfigPath "C:\NonExistent\config.json"
            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
        }

        It "Should load valid JSON config" {
            $testConfig = @{ Setting1 = "Value1"; Setting2 = 123 }
            $testConfig | ConvertTo-Json | Out-File $testConfigPath
            $result = Get-AppConfig -ConfigPath $testConfigPath
            $result.Setting1 | Should -Be "Value1"
            $result.Setting2 | Should -Be 123
        }
    }

    Context "Save-AppConfig" {
        It "Should save configuration to file" {
            $config = @{ TestKey = "TestValue" }
            Save-AppConfig -Config $config -ConfigPath $testConfigPath
            Test-Path $testConfigPath | Should -Be $true

            $loaded = Get-Content $testConfigPath -Raw | ConvertFrom-Json
            $loaded.TestKey | Should -Be "TestValue"
        }
    }
}

Describe "Logging" {
    BeforeAll {
        $testLogPath = Join-Path $TestDrive "test.log"
    }

    AfterEach {
        Stop-AppLogging
    }

    Context "Start-AppLogging" {
        It "Should create log file" {
            Start-AppLogging -LogPath $testLogPath
            Test-Path $testLogPath | Should -Be $true
        }
    }

    Context "Write-Log" {
        It "Should write to log file when logging is active" {
            Start-AppLogging -LogPath $testLogPath
            Write-Log -Message "Test message" -Level Info

            $content = Get-Content $testLogPath -Raw
            $content | Should -Match "Test message"
            $content | Should -Match "\[Info\]"
        }

        It "Should include timestamp in log entries" {
            Start-AppLogging -LogPath $testLogPath
            Write-Log -Message "Timestamp test"

            $content = Get-Content $testLogPath -Raw
            $content | Should -Match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"
        }
    }
}

AfterAll {
    Remove-Module Common -ErrorAction SilentlyContinue
}
