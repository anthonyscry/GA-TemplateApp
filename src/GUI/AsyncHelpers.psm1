<#
.SYNOPSIS
    Async execution helpers for WPF GUI applications.

.DESCRIPTION
    Provides background task execution without freezing the UI thread.
    Essential for any PS2EXE compiled GUI application that performs
    long-running operations.

.NOTES
    Author: GA-ASI Template
    Requires: PowerShell 5.1+, WPF assemblies loaded

.EXAMPLE
    # Start a background task
    $task = Start-AsyncTask -ScriptBlock { Get-Process } -Window $window -OnComplete {
        param($result)
        $listBox.ItemsSource = $result
    }

.EXAMPLE
    # Run with progress updates
    Start-AsyncTask -ScriptBlock {
        for ($i = 1; $i -le 100; $i++) {
            Start-Sleep -Milliseconds 50
            Write-Progress -Activity "Processing" -PercentComplete $i
        }
        return "Complete"
    } -Window $window -OnProgress {
        param($percent)
        $progressBar.Value = $percent
    }
#>

#Requires -Version 5.1

# Track active runspaces for cleanup
$script:ActiveRunspaces = [System.Collections.ArrayList]::new()

function Start-AsyncTask {
    <#
    .SYNOPSIS
        Executes a script block in a background runspace without blocking the UI.

    .DESCRIPTION
        Creates a new runspace to execute the provided script block asynchronously.
        Uses WPF Dispatcher to safely update UI elements when complete.

    .PARAMETER ScriptBlock
        The code to execute in the background.

    .PARAMETER Window
        The WPF Window object for Dispatcher access.

    .PARAMETER OnComplete
        Script block to execute when the task completes. Receives the result as parameter.

    .PARAMETER OnError
        Script block to execute if the task throws an exception.

    .PARAMETER OnProgress
        Script block to execute for progress updates (0-100).

    .PARAMETER Arguments
        Hashtable of arguments to pass to the script block.

    .OUTPUTS
        PSCustomObject with Id, Runspace, and PowerShell properties for task management.

    .EXAMPLE
        Start-AsyncTask -ScriptBlock { Get-ChildItem C:\ } -Window $window -OnComplete {
            param($files)
            $listBox.ItemsSource = $files
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [System.Windows.Window]$Window,

        [scriptblock]$OnComplete,

        [scriptblock]$OnError,

        [scriptblock]$OnProgress,

        [hashtable]$Arguments = @{}
    )

    # Create runspace
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()

    # Pass arguments to runspace
    foreach ($key in $Arguments.Keys) {
        $runspace.SessionStateProxy.SetVariable($key, $Arguments[$key])
    }

    # Create PowerShell instance
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    $null = $powershell.AddScript($ScriptBlock)

    # Create task info object
    $taskId = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $taskInfo = [PSCustomObject]@{
        Id         = $taskId
        Runspace   = $runspace
        PowerShell = $powershell
        StartTime  = Get-Date
        Status     = 'Running'
    }

    # Track for cleanup
    $null = $script:ActiveRunspaces.Add($taskInfo)

    # Start async execution
    $asyncResult = $powershell.BeginInvoke()

    # Create timer to poll for completion
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)

    # Store references for the timer callback
    $timerState = @{
        Timer       = $timer
        PowerShell  = $powershell
        AsyncResult = $asyncResult
        Runspace    = $runspace
        Window      = $Window
        OnComplete  = $OnComplete
        OnError     = $OnError
        OnProgress  = $OnProgress
        TaskInfo    = $taskInfo
    }

    $timer.Add_Tick({
        $state = $timerState

        # Check for progress (if streams have data)
        if ($state.OnProgress -and $state.PowerShell.Streams.Progress.Count -gt 0) {
            $latestProgress = $state.PowerShell.Streams.Progress[-1]
            if ($latestProgress.PercentComplete -ge 0) {
                $state.Window.Dispatcher.Invoke([action]{
                    & $state.OnProgress $latestProgress.PercentComplete
                })
            }
        }

        # Check if complete
        if ($state.AsyncResult.IsCompleted) {
            $state.Timer.Stop()

            try {
                $result = $state.PowerShell.EndInvoke($state.AsyncResult)
                $state.TaskInfo.Status = 'Completed'

                # Check for errors
                if ($state.PowerShell.HadErrors -and $state.OnError) {
                    $errors = $state.PowerShell.Streams.Error
                    $state.Window.Dispatcher.Invoke([action]{
                        & $state.OnError $errors
                    })
                }
                elseif ($state.OnComplete) {
                    $state.Window.Dispatcher.Invoke([action]{
                        & $state.OnComplete $result
                    })
                }
            }
            catch {
                $state.TaskInfo.Status = 'Failed'
                if ($state.OnError) {
                    $errorInfo = $_
                    $state.Window.Dispatcher.Invoke([action]{
                        & $state.OnError $errorInfo
                    })
                }
            }
            finally {
                # Cleanup
                $state.PowerShell.Dispose()
                $state.Runspace.Close()
                $state.Runspace.Dispose()
                $null = $script:ActiveRunspaces.Remove($state.TaskInfo)
            }
        }
    }.GetNewClosure())

    $timer.Start()

    return $taskInfo
}

function Stop-AsyncTask {
    <#
    .SYNOPSIS
        Cancels a running async task.

    .PARAMETER TaskInfo
        The task object returned by Start-AsyncTask.

    .EXAMPLE
        $task = Start-AsyncTask -ScriptBlock { Start-Sleep 60 } -Window $window
        Stop-AsyncTask -TaskInfo $task
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$TaskInfo
    )

    if ($TaskInfo.Status -eq 'Running') {
        try {
            $TaskInfo.PowerShell.Stop()
            $TaskInfo.Status = 'Cancelled'
        }
        catch {
            Write-Warning "Failed to stop task $($TaskInfo.Id): $_"
        }
        finally {
            $TaskInfo.PowerShell.Dispose()
            $TaskInfo.Runspace.Close()
            $TaskInfo.Runspace.Dispose()
            $null = $script:ActiveRunspaces.Remove($TaskInfo)
        }
    }
}

function Stop-AllAsyncTasks {
    <#
    .SYNOPSIS
        Cancels all running async tasks. Call this on window close.

    .EXAMPLE
        $window.Add_Closing({ Stop-AllAsyncTasks })
    #>
    [CmdletBinding()]
    param()

    $tasksToStop = @($script:ActiveRunspaces)
    foreach ($task in $tasksToStop) {
        Stop-AsyncTask -TaskInfo $task
    }
}

function Invoke-OnUIThread {
    <#
    .SYNOPSIS
        Safely executes code on the UI thread from a background context.

    .PARAMETER Window
        The WPF Window for Dispatcher access.

    .PARAMETER ScriptBlock
        Code to execute on the UI thread.

    .PARAMETER Async
        If set, doesn't wait for completion (fire-and-forget).

    .EXAMPLE
        Invoke-OnUIThread -Window $window -ScriptBlock {
            $statusLabel.Content = "Updated!"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Window]$Window,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [switch]$Async
    )

    if ($Async) {
        $null = $Window.Dispatcher.BeginInvoke([action]$ScriptBlock)
    }
    else {
        $Window.Dispatcher.Invoke([action]$ScriptBlock)
    }
}

function Test-UIResponsive {
    <#
    .SYNOPSIS
        Tests if the UI thread is responsive. Useful for debugging freezes.

    .PARAMETER Window
        The WPF Window to test.

    .PARAMETER TimeoutMs
        Maximum time to wait for response (default 1000ms).

    .OUTPUTS
        Boolean indicating if UI responded within timeout.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Window]$Window,

        [int]$TimeoutMs = 1000
    )

    $responded = $false
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $null = $Window.Dispatcher.Invoke([action]{
            $responded = $true
        }, [System.Windows.Threading.DispatcherPriority]::Background,
           [System.Threading.CancellationToken]::None,
           [TimeSpan]::FromMilliseconds($TimeoutMs))
    }
    catch {
        # Timeout or error
    }

    $stopwatch.Stop()
    return $responded
}

# Export functions
Export-ModuleMember -Function @(
    'Start-AsyncTask',
    'Stop-AsyncTask',
    'Stop-AllAsyncTasks',
    'Invoke-OnUIThread',
    'Test-UIResponsive'
)
