@{
    # Severity levels to include
    Severity = @('Error', 'Warning')

    # Rules to exclude (common exclusions for GA apps)
    ExcludeRules = @(
        # Allow Write-Host for console output
        'PSAvoidUsingWriteHost',

        # These are often impractical for admin tools
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingInvokeExpression',

        # Naming flexibility
        'PSUseSingularNouns',
        'PSUseApprovedVerbs',

        # Parameter handling
        'PSReviewUnusedParameter',
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',

        # Variable tracking (often false positives)
        'PSUseDeclaredVarsMoreThanAssignments'
    )

    # Include specific rules (uncomment to enable)
    # IncludeRules = @(
    #     'PSAvoidUsingPlainTextForPassword',
    #     'PSAvoidUsingConvertToSecureStringWithPlainText'
    # )

    # Rules configuration
    Rules = @{
        # Configure specific rules
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $false
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
        }

        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }
    }
}
