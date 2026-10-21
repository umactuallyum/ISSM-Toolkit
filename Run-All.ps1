#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Runs the weekly ISSM scripts in one go (everything except New-YearFolders.ps1).

.DESCRIPTION
    Order:
      0. Shows the system clock and asks you to confirm it is correct (AU-8)
      1. Install-Updates.ps1          - AV + OS updates from the staging folders
                                        (skipped automatically if the folders are empty)
      2. Weekly-EventLog-Review.ps1   - event review up to now (includes the installs from step 1)
      3. User-Password-Report.ps1     - last logon / password age / next change

    Updates run first so the review records them. If a reboot is needed, the
    summary says so at the end - reboot after reviewing. If one step fails, the others
    still run, and a summary at the end shows what passed or failed.

    Keep this file in the same folder as the other scripts.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Run-All.ps1

.EXAMPLE
    .\Run-All.ps1 -SkipUpdates
    .\Run-All.ps1 -Root 'D:\ISSM_Records' -Days 14
#>
param(
    [string]$Root = 'C:\ISSM_Records',
    [int]$Days = 7,
    [string]$AVFolder = 'C:\ISSM_Staging\AV',
    [string]$OSFolder = 'C:\ISSM_Staging\OS',
    [switch]$SkipUpdates,
    [switch]$Domain,
    [switch]$NoClockCheck
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$results = [ordered]@{}

# ---------------------------------------------------------------------------
# 0. Clock check - every script depends on the system time
# ---------------------------------------------------------------------------
if (-not $NoClockCheck) {
    Write-Host ''
    Write-Host ("System date/time: {0}" -f (Get-Date).ToString('dddd yyyy-MM-dd HH:mm:ss')) -ForegroundColor Cyan
    $answer = Read-Host 'Is this correct? (Y/N)'
    if ($answer -notmatch '^[Yy]') {
        Write-Host 'Fix the system clock first, then run this again.' -ForegroundColor Yellow
        return
    }
}

function Invoke-Step {
    param([string]$Name, [string]$Script, [hashtable]$Params)
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor Cyan
    Write-Host " $Name" -ForegroundColor Cyan
    Write-Host ('=' * 70) -ForegroundColor Cyan
    $path = Join-Path $here $Script
    if (-not (Test-Path -LiteralPath $path)) {
        $results[$Name] = "FAILED - $Script not found in $here"
        Write-Host $results[$Name] -ForegroundColor Red
        return
    }
    try {
        & $path @Params
        $results[$Name] = 'OK'
    } catch {
        $results[$Name] = "FAILED - $($_.Exception.Message)"
        Write-Host $results[$Name] -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# 1-3. Run the scripts
# ---------------------------------------------------------------------------
# Updates run FIRST so the event review that follows captures the install events
# (Setup log 2/4, Defender 2000) in this week's AV_OS_Updates CSVs.
if ($SkipUpdates) {
    $results['Install updates'] = 'SKIPPED (-SkipUpdates)'
} else {
    $hasAV = (Test-Path -LiteralPath $AVFolder) -and @(Get-ChildItem -LiteralPath $AVFolder -File -Include 'mpam-fe*.exe', 'UpdatePlatform*.exe' -Recurse -ErrorAction SilentlyContinue).Count
    $hasOS = (Test-Path -LiteralPath $OSFolder) -and @(Get-ChildItem -LiteralPath $OSFolder -File -Include '*.msu', '*.cab' -Recurse -ErrorAction SilentlyContinue).Count
    if ($hasAV -or $hasOS) {
        Invoke-Step 'Install updates' 'Install-Updates.ps1' @{ Root = $Root; AVFolder = $AVFolder; OSFolder = $OSFolder }
    } else {
        $results['Install updates'] = 'SKIPPED (no update files in the staging folders)'
    }
}

$evParams = @{ Root = $Root; Days = $Days }
Invoke-Step 'Weekly event log review' 'Weekly-EventLog-Review.ps1' $evParams

$pwParams = @{ Root = $Root }
if ($Domain) { $pwParams.Domain = $true }
Invoke-Step 'User / password report' 'User-Password-Report.ps1' $pwParams


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host ('=' * 70) -ForegroundColor Cyan
Write-Host ' SUMMARY' -ForegroundColor Cyan
Write-Host ('=' * 70) -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = $results[$k]
    $color = 'Green'
    if ($v -like 'SKIPPED*') { $color = 'Gray' }
    if ($v -like 'FAILED*') { $color = 'Red' }
    Write-Host ('  {0,-26} {1}' -f $k, $v) -ForegroundColor $color
}
Write-Host ''
Write-Host "  Records: $Root" -ForegroundColor Cyan
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
    Write-Host '  REBOOT REQUIRED to finish installing updates.' -ForegroundColor Yellow
}
