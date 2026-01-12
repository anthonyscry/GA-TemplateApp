# GA-TemplateApp GUI Test Suite

Automated GUI testing for GA-TemplateApp using AutoIt.

## Prerequisites

- [AutoIt v3](https://www.autoitscript.com/site/autoit/downloads/)
- GA-TemplateApp.exe (built from source)

## Running Tests

### Using the Batch File

```cmd
Run-GUITests.bat          # Normal mode
Run-GUITests.bat quick    # Quick smoke tests
Run-GUITests.bat full     # Full test suite
Run-GUITests.bat verbose  # Verbose output
```

### Direct AutoIt Execution

```cmd
"C:\Program Files (x86)\AutoIt3\AutoIt3.exe" GA-TemplateApp-GUI-Test.au3 /verbose
```

## Test Suites

| Suite | Tests | Description |
|-------|-------|-------------|
| Application Launch | 3 | Verify app starts and window appears |
| Navigation | 5 | Test keyboard shortcuts |
| Dashboard | 2 | Dashboard page functionality |
| Settings | 1 | Settings page loads |
| Help | 2 | Help page and documentation |
| Window Close | 1 | Proper shutdown |

## Test Output

- Console output during execution
- Log file: `test-results-YYYYMMDD-HHMMSS.log`
- Exit code: 0 = pass, 1 = fail

## Adding New Tests

1. Add test function in `GA-TemplateApp-GUI-Test.au3`
2. Use `TestStart()`, `TestPass()`, `TestFail()` helpers
3. Call the test from `Main()`

Example:
```autoit
Func TestSuite_NewFeature()
    LogMessage("=== Test Suite: New Feature ===", "SUITE")

    TestStart("New feature works")
    ; Your test code here
    If $success Then
        TestPass("New feature works")
    Else
        TestFail("New feature works", "Reason for failure")
    EndIf
EndFunc
```

## CI/CD Integration

The test script returns appropriate exit codes for CI integration:
- Exit 0: All tests passed
- Exit 1: One or more tests failed

Example GitHub Actions step:
```yaml
- name: Run GUI Tests
  shell: cmd
  run: |
    "C:\Program Files (x86)\AutoIt3\AutoIt3.exe" Tests\GUI\GA-TemplateApp-GUI-Test.au3 /quick
```
