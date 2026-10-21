#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Lists every user account with last logon, last password change, and when the next
    password change is due (password set date + 60 days). Saves a CSV.

.DESCRIPTION
    Default: local accounts on this computer (standalone / air-gapped systems).
    -Domain : Active Directory accounts instead (needs the ActiveDirectory module / RSAT).

    Output (same week folder as the weekly event review):
        <Root>\<Year>\<MM_Month>\WeekN_dd-dd\<HOST>_<date>_User_Password_Report.csv

    Status column:
        EXPIRED          password is older than 60 days
        DUE SOON         due within the next 7 days (change with -WarnDays)
        OK               more than 7 days left
        NEVER SET        no password-set date recorded
        NEVER EXPIRES    account is set to "password never expires" (date still shown)
    Disabled accounts are listed and marked so the report is complete.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\User-Password-Report.ps1

.EXAMPLE
    .\User-Password-Report.ps1 -MaxPasswordAgeDays 60 -WarnDays 14 -Root 'D:\ISSM_Records'

.EXAMPLE
    .\User-Password-Report.ps1 -Domain
#>
param(
    [string]$Root = 'C:\ISSM_Records',
    [int]$MaxPasswordAgeDays = 60,
    [int]$WarnDays = 7,
    [switch]$Domain
)

$ErrorActionPreference = 'Stop'
$today = Get-Date

# Output folder: current month / week (same layout as the year template)
$monthName = [Globalization.CultureInfo]::InvariantCulture.DateTimeFormat.GetMonthName($today.Month)
$monthFolder = Join-Path (Join-Path $Root $today.Year) ('{0:D2}_{1}' -f $today.Month, $monthName)
$week = [int][Math]::Ceiling($today.Day / 7)
$weekFirst = ($week - 1) * 7 + 1
$weekLast = [Math]::Min($week * 7, [DateTime]::DaysInMonth($today.Year, $today.Month))
$outFolder = Join-Path $monthFolder ('Week{0}_{1:D2}-{2:D2}' -f $week, $weekFirst, $weekLast)
New-Item -ItemType Directory -Force -Path $outFolder | Out-Null
$csv = Join-Path $outFolder ('{0}_{1}_User_Password_Report.csv' -f $env:COMPUTERNAME, $today.ToString('yyyy-MM-dd'))

# ---------------------------------------------------------------------------
# Collect accounts
# ---------------------------------------------------------------------------
if ($Domain) {
    Import-Module ActiveDirectory
    $accounts = Get-ADUser -Filter * -Properties LastLogonTimestamp, PasswordLastSet, PasswordNeverExpires, Enabled, Description |
        ForEach-Object {
            [pscustomobject]@{
                Account              = $_.SamAccountName
                FullName             = $_.Name
                Enabled              = $_.Enabled
                LastLogon            = $(if ($_.LastLogonTimestamp) { [DateTime]::FromFileTime($_.LastLogonTimestamp) } else { $null })
                PasswordLastSet      = $_.PasswordLastSet
                PasswordNeverExpires = $_.PasswordNeverExpires
                Description          = $_.Description
            }
        }
} else {
    $accounts = Get-LocalUser | ForEach-Object {
        [pscustomobject]@{
            Account              = $_.Name
            FullName             = $_.FullName
            Enabled              = $_.Enabled
            LastLogon            = $_.LastLogon
            PasswordLastSet      = $_.PasswordLastSet
            PasswordNeverExpires = ($null -eq $_.PasswordExpires -and $null -ne $_.PasswordLastSet)
            Description          = $_.Description
        }
    }
}

# ---------------------------------------------------------------------------
# Build report
# ---------------------------------------------------------------------------
function Format-Date($d) { if ($d) { $d.ToString('yyyy-MM-dd HH:mm') } else { 'Never' } }

$report = foreach ($a in $accounts) {
    $nextChange = $null
    $daysLeft = $null
    $pwdAge = $null
    if ($a.PasswordLastSet) {
        $nextChange = $a.PasswordLastSet.AddDays($MaxPasswordAgeDays)
        $daysLeft = ($nextChange.Date - $today.Date).Days
        $pwdAge = ($today.Date - $a.PasswordLastSet.Date).Days
    }

    if (-not $a.PasswordLastSet)    { $status = 'NEVER SET' }
    elseif ($daysLeft -lt 0)        { $status = 'EXPIRED' }
    elseif ($daysLeft -le $WarnDays) { $status = 'DUE SOON' }
    else                            { $status = 'OK' }
    if ($a.PasswordNeverExpires)    { $status = "$status / NEVER EXPIRES" }
    if (-not $a.Enabled)            { $status = "$status (DISABLED)" }

    [pscustomobject]@{
        Account              = $a.Account
        FullName             = $a.FullName
        Enabled              = $a.Enabled
        LastLogon            = Format-Date $a.LastLogon
        DaysSinceLastLogon   = $(if ($a.LastLogon) { ($today.Date - $a.LastLogon.Date).Days } else { '' })
        PasswordLastSet      = Format-Date $a.PasswordLastSet
        PasswordAgeDays      = $pwdAge
        NextPasswordChange   = $(if ($nextChange) { $nextChange.ToString('yyyy-MM-dd') } else { 'N/A' })
        DaysUntilChange      = $daysLeft
        Status               = $status
        PasswordNeverExpires = $a.PasswordNeverExpires
        Description          = $a.Description
    }
}
$report = @($report | Sort-Object @{ Expression = { if ($null -eq $_.DaysUntilChange) { -99999 } else { $_.DaysUntilChange } } })
$report | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8

# ---------------------------------------------------------------------------
# Screen output
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host ("User password report - {0} - {1} (max password age {2} days)" -f $env:COMPUTERNAME, $today.ToString('yyyy-MM-dd'), $MaxPasswordAgeDays) -ForegroundColor Cyan
Write-Host ('{0,-20} {1,-17} {2,-17} {3,-11} {4,5}  {5}' -f 'Account', 'Last Logon', 'Pwd Last Set', 'Next Change', 'Days', 'Status')
Write-Host ('-' * 100)
foreach ($r in $report) {
    $color = 'Gray'
    if ($r.Status -like 'EXPIRED*' -or $r.Status -like 'NEVER SET*') { $color = 'Red' }
    elseif ($r.Status -like 'DUE SOON*') { $color = 'Yellow' }
    elseif ($r.Status -like 'OK*') { $color = 'Green' }
    if (-not $r.Enabled) { $color = 'DarkGray' }
    Write-Host ('{0,-20} {1,-17} {2,-17} {3,-11} {4,5}  {5}' -f $r.Account, $r.LastLogon, $r.PasswordLastSet, $r.NextPasswordChange, $r.DaysUntilChange, $r.Status) -ForegroundColor $color
}
$active = @($report | Where-Object { $_.Enabled })
Write-Host ''
Write-Host ("Enabled accounts: {0}  |  Expired: {1}  |  Due within {2} days: {3}" -f $active.Count,
    @($active | Where-Object { $_.Status -like 'EXPIRED*' }).Count, $WarnDays,
    @($active | Where-Object { $_.Status -like 'DUE SOON*' }).Count)
Write-Host "Saved: $csv" -ForegroundColor Green
