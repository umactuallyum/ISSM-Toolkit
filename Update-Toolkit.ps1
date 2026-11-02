<#
.SYNOPSIS
    One-time updater for the ISSM Weekly Toolkit. Run it from the toolkit folder.

.DESCRIPTION
    Weekly-EventLog-Review.ps1
        - Raw logs are saved to ONE file per run: <HOST>_<date>_EventLogs.evtx in the week folder
          (Security, System, PowerShell, Defender and PrintService together) instead of a
          separate .evtx per log.
        - No longer pulls update events (no OS_Updates.csv / AV_Updates.csv / Setup.evtx /
          Defender.evtx in AV_OS_Updates). Install-Updates.ps1 keeps the update record in the
          month's AV_OS_Updates\Update_Log.csv, appending to it all month.

    User-Password-Report.ps1
        - Same report and columns, but the next password change comes from the account's real
          expiry date (Windows / AD password policy) instead of a fixed "set date + 60 days".

    Run-All.ps1
        - Comment updated to match.

    Originals are copied to Backup_<date-time> in this folder before anything is changed.
    If any file does not look as expected, nothing is changed. Safe to run twice.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Update-Toolkit.ps1
#>
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
if (-not $here) { $here = (Get-Location).Path }

$problems = New-Object System.Collections.Generic.List[string]

function Get-Dash([string]$Text) { [regex]::Match($Text, '(?m)^# -{20,}$').Value }

function Set-Exact {
    param([hashtable]$F, [string]$Old, [string]$New)
    $Old = $Old -replace "`r", ''; $New = $New -replace "`r", ''
    $i = $F.Text.IndexOf($Old)
    if ($i -lt 0 -or $F.Text.IndexOf($Old, $i + 1) -ge 0) {
        $problems.Add("$($F.Name): could not find (exactly once): $(($Old -split "`n")[0])"); return
    }
    $F.Text = $F.Text.Substring(0, $i) + $New + $F.Text.Substring($i + $Old.Length)
}

function Set-Between {
    # Replaces everything from $Start (included) up to $End (not included)
    param([hashtable]$F, [string]$Start, [string]$End, [string]$New)
    $Start = $Start -replace "`r", ''; $End = $End -replace "`r", ''; $New = $New -replace "`r", ''
    $i = $F.Text.IndexOf($Start)
    $j = $(if ($i -ge 0) { $F.Text.IndexOf($End, $i + $Start.Length) } else { -1 })
    if ($i -lt 0 -or $j -lt 0) { $problems.Add("$($F.Name): could not find section starting: $Start"); return }
    $F.Text = $F.Text.Substring(0, $i) + $New + $F.Text.Substring($j)
}

function Open-File([string]$Name) {
    $path = Join-Path $here $Name
    if (-not (Test-Path -LiteralPath $path)) { $problems.Add("$Name not found in $here"); return $null }
    @{ Name = $Name; Path = $path; Text = ([IO.File]::ReadAllText($path) -replace "`r", '') }
}

$files = @()

# ===========================================================================
# Weekly-EventLog-Review.ps1
# ===========================================================================
$ev = Open-File 'Weekly-EventLog-Review.ps1'
if ($ev -and $ev.Text.Contains('function Export-CombinedEvtx')) {
    Write-Host "Weekly-EventLog-Review.ps1 is already updated - skipped." -ForegroundColor Gray
} elseif ($ev) {
    $dash = Get-Dash $ev.Text
    $files += $ev

    Set-Between $ev '    Into the WEEK folder' '    ID     Tier' ((@'
    Into the WEEK folder  (<Root>\<Year>\<MM_Month>\WeekN_dd-dd\):
        <HOST>_<date>_AuditSettings.csv   PASS/FAIL for the audit settings each Event ID needs (AU-12)
        <HOST>_<date>_WeeklyReview.csv    ONLY the events to review each week (start here)
        <HOST>_<date>_Events.csv          every monitored Event ID with key fields (Review, Filter, Archive)
        <HOST>_<date>_EventCounts.csv     count per Event ID (zeros included)
        <HOST>_<date>_EventLogs.evtx      ONE raw log file for the period: Security, System, PowerShell,
                                          Defender and PrintService together (open in Event Viewer)

    Update installs are not pulled here. Install-Updates.ps1 keeps the month's update record in
    <Root>\<Year>\<MM_Month>\AV_OS_Updates\Update_Log.csv.

    Folders are created automatically if missing.

    WHERE TO FIND EACH EVENT
    ------------------------
    Event Viewer: Start > type "Event Viewer" > open the log path below > Filter Current Log > enter the Event ID.
    Script output: Review events -> WeeklyReview.csv AND Events.csv; Filter/Archive events -> Events.csv only.
    Every event also stays in the raw copy: Week folder\<HOST>_<date>_EventLogs.evtx
    (Event Viewer > Action > Open Saved Log; the Log Name column shows which log each event came from).

    Log                      Event Viewer path
    Security                 Windows Logs > Security
    System                   Windows Logs > System
    PowerShell/Operational   Applications and Services Logs > Microsoft > Windows > PowerShell > Operational
    Defender/Operational     Applications and Services Logs > Microsoft > Windows > Windows Defender > Operational
    PrintService/Operational Applications and Services Logs > Microsoft > Windows > PrintService > Operational
'@) + "`n`n")

    # Update-event rows at the end of the ID table
    Set-Between $ev '    --- Update events' '.EXAMPLE' "`n"

    Set-Between $ev '$UpdateEvents = @(' '# Where each log lives' ''

    Set-Between $ev '# Where each log lives' 'function Get-FoundIn' ((@'
# Where each log lives in Event Viewer, and where the script saves its raw copy
$LogLocations = @{
    'Security'                                       = @{ Viewer = 'Event Viewer > Windows Logs > Security'; Evtx = 'EventLogs.evtx (week folder)' }
    'System'                                         = @{ Viewer = 'Event Viewer > Windows Logs > System'; Evtx = 'EventLogs.evtx (week folder)' }
    'Microsoft-Windows-PowerShell/Operational'       = @{ Viewer = 'Event Viewer > Applications and Services Logs > Microsoft > Windows > PowerShell > Operational'; Evtx = 'EventLogs.evtx (week folder)' }
    'Microsoft-Windows-Windows Defender/Operational' = @{ Viewer = 'Event Viewer > Applications and Services Logs > Microsoft > Windows > Windows Defender > Operational'; Evtx = 'EventLogs.evtx (week folder)' }
    'Microsoft-Windows-PrintService/Operational'     = @{ Viewer = 'Event Viewer > Applications and Services Logs > Microsoft > Windows > PrintService > Operational'; Evtx = 'EventLogs.evtx (week folder)' }
}
'@) + "`n")

    Set-Between $ev '$UpdateDescriptions = @{' '# Audit settings that must be ON' ''

    Set-Exact $ev @'
$updateFolder = Join-Path $monthFolder 'AV_OS_Updates'
foreach ($f in $weekFolder, $updateFolder) { New-Item -ItemType Directory -Force -Path $f | Out-Null }
'@ 'New-Item -ItemType Directory -Force -Path $weekFolder | Out-Null'

    Set-Exact $ev ('Write-Host "Updates: $updateFolder"' + "`n") ''

    Set-Between $ev 'function Export-Evtx {' 'function Format-Message {' ((@'
function Export-CombinedEvtx {
    # Saves the period from every listed log into ONE .evtx file
    param([string[]]$LogNames, [string]$File)
    $time = "*[System[TimeCreated[@SystemTime&gt;='{0}' and @SystemTime&lt;'{1}']]]" -f `
        $start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'), $end.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $included = @()
    foreach ($l in $LogNames) {
        try { $null = Get-WinEvent -ListLog $l -ErrorAction Stop; $included += $l }
        catch { Write-Host "  WARNING: $l not found on this system - left out of the .evtx" -ForegroundColor Yellow }
    }
    if (-not $included.Count) { Write-Host '  WARNING: no logs available to export' -ForegroundColor Yellow; return }
    $selects = ($included | ForEach-Object { '<Select Path="{0}">{1}</Select>' -f [Security.SecurityElement]::Escape($_), $time }) -join ''
    $queryFile = Join-Path $env:TEMP ('ISSM_EvtxQuery_{0}.xml' -f [guid]::NewGuid())
    Set-Content -LiteralPath $queryFile -Value "<QueryList><Query Id=`"0`">$selects</Query></QueryList>" -Encoding ASCII
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $null = & wevtutil.exe epl $queryFile $File /sq:true /ow:true 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    Remove-Item -LiteralPath $queryFile -Force -ErrorAction SilentlyContinue
    if ($code -eq 0) { Write-Host ("  Saved {0} ({1})" -f (Split-Path -Leaf $File), ($included -join ', ')) -ForegroundColor Green }
    else { Write-Host "  WARNING: could not export the event logs (exit $code)" -ForegroundColor Yellow }
}
'@) + "`n")

    # Only the update section used this
    Set-Exact $ev @'
function Format-Message {
    param($WinEvent)
    $m = ''
    try { $m = [string]$WinEvent.Message } catch { }
    ($m -replace '\s+', ' ').Trim()
}


'@ ''

    # Per-log .evtx exports + the whole OS/AV update section -> one combined export
    Set-Between $ev "Write-Host 'Saving raw event logs (.evtx)...'" "# Summary`n" ((@'
Write-Host 'Saving raw event logs (one .evtx)...' -ForegroundColor Cyan
$evtxLogs = @($Monitored | ForEach-Object { $_.Log } | Select-Object -Unique)
Export-CombinedEvtx $evtxLogs (Join-Path $weekFolder "$($computer)_$($stamp)_EventLogs.evtx")

'@) + "`n$dash`n")

    Set-Exact $ev 'Write-Host "Done. Files are in $weekFolder and $updateFolder" -ForegroundColor Green' 'Write-Host "Done. Files are in $weekFolder" -ForegroundColor Green'
}

# ===========================================================================
# User-Password-Report.ps1
# ===========================================================================
$pw = Open-File 'User-Password-Report.ps1'
if ($pw -and $pw.Text.Contains('msDS-UserPasswordExpiryTimeComputed')) {
    Write-Host "User-Password-Report.ps1 is already updated - skipped." -ForegroundColor Gray
} elseif ($pw) {
    $dash = Get-Dash $pw.Text
    $files += $pw

    Set-Exact $pw 'password change is due (password set date + 60 days). Saves a CSV.' 'password change is due (the password expiry date set by Windows). Saves a CSV.'
    Set-Exact $pw '        EXPIRED          password is older than 60 days' '        EXPIRED          password expiry date has passed'
    Set-Exact $pw '        NEVER EXPIRES    account is set to "password never expires" (date still shown)' '        NEVER EXPIRES    password does not expire (account setting, or no maximum password age)'
    Set-Exact $pw '    Disabled accounts are listed and marked so the report is complete.' (@'
    Disabled accounts are listed and marked so the report is complete.

    The next change date is the account's own expiry date from Windows (local password policy,
    or msDS-UserPasswordExpiryTimeComputed in AD) - no fixed number of days is assumed.
'@)
    Set-Exact $pw ".\User-Password-Report.ps1 -MaxPasswordAgeDays 60 -WarnDays 14 -Root 'D:\ISSM_Records'" ".\User-Password-Report.ps1 -WarnDays 14 -Root 'D:\ISSM_Records'"
    Set-Exact $pw ('    [int]$MaxPasswordAgeDays = 60,' + "`n") ''

    Set-Between $pw '# Collect accounts' '# Build report' ((@'
# Collect accounts
'@) + "`n$dash`n" + (@'
if ($Domain) {
    Import-Module ActiveDirectory
    $neverFileTime = [DateTime]::MaxValue.ToFileTime()
    $accounts = Get-ADUser -Filter * -Properties LastLogonTimestamp, PasswordLastSet, PasswordNeverExpires, Enabled, Description, 'msDS-UserPasswordExpiryTimeComputed' |
        ForEach-Object {
            $exp = [int64]$_.'msDS-UserPasswordExpiryTimeComputed'
            $expires = $(if ($exp -gt 0 -and $exp -lt $neverFileTime) { [DateTime]::FromFileTime($exp) } else { $null })
            [pscustomobject]@{
                Account              = $_.SamAccountName
                FullName             = $_.Name
                Enabled              = $_.Enabled
                LastLogon            = $(if ($_.LastLogonTimestamp) { [DateTime]::FromFileTime($_.LastLogonTimestamp) } else { $null })
                PasswordLastSet      = $_.PasswordLastSet
                PasswordExpires      = $expires
                PasswordNeverExpires = ($_.PasswordNeverExpires -or ($null -eq $expires -and $null -ne $_.PasswordLastSet))
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
            PasswordExpires      = $_.PasswordExpires
            PasswordNeverExpires = ($null -eq $_.PasswordExpires -and $null -ne $_.PasswordLastSet)
            Description          = $_.Description
        }
    }
}
'@) + "`n`n$dash`n")

    Set-Between $pw '$report = foreach ($a in $accounts) {' '    [pscustomobject]@{' ((@'
$report = foreach ($a in $accounts) {
    $nextChange = $null
    $daysLeft = $null
    $pwdAge = $null
    if ($a.PasswordLastSet) {
        $pwdAge = ($today.Date - $a.PasswordLastSet.Date).Days
        if ($a.PasswordExpires -and -not $a.PasswordNeverExpires) {
            $nextChange = $a.PasswordExpires
            $daysLeft = ($nextChange.Date - $today.Date).Days
        }
    }

    if (-not $a.PasswordLastSet)    { $status = 'NEVER SET' }
    elseif (-not $nextChange)       { $status = 'NEVER EXPIRES' }
    elseif ($daysLeft -lt 0)        { $status = 'EXPIRED' }
    elseif ($daysLeft -le $WarnDays) { $status = 'DUE SOON' }
    else                            { $status = 'OK' }
    if (-not $a.Enabled)            { $status = "$status (DISABLED)" }
'@) + "`n`n")

    Set-Exact $pw "        NextPasswordChange   = `$(if (`$nextChange) { `$nextChange.ToString('yyyy-MM-dd') } else { 'N/A' })" "        NextPasswordChange   = `$(if (`$nextChange) { `$nextChange.ToString('yyyy-MM-dd') } elseif (`$a.PasswordLastSet) { 'Never' } else { 'N/A' })"

    Set-Exact $pw 'Write-Host ("User password report - {0} - {1} (max password age {2} days)" -f $env:COMPUTERNAME, $today.ToString(''yyyy-MM-dd''), $MaxPasswordAgeDays) -ForegroundColor Cyan' 'Write-Host ("User password report - {0} - {1}" -f $env:COMPUTERNAME, $today.ToString(''yyyy-MM-dd'')) -ForegroundColor Cyan'
}

# ===========================================================================
# Run-All.ps1 (comment only)
# ===========================================================================
$ra = Open-File 'Run-All.ps1'
if ($ra -and $ra.Text.Contains('EventLogs.evtx')) {
    Write-Host "Run-All.ps1 is already updated - skipped." -ForegroundColor Gray
} elseif ($ra) {
    $files += $ra
    Set-Exact $ra @'
# Updates run FIRST so the event review that follows captures the install events
# (Setup log 2/4, Defender 2000) in this week's AV_OS_Updates CSVs.
'@ @'
# Updates run FIRST so the install events land in this week's EventLogs.evtx.
# The update record is the month's AV_OS_Updates\Update_Log.csv (appended by Install-Updates.ps1).
'@
}

# ===========================================================================
# Check, back up, write
# ===========================================================================
foreach ($f in $files) {
    $errs = $null
    $null = [Management.Automation.PSParser]::Tokenize($f.Text, [ref]$errs)
    if ($errs.Count) { $problems.Add("$($f.Name): updated script would not parse - $($errs[0].Message)") }
}

if ($problems.Count) {
    Write-Host ''
    Write-Host 'NOTHING WAS CHANGED. These files are not the expected version:' -ForegroundColor Red
    $problems | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}
if (-not $files.Count) { Write-Host 'Toolkit is already up to date.' -ForegroundColor Green; return }

$backup = Join-Path $here ('Backup_{0}' -f (Get-Date).ToString('yyyy-MM-dd_HHmmss'))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$enc = New-Object Text.UTF8Encoding($false)
foreach ($f in $files) {
    Copy-Item -LiteralPath $f.Path -Destination $backup
    [IO.File]::WriteAllText($f.Path, ($f.Text -replace "`n", "`r`n"), $enc)
    Write-Host "  Updated $($f.Name)" -ForegroundColor Green
}
Write-Host ''
Write-Host "Originals saved in $backup" -ForegroundColor Cyan
Write-Host 'Install-Updates.ps1 already appends to one Update_Log.csv per month - no change needed.' -ForegroundColor Cyan
