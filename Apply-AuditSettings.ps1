#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Applies every audit setting the weekly event review needs (AU-12), whether it
    currently passes or fails, then re-checks and reports PASS/FAIL.

.DESCRIPTION
    Sets:
      - 28 Advanced Audit Policy subcategories (Windows 11 STIG set; same list as GPO\audit.csv)
      - Security / Application / System log sizes (AU-4; only ever increased)
      - PrintService Operational log enabled (event 307 - printed documents)
      - Include command line in process creation events      (4688)
      - PowerShell Script Block Logging                        (4104)
      - Force audit policy subcategory settings to override category settings
        (without this, older category-level settings can override the subcategories)
      - Optional: auditing (SACL) on folders you list, needed for 4656 / 4663

    Settings are only turned ON. Nothing that is already enabled is turned off.

    Before changing anything it saves a backup to GPO\Backup_<date>\:
        audit_before.csv      restore with:  auditpol /restore /file:"<path>\audit_before.csv"
        registry_before.csv   previous registry values

    If a domain or local Group Policy sets these differently, policy refresh will
    overwrite what this script sets. Put the same settings in that GPO
    (see Audit_Settings_Fix_Text.md and the GPO folder).

.PARAMETER SaclFolders
    Folders to add file-access auditing to (Everyone; write, delete, permission and
    ownership changes; success and failure). Example: 'D:\Sensitive','C:\ISSM_Records'

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Apply-AuditSettings.ps1

.EXAMPLE
    .\Apply-AuditSettings.ps1 -SaclFolders 'D:\Sensitive','C:\ISSM_Records'
#>
param(
    [string[]]$SaclFolders
)

$ErrorActionPreference = 'Stop'
$G = '-69AE-11D9-BED3-505054503030}'
$AuditPolicy = @(
    @{ Name = 'Audit Credential Validation'; Guid = '{0CCE923F-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4776' },
    @{ Name = 'Audit Other Account Management Events'; Guid = '{0CCE923A-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4782, 4793' },
    @{ Name = 'Audit Security Group Management'; Guid = '{0CCE9237-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4727-4735, 4754-4758' },
    @{ Name = 'Audit User Account Management'; Guid = '{0CCE9235-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4720, 4722-4726, 4738, 4740, 4767, 4781' },
    @{ Name = 'Audit PNP Activity'; Guid = '{0CCE9248-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '6416' },
    @{ Name = 'Audit Process Creation'; Guid = '{0CCE922B-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4688' },
    @{ Name = 'Audit Account Lockout'; Guid = '{0CCE9217-69AE-11D9-BED3-505054503030}'; Success = $false; Failure = $true; Events = '4625 (locked account)' },
    @{ Name = 'Audit Group Membership'; Guid = '{0CCE9249-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4627' },
    @{ Name = 'Audit Logoff'; Guid = '{0CCE9216-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4634, 4647' },
    @{ Name = 'Audit Logon'; Guid = '{0CCE9215-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4624, 4625, 4648' },
    @{ Name = 'Audit Other Logon/Logoff Events'; Guid = '{0CCE921C-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4778, 4779, 4800-4803' },
    @{ Name = 'Audit Special Logon'; Guid = '{0CCE921B-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4672, 4964' },
    @{ Name = 'Audit File Share'; Guid = '{0CCE9224-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '5140, 5142-5144' },
    @{ Name = 'Audit File System'; Guid = '{0CCE921D-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4656, 4660, 4663, 4670' },
    @{ Name = 'Audit Other Object Access Events'; Guid = '{0CCE9227-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4698-4702' },
    @{ Name = 'Audit Registry'; Guid = '{0CCE921E-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4657' },
    @{ Name = 'Audit Removable Storage'; Guid = '{0CCE9245-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4656, 4663 (USB / removable media)' },
    @{ Name = 'Audit Audit Policy Change'; Guid = '{0CCE922F-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4715, 4719, 4912' },
    @{ Name = 'Audit Authentication Policy Change'; Guid = '{0CCE9230-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4706, 4707, 4713, 4739' },
    @{ Name = 'Audit Authorization Policy Change'; Guid = '{0CCE9231-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4704, 4705' },
    @{ Name = 'Audit MPSSVC Rule-Level Policy Change'; Guid = '{0CCE9232-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4946-4950' },
    @{ Name = 'Audit Other Policy Change Events'; Guid = '{0CCE9234-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = 'STIG requirement' },
    @{ Name = 'Audit Sensitive Privilege Use'; Guid = '{0CCE9228-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4673, 4674' },
    @{ Name = 'Audit IPsec Driver'; Guid = '{0CCE9213-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4960-4965' },
    @{ Name = 'Audit Other System Events'; Guid = '{0CCE9214-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '5024-5027 (firewall service)' },
    @{ Name = 'Audit Security State Change'; Guid = '{0CCE9210-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4608, 4616' },
    @{ Name = 'Audit Security System Extension'; Guid = '{0CCE9211-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4697, 4610, 4611, 4614, 4622' },
    @{ Name = 'Audit System Integrity'; Guid = '{0CCE9212-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4612, 5038, 6281' }
)
$Registry = @(
    @{ Name = 'Include command line in process creation events'; Path = 'HKLM:\\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit'; Value = 'ProcessCreationIncludeCmdLine_Enabled'; Expected = 1; Events = '4688 command line' },
    @{ Name = 'PowerShell Script Block Logging'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'; Value = 'EnableScriptBlockLogging'; Expected = 1; Events = '4104' },
    @{ Name = 'Force audit policy subcategory settings'; Path = 'HKLM:\\System\CurrentControlSet\Control\Lsa'; Value = 'SCENoApplyLegacyAuditPolicy'; Expected = 1; Events = 'all subcategories' },
    @{ Name = 'Security log maximum size (KB)'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\EventLog\Security'; Value = 'MaxSize'; Expected = 1024000; Events = 'AU-4' },
    @{ Name = 'Application log maximum size (KB)'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\EventLog\Application'; Value = 'MaxSize'; Expected = 32768; Events = 'AU-4' },
    @{ Name = 'System log maximum size (KB)'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\EventLog\System'; Value = 'MaxSize'; Expected = 32768; Events = 'AU-4' }
)

function Invoke-Native {
    param([string]$File, [string[]]$Arguments)
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = @(& $File @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    [pscustomobject]@{ ExitCode = $code; Output = $out }
}

function Get-AuditSetting {
    param([string]$Guid)
    $r = Invoke-Native 'auditpol.exe' @('/get', "/subcategory:$Guid", '/r')
    $lines = @($r.Output | Where-Object { $_.Trim() })
    if ($r.ExitCode -ne 0 -or $lines.Count -lt 2) { return 'Unable to read' }
    [string](($lines[1] | ConvertFrom-Csv -Header 'Machine', 'Target', 'Subcategory', 'Guid', 'Inclusion', 'Exclusion').Inclusion)
}

function Get-RegValue {
    param($Path, $Value)
    try { (Get-ItemProperty -LiteralPath $Path -Name $Value -ErrorAction Stop).$Value } catch { $null }
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
$backup = Join-Path $PSScriptRoot ('GPO\Backup_{0}' -f (Get-Date).ToString('yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$null = Invoke-Native 'auditpol.exe' @('/backup', "/file:$backup\audit_before.csv")
$Registry | ForEach-Object {
    $v = Get-RegValue $_.Path $_.Value
    [pscustomobject]@{ Path = $_.Path; Value = $_.Value; Before = $(if ($null -eq $v) { 'Not set' } else { $v }) }
} | Export-Csv -LiteralPath "$backup\registry_before.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Backup saved: $backup" -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------
Write-Host 'Applying audit policy...' -ForegroundColor Cyan
foreach ($a in $AuditPolicy) {
    $args2 = @('/set', "/subcategory:$($a.Guid)")
    if ($a.Success) { $args2 += '/success:enable' }
    if ($a.Failure) { $args2 += '/failure:enable' }
    $r = Invoke-Native 'auditpol.exe' $args2
    $msg = $(if ($r.ExitCode -eq 0) { 'set' } else { "ERROR (exit $($r.ExitCode))" })
    Write-Host ('  {0,-34} {1}' -f $a.Name, $msg)
}

Write-Host 'Applying registry settings...' -ForegroundColor Cyan
foreach ($rs in $Registry) {
    if (-not (Test-Path -LiteralPath $rs.Path)) { New-Item -Path $rs.Path -Force | Out-Null }
    $current = Get-RegValue $rs.Path $rs.Value
    if ($rs.Value -eq 'MaxSize' -and $current -ge $rs.Expected) {
        Write-Host ('  {0,-50} already {1} (kept)' -f $rs.Name, $current)
    } else {
        New-ItemProperty -LiteralPath $rs.Path -Name $rs.Value -Value $rs.Expected -PropertyType DWord -Force | Out-Null
        Write-Host ('  {0,-50} set to {1}' -f $rs.Name, $rs.Expected)
    }
    if ($rs.Value -eq 'MaxSize') {
        # Also resize the live log now (only ever increases)
        $logName = Split-Path -Leaf $rs.Path
        try {
            $info = Get-WinEvent -ListLog $logName -ErrorAction Stop
            if ($info.MaximumSizeInBytes -lt ([int64]$rs.Expected * 1KB)) { $null = Invoke-Native 'wevtutil.exe' @('sl', $logName, "/ms:$([int64]$rs.Expected * 1KB)") }
        } catch { }
    }
}

Write-Host 'Enabling PrintService Operational log (event 307 - printed documents)...' -ForegroundColor Cyan
$pr = Invoke-Native 'wevtutil.exe' @('sl', 'Microsoft-Windows-PrintService/Operational', '/e:true')
Write-Host ('  {0,-50} {1}' -f 'PrintService Operational log', $(if ($pr.ExitCode -eq 0) { 'enabled' } else { "ERROR (exit $($pr.ExitCode))" }))

if ($SaclFolders) {
    Write-Host 'Adding folder auditing (SACL) for 4656 / 4663...' -ForegroundColor Cyan
    $rights = [System.Security.AccessControl.FileSystemRights]'Write, Delete, DeleteSubdirectoriesAndFiles, ChangePermissions, TakeOwnership'
    $inherit = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
    $flags = [System.Security.AccessControl.AuditFlags]'Success, Failure'
    $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
    foreach ($folder in $SaclFolders) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
            Write-Host "  $folder - not found, skipped" -ForegroundColor Yellow
            continue
        }
        $acl = Get-Acl -LiteralPath $folder -Audit
        $rule = New-Object System.Security.AccessControl.FileSystemAuditRule($everyone, $rights, $inherit, 'None', $flags)
        $acl.AddAuditRule($rule)
        Set-Acl -LiteralPath $folder -AclObject $acl
        Write-Host "  $folder - auditing added" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Verifying...' -ForegroundColor Cyan
$results = @()
foreach ($a in $AuditPolicy) {
    $actual = Get-AuditSetting $a.Guid
    $need = @(); if ($a.Success) { $need += 'Success' }; if ($a.Failure) { $need += 'Failure' }
    $ok = ((-not $a.Success) -or $actual -match 'Success') -and ((-not $a.Failure) -or $actual -match 'Failure')
    $results += [pscustomobject]@{ Setting = $a.Name; Required = ($need -join ' and '); Actual = $actual; Status = $(if ($ok) { 'PASS' } else { 'FAIL' }); Generates = $a.Events }
}
foreach ($rs in $Registry) {
    $v = Get-RegValue $rs.Path $rs.Value
    if ($rs.Value -eq 'MaxSize') { $ok = ($v -ge $rs.Expected); $req = ">= $($rs.Expected)" } else { $ok = ($v -eq $rs.Expected); $req = "Enabled ($($rs.Expected))" }
    $results += [pscustomobject]@{ Setting = $rs.Name; Required = $req; Actual = $(if ($null -eq $v) { 'Not set' } else { "$v" }); Status = $(if ($ok) { 'PASS' } else { 'FAIL' }); Generates = $rs.Events }
}
$pe = $null
try { $pe = (Get-WinEvent -ListLog 'Microsoft-Windows-PrintService/Operational' -ErrorAction Stop).IsEnabled } catch { }
$results += [pscustomobject]@{ Setting = 'PrintService Operational log enabled'; Required = 'Enabled'; Actual = $(if ($pe) { 'Enabled' } else { 'Disabled' }); Status = $(if ($pe) { 'PASS' } else { 'FAIL' }); Generates = '307' }
foreach ($r in $results) {
    Write-Host ('  {0,-4}  {1,-50} {2}' -f $r.Status, $r.Setting, $r.Actual) -ForegroundColor $(if ($r.Status -eq 'PASS') { 'Green' } else { 'Red' })
}
$results | Export-Csv -LiteralPath "$backup\results_after.csv" -NoTypeInformation -Encoding UTF8

$fails = @($results | Where-Object { $_.Status -ne 'PASS' }).Count
Write-Host ''
if ($fails) {
    Write-Host "$fails setting(s) still FAIL - a Group Policy is probably overriding them. Set them in that GPO (see Audit_Settings_Fix_Text.md)." -ForegroundColor Yellow
} else {
    Write-Host 'All audit settings PASS.' -ForegroundColor Green
}
Write-Host 'Note: this change itself creates a 4719 (audit policy changed) event - expected; note it in the weekly review.'
Write-Host 'PowerShell Script Block Logging applies to new PowerShell windows.'
if (-not $SaclFolders) {
    Write-Host 'Reminder: 4656 / 4663 also need folder auditing. Re-run with -SaclFolders <folders> or set it manually.' -ForegroundColor Yellow
}
