<#
.SYNOPSIS
    GA-TemplateApp Portable GUI Application

.DESCRIPTION
    A standalone, portable graphical user interface for the GA-TemplateApp toolkit.
    Can be compiled to a single .exe file using PS2EXE or run directly.

.NOTES
    Author: [YOUR NAME]
            [YOUR ROLE]
            [YOUR DEPARTMENT], GA-ASI
            [YOUR EMAIL]

    Requires: PowerShell 5.1+, Windows Presentation Foundation

    To compile to EXE:
    Install-Module -Name PS2EXE -Scope CurrentUser
    Invoke-PS2EXE -InputFile .\GA-TemplateApp-Portable.ps1 -OutputFile .\GA-TemplateApp.exe -NoConsole -RequireAdmin

.EXAMPLE
    .\GA-TemplateApp-Portable.ps1
    Runs the GUI application directly

.EXAMPLE
    .\GA-TemplateApp.exe
    Runs the compiled executable
#>

#Requires -Version 5.1

param(
    [string]$ScriptsPath = "",
    [switch]$Test  # Used for automated testing - exits after launch validation
)

# Version constant - UPDATE THIS when releasing new versions
$Script:AppVersion = "1.0.0"

#region DPI Awareness
# Enable DPI awareness for crisp rendering on high-DPI displays
# This must be called BEFORE loading WPF assemblies
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class DpiAwareness {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetProcessDPIAware();

    [DllImport("shcore.dll", SetLastError = true)]
    public static extern int SetProcessDpiAwareness(int awareness);

    public static void Enable() {
        try {
            // Try Windows 8.1+ per-monitor DPI awareness first
            SetProcessDpiAwareness(2); // PROCESS_PER_MONITOR_DPI_AWARE
        } catch {
            // Fall back to system DPI awareness for older Windows
            SetProcessDPIAware();
        }
    }
}
"@ -ErrorAction SilentlyContinue

try {
    [DpiAwareness]::Enable()
} catch {
    # Silently continue if DPI awareness fails (non-critical)
}
#endregion

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

#region Script Path Detection
# Detect script root - handles EXE, PS1, and ISE scenarios
$Script:AppRoot = $null

if ($ScriptsPath -and (Test-Path $ScriptsPath)) {
    $Script:AppRoot = $ScriptsPath
}
else {
    $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($exePath -and $exePath -notmatch 'powershell\.exe$|pwsh\.exe$') {
        $Script:AppRoot = Split-Path -Parent $exePath
    }
    elseif ($PSScriptRoot) {
        $Script:AppRoot = Split-Path -Parent $PSScriptRoot
    }
    elseif ($MyInvocation.MyCommand.Path) {
        $Script:AppRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }
    else {
        $Script:AppRoot = (Get-Location).Path
    }
}

$Script:IsPortable = $true
#endregion

#region XAML Definition
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="GA-TemplateApp"
    Height="800"
    Width="1200"
    MinHeight="600"
    MinWidth="900"
    WindowStartupLocation="CenterScreen"
    Background="#0D1117">

    <Window.InputBindings>
        <!-- Navigation Shortcuts -->
        <KeyBinding x:Name="KeyPage1" Key="D1" Modifiers="Control" />
        <KeyBinding x:Name="KeyPage2" Key="D2" Modifiers="Control" />
        <KeyBinding x:Name="KeyPage3" Key="D3" Modifiers="Control" />
        <KeyBinding x:Name="KeyHelp" Key="F1" />
        <KeyBinding x:Name="KeySettings" Key="OemComma" Modifiers="Control" />
    </Window.InputBindings>

    <Window.Resources>
        <!-- Modern Dark Theme Color Palette -->
        <Color x:Key="BgDark">#0D1117</Color>
        <Color x:Key="BgSidebar">#161B22</Color>
        <Color x:Key="BgCard">#21262D</Color>
        <Color x:Key="BgInput">#0D1117</Color>
        <Color x:Key="BorderColor">#30363D</Color>
        <Color x:Key="AccentBlue">#58A6FF</Color>
        <Color x:Key="AccentGreen">#3FB950</Color>
        <Color x:Key="AccentOrange">#D29922</Color>
        <Color x:Key="AccentPurple">#A371F7</Color>
        <Color x:Key="AccentRed">#F85149</Color>
        <Color x:Key="TextPrimary">#E6EDF3</Color>
        <Color x:Key="TextSecondary">#A8B2BC</Color>
        <Color x:Key="TextMuted">#7D8590</Color>

        <SolidColorBrush x:Key="BgDarkBrush" Color="{StaticResource BgDark}"/>
        <SolidColorBrush x:Key="BgSidebarBrush" Color="{StaticResource BgSidebar}"/>
        <SolidColorBrush x:Key="BgCardBrush" Color="{StaticResource BgCard}"/>
        <SolidColorBrush x:Key="BgInputBrush" Color="{StaticResource BgInput}"/>
        <SolidColorBrush x:Key="BorderBrush" Color="{StaticResource BorderColor}"/>
        <SolidColorBrush x:Key="AccentBlueBrush" Color="{StaticResource AccentBlue}"/>
        <SolidColorBrush x:Key="AccentGreenBrush" Color="{StaticResource AccentGreen}"/>
        <SolidColorBrush x:Key="AccentOrangeBrush" Color="{StaticResource AccentOrange}"/>
        <SolidColorBrush x:Key="AccentPurpleBrush" Color="{StaticResource AccentPurple}"/>
        <SolidColorBrush x:Key="AccentRedBrush" Color="{StaticResource AccentRed}"/>
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="{StaticResource TextPrimary}"/>
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="{StaticResource TextSecondary}"/>
        <SolidColorBrush x:Key="TextMutedBrush" Color="{StaticResource TextMuted}"/>

        <!-- Primary Button Style -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBlueBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#79C0FF"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#30363D"/>
                                <Setter Property="Foreground" Value="#484F58"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button Style -->
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource BgCardBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#30363D"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#484F58"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Foreground" Value="#484F58"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Navigation Button Style -->
        <Style x:Key="NavButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextSecondaryBrush}"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#21262D"/>
                                <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Active Navigation Button Style -->
        <Style x:Key="NavButtonActive" TargetType="Button" BasedOn="{StaticResource NavButton}">
            <Setter Property="Background" Value="#21262D"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
        </Style>

        <!-- Modern TextBox Style -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource BgInputBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,10"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource AccentBlueBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Modern ComboBox Style -->
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="{StaticResource BgInputBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,10"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>

        <!-- Modern CheckBox Style -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimaryBrush}"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,4"/>
        </Style>

        <!-- Card Panel Style -->
        <Style x:Key="CardPanel" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource BgCardBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="0,0,0,16"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Sidebar Navigation -->
        <Border Grid.Column="0" Background="{StaticResource BgSidebarBrush}"
                BorderBrush="{StaticResource BorderBrush}" BorderThickness="0,0,1,0">
            <DockPanel>
                <!-- App Header -->
                <StackPanel DockPanel.Dock="Top" Margin="16,20,16,24">
                    <TextBlock Text="GA-TemplateApp" FontSize="18" FontWeight="Bold"
                               Foreground="{StaticResource TextPrimaryBrush}"/>
                    <TextBlock x:Name="VersionText" Text="Version 1.0.0" FontSize="11"
                               Foreground="{StaticResource TextMutedBrush}" Margin="0,4,0,0"/>
                </StackPanel>

                <!-- Navigation Menu -->
                <StackPanel DockPanel.Dock="Top">
                    <TextBlock Text="MAIN" FontSize="10" FontWeight="SemiBold"
                               Foreground="{StaticResource TextMutedBrush}"
                               Margin="16,0,0,8"/>

                    <Button x:Name="NavDashboard" Style="{StaticResource NavButtonActive}"
                            Content="Dashboard" ToolTip="Ctrl+1"/>
                    <Button x:Name="NavPage1" Style="{StaticResource NavButton}"
                            Content="Page 1" ToolTip="Ctrl+2"/>
                    <Button x:Name="NavPage2" Style="{StaticResource NavButton}"
                            Content="Page 2" ToolTip="Ctrl+3"/>

                    <TextBlock Text="TOOLS" FontSize="10" FontWeight="SemiBold"
                               Foreground="{StaticResource TextMutedBrush}"
                               Margin="16,20,0,8"/>

                    <Button x:Name="NavSettings" Style="{StaticResource NavButton}"
                            Content="Settings" ToolTip="Ctrl+,"/>
                    <Button x:Name="NavHelp" Style="{StaticResource NavButton}"
                            Content="Help" ToolTip="F1"/>
                    <Button x:Name="NavAbout" Style="{StaticResource NavButton}"
                            Content="About"/>
                </StackPanel>

                <!-- Footer -->
                <StackPanel DockPanel.Dock="Bottom" Margin="16,0,16,16" VerticalAlignment="Bottom">
                    <TextBlock Text="General Atomics" FontSize="10"
                               Foreground="{StaticResource TextMutedBrush}"/>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- Main Content Area -->
        <Grid Grid.Column="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Page Content -->
            <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Padding="24">
                <Grid x:Name="ContentArea">
                    <!-- Dashboard Page (default) -->
                    <StackPanel x:Name="PageDashboard" Visibility="Visible">
                        <TextBlock Text="Dashboard" FontSize="24" FontWeight="Bold"
                                   Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,8"/>
                        <TextBlock Text="Welcome to GA-TemplateApp" FontSize="13"
                                   Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>

                        <!-- Status Cards -->
                        <UniformGrid Columns="3" Margin="0,0,0,24">
                            <Border Style="{StaticResource CardPanel}" Margin="0,0,12,0">
                                <StackPanel>
                                    <TextBlock Text="STATUS" FontSize="10" FontWeight="SemiBold"
                                               Foreground="{StaticResource TextMutedBrush}"/>
                                    <TextBlock x:Name="StatusValue" Text="Ready" FontSize="24" FontWeight="Bold"
                                               Foreground="{StaticResource AccentGreenBrush}" Margin="0,8,0,0"/>
                                </StackPanel>
                            </Border>
                            <Border Style="{StaticResource CardPanel}" Margin="6,0,6,0">
                                <StackPanel>
                                    <TextBlock Text="METRIC 1" FontSize="10" FontWeight="SemiBold"
                                               Foreground="{StaticResource TextMutedBrush}"/>
                                    <TextBlock x:Name="Metric1Value" Text="0" FontSize="24" FontWeight="Bold"
                                               Foreground="{StaticResource AccentBlueBrush}" Margin="0,8,0,0"/>
                                </StackPanel>
                            </Border>
                            <Border Style="{StaticResource CardPanel}" Margin="12,0,0,0">
                                <StackPanel>
                                    <TextBlock Text="METRIC 2" FontSize="10" FontWeight="SemiBold"
                                               Foreground="{StaticResource TextMutedBrush}"/>
                                    <TextBlock x:Name="Metric2Value" Text="0" FontSize="24" FontWeight="Bold"
                                               Foreground="{StaticResource AccentOrangeBrush}" Margin="0,8,0,0"/>
                                </StackPanel>
                            </Border>
                        </UniformGrid>

                        <!-- Quick Actions -->
                        <Border Style="{StaticResource CardPanel}">
                            <StackPanel>
                                <TextBlock Text="Quick Actions" FontSize="14" FontWeight="SemiBold"
                                           Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,16"/>
                                <WrapPanel>
                                    <Button x:Name="BtnAction1" Content="Action 1"
                                            Style="{StaticResource PrimaryButton}" Margin="0,0,8,8"/>
                                    <Button x:Name="BtnAction2" Content="Action 2"
                                            Style="{StaticResource SecondaryButton}" Margin="0,0,8,8"/>
                                    <Button x:Name="BtnAction3" Content="Action 3"
                                            Style="{StaticResource SecondaryButton}" Margin="0,0,8,8"/>
                                </WrapPanel>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- Page 1 -->
                    <StackPanel x:Name="Page1" Visibility="Collapsed">
                        <TextBlock Text="Page 1" FontSize="24" FontWeight="Bold"
                                   Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,8"/>
                        <TextBlock Text="Configure your first feature here" FontSize="13"
                                   Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>

                        <Border Style="{StaticResource CardPanel}">
                            <StackPanel>
                                <TextBlock Text="Configuration" FontSize="14" FontWeight="SemiBold"
                                           Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,16"/>

                                <StackPanel Margin="0,0,0,12">
                                    <TextBlock Text="Input Field 1" FontSize="12"
                                               Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,6"/>
                                    <TextBox x:Name="Input1" Width="400" HorizontalAlignment="Left"/>
                                </StackPanel>

                                <StackPanel Margin="0,0,0,12">
                                    <TextBlock Text="Input Field 2" FontSize="12"
                                               Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,6"/>
                                    <TextBox x:Name="Input2" Width="400" HorizontalAlignment="Left"/>
                                </StackPanel>

                                <Button x:Name="BtnPage1Action" Content="Execute"
                                        Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left"
                                        Margin="0,8,0,0"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- Page 2 -->
                    <StackPanel x:Name="Page2" Visibility="Collapsed">
                        <TextBlock Text="Page 2" FontSize="24" FontWeight="Bold"
                                   Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,8"/>
                        <TextBlock Text="Configure your second feature here" FontSize="13"
                                   Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>

                        <Border Style="{StaticResource CardPanel}">
                            <StackPanel>
                                <TextBlock Text="Options" FontSize="14" FontWeight="SemiBold"
                                           Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,16"/>

                                <CheckBox x:Name="Option1" Content="Enable Option 1"/>
                                <CheckBox x:Name="Option2" Content="Enable Option 2"/>
                                <CheckBox x:Name="Option3" Content="Enable Option 3"/>

                                <Button x:Name="BtnPage2Action" Content="Save Options"
                                        Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left"
                                        Margin="0,16,0,0"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- Settings Page -->
                    <StackPanel x:Name="PageSettings" Visibility="Collapsed">
                        <TextBlock Text="Settings" FontSize="24" FontWeight="Bold"
                                   Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,8"/>
                        <TextBlock Text="Configure application settings" FontSize="13"
                                   Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>

                        <Border Style="{StaticResource CardPanel}">
                            <StackPanel>
                                <TextBlock Text="General Settings" FontSize="14" FontWeight="SemiBold"
                                           Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,16"/>

                                <CheckBox x:Name="SettingDarkMode" Content="Dark Mode (enabled by default)" IsChecked="True"/>
                                <CheckBox x:Name="SettingAutoSave" Content="Auto-save settings"/>
                                <CheckBox x:Name="SettingNotifications" Content="Enable notifications"/>

                                <Button x:Name="BtnSaveSettings" Content="Save Settings"
                                        Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left"
                                        Margin="0,16,0,0"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- Help Page -->
                    <StackPanel x:Name="PageHelp" Visibility="Collapsed">
                        <TextBlock Text="Help" FontSize="24" FontWeight="Bold"
                                   Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,8"/>
                        <TextBlock Text="Documentation and keyboard shortcuts" FontSize="13"
                                   Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>

                        <Border Style="{StaticResource CardPanel}">
                            <StackPanel>
                                <TextBlock Text="Keyboard Shortcuts" FontSize="14" FontWeight="SemiBold"
                                           Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,16"/>

                                <TextBlock Text="Ctrl+1  -  Dashboard" FontSize="12" Foreground="{StaticResource TextSecondaryBrush}" Margin="0,4"/>
                                <TextBlock Text="Ctrl+2  -  Page 1" FontSize="12" Foreground="{StaticResource TextSecondaryBrush}" Margin="0,4"/>
                                <TextBlock Text="Ctrl+3  -  Page 2" FontSize="12" Foreground="{StaticResource TextSecondaryBrush}" Margin="0,4"/>
                                <TextBlock Text="Ctrl+,  -  Settings" FontSize="12" Foreground="{StaticResource TextSecondaryBrush}" Margin="0,4"/>
                                <TextBlock Text="F1      -  Help" FontSize="12" Foreground="{StaticResource TextSecondaryBrush}" Margin="0,4"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- About Page -->
                    <StackPanel x:Name="PageAbout" Visibility="Collapsed">
                        <TextBlock Text="About" FontSize="24" FontWeight="Bold"
                                   Foreground="{StaticResource TextPrimaryBrush}" Margin="0,0,0,8"/>
                        <TextBlock Text="Application information" FontSize="13"
                                   Foreground="{StaticResource TextSecondaryBrush}" Margin="0,0,0,24"/>

                        <Border Style="{StaticResource CardPanel}">
                            <StackPanel>
                                <TextBlock Text="GA-TemplateApp" FontSize="18" FontWeight="Bold"
                                           Foreground="{StaticResource TextPrimaryBrush}"/>
                                <TextBlock x:Name="AboutVersion" Text="Version 1.0.0" FontSize="12"
                                           Foreground="{StaticResource TextSecondaryBrush}" Margin="0,4,0,16"/>

                                <TextBlock Text="A template application for GA PowerShell tools." FontSize="12"
                                           Foreground="{StaticResource TextSecondaryBrush}" TextWrapping="Wrap"/>

                                <TextBlock Text="Author: [Your Name]" FontSize="12"
                                           Foreground="{StaticResource TextMutedBrush}" Margin="0,16,0,0"/>
                                <TextBlock Text="Organization: General Atomics" FontSize="12"
                                           Foreground="{StaticResource TextMutedBrush}"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Grid>
            </ScrollViewer>

            <!-- Log Output Panel -->
            <Border Grid.Row="1" Background="{StaticResource BgSidebarBrush}"
                    BorderBrush="{StaticResource BorderBrush}" BorderThickness="0,1,0,0"
                    Height="200">
                <DockPanel>
                    <Border DockPanel.Dock="Top" Background="{StaticResource BgCardBrush}"
                            BorderBrush="{StaticResource BorderBrush}" BorderThickness="0,0,0,1"
                            Padding="12,8">
                        <DockPanel>
                            <TextBlock Text="Output Log" FontSize="12" FontWeight="SemiBold"
                                       Foreground="{StaticResource TextPrimaryBrush}"
                                       VerticalAlignment="Center"/>
                            <Button x:Name="BtnClearLog" Content="Clear" Style="{StaticResource SecondaryButton}"
                                    HorizontalAlignment="Right" Padding="8,4"/>
                        </DockPanel>
                    </Border>
                    <TextBox x:Name="LogOutput" IsReadOnly="True" TextWrapping="Wrap"
                             VerticalScrollBarVisibility="Auto" Background="Transparent"
                             Foreground="{StaticResource TextSecondaryBrush}" FontFamily="Consolas"
                             FontSize="11" Padding="12" BorderThickness="0"/>
                </DockPanel>
            </Border>
        </Grid>
    </Grid>
</Window>
"@
#endregion

#region Window Creation
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find all named controls
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
    $name = $_.Name
    if ($name) {
        Set-Variable -Name $name -Value $window.FindName($name) -Scope Script
    }
}
#endregion

#region Helper Functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Level) {
        'Info'    { "[INFO]" }
        'Success' { "[OK]" }
        'Warning' { "[WARN]" }
        'Error'   { "[ERROR]" }
    }

    $logMessage = "$timestamp $prefix $Message`r`n"

    $window.Dispatcher.Invoke([action]{
        $LogOutput.AppendText($logMessage)
        $LogOutput.ScrollToEnd()
    })
}

function Show-Page {
    param([string]$PageName)

    # Hide all pages
    $PageDashboard.Visibility = 'Collapsed'
    $Page1.Visibility = 'Collapsed'
    $Page2.Visibility = 'Collapsed'
    $PageSettings.Visibility = 'Collapsed'
    $PageHelp.Visibility = 'Collapsed'
    $PageAbout.Visibility = 'Collapsed'

    # Reset all nav buttons
    $NavDashboard.Style = $window.FindResource('NavButton')
    $NavPage1.Style = $window.FindResource('NavButton')
    $NavPage2.Style = $window.FindResource('NavButton')
    $NavSettings.Style = $window.FindResource('NavButton')
    $NavHelp.Style = $window.FindResource('NavButton')
    $NavAbout.Style = $window.FindResource('NavButton')

    # Show selected page and highlight nav button
    switch ($PageName) {
        'Dashboard' {
            $PageDashboard.Visibility = 'Visible'
            $NavDashboard.Style = $window.FindResource('NavButtonActive')
        }
        'Page1' {
            $Page1.Visibility = 'Visible'
            $NavPage1.Style = $window.FindResource('NavButtonActive')
        }
        'Page2' {
            $Page2.Visibility = 'Visible'
            $NavPage2.Style = $window.FindResource('NavButtonActive')
        }
        'Settings' {
            $PageSettings.Visibility = 'Visible'
            $NavSettings.Style = $window.FindResource('NavButtonActive')
        }
        'Help' {
            $PageHelp.Visibility = 'Visible'
            $NavHelp.Style = $window.FindResource('NavButtonActive')
        }
        'About' {
            $PageAbout.Visibility = 'Visible'
            $NavAbout.Style = $window.FindResource('NavButtonActive')
        }
    }
}
#endregion

#region Event Handlers

# Navigation
$NavDashboard.Add_Click({ Show-Page 'Dashboard' })
$NavPage1.Add_Click({ Show-Page 'Page1' })
$NavPage2.Add_Click({ Show-Page 'Page2' })
$NavSettings.Add_Click({ Show-Page 'Settings' })
$NavHelp.Add_Click({ Show-Page 'Help' })
$NavAbout.Add_Click({ Show-Page 'About' })

# Keyboard shortcuts
$KeyPage1.Command = New-Object System.Windows.Input.RoutedCommand
$window.CommandBindings.Add((New-Object System.Windows.Input.CommandBinding $KeyPage1.Command, { Show-Page 'Dashboard' }))

$KeyPage2.Command = New-Object System.Windows.Input.RoutedCommand
$window.CommandBindings.Add((New-Object System.Windows.Input.CommandBinding $KeyPage2.Command, { Show-Page 'Page1' }))

$KeyPage3.Command = New-Object System.Windows.Input.RoutedCommand
$window.CommandBindings.Add((New-Object System.Windows.Input.CommandBinding $KeyPage3.Command, { Show-Page 'Page2' }))

$KeyHelp.Command = New-Object System.Windows.Input.RoutedCommand
$window.CommandBindings.Add((New-Object System.Windows.Input.CommandBinding $KeyHelp.Command, { Show-Page 'Help' }))

$KeySettings.Command = New-Object System.Windows.Input.RoutedCommand
$window.CommandBindings.Add((New-Object System.Windows.Input.CommandBinding $KeySettings.Command, { Show-Page 'Settings' }))

# Quick actions
$BtnAction1.Add_Click({
    Write-Log "Action 1 executed" -Level Success
})

$BtnAction2.Add_Click({
    Write-Log "Action 2 executed" -Level Info
})

$BtnAction3.Add_Click({
    Write-Log "Action 3 executed" -Level Info
})

# Page actions
$BtnPage1Action.Add_Click({
    $value1 = $Input1.Text
    $value2 = $Input2.Text
    Write-Log "Page 1 action: Input1='$value1', Input2='$value2'" -Level Info
})

$BtnPage2Action.Add_Click({
    $opt1 = $Option1.IsChecked
    $opt2 = $Option2.IsChecked
    $opt3 = $Option3.IsChecked
    Write-Log "Options saved: Option1=$opt1, Option2=$opt2, Option3=$opt3" -Level Success
})

$BtnSaveSettings.Add_Click({
    Write-Log "Settings saved" -Level Success
})

$BtnClearLog.Add_Click({
    $LogOutput.Clear()
})

# Window loaded
$window.Add_Loaded({
    $window.Title = "GA-TemplateApp v$Script:AppVersion"
    $VersionText.Text = "Version $Script:AppVersion"
    $AboutVersion.Text = "Version $Script:AppVersion"
    Write-Log "GA-TemplateApp v$Script:AppVersion started" -Level Info
    Write-Log "App root: $Script:AppRoot" -Level Info
})

# Cleanup on window close
$window.Add_Closing({
    # Stop any async tasks (if AsyncHelpers is loaded)
    if (Get-Command Stop-AllAsyncTasks -ErrorAction SilentlyContinue) {
        Stop-AllAsyncTasks
    }
})
#endregion

#region Error Handling Wrapper and Window Display
# Wrap window display in try/catch for graceful error handling
# This catches runtime errors that would otherwise crash the compiled EXE silently

# Handle test mode for automated validation
if ($Test) {
    # Test mode: verify window can be created, then exit
    Write-Host "Test mode: Window created successfully"
    Write-Host "Version: $Script:AppVersion"
    Write-Host "App Root: $Script:AppRoot"
    exit 0
}

try {
    $null = $window.ShowDialog()
}
catch {
    $errorMessage = $_.Exception.Message
    $errorStack = $_.ScriptStackTrace

    # Log error to temp file for debugging
    $crashLogPath = Join-Path $env:TEMP "GA-TemplateApp-crash.log"
    $crashEntry = @"
========================================
Crash Report: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Version: $Script:AppVersion
========================================
Error: $errorMessage

Stack Trace:
$errorStack

Exception Details:
$($_ | Format-List -Force | Out-String)
========================================

"@
    Add-Content -Path $crashLogPath -Value $crashEntry -ErrorAction SilentlyContinue

    # Show error dialog to user
    $null = [System.Windows.MessageBox]::Show(
        "An unexpected error occurred:`n`n$errorMessage`n`nDetails have been logged to:`n$crashLogPath",
        "GA-TemplateApp Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )

    # Exit with error code
    exit 1
}
#endregion
