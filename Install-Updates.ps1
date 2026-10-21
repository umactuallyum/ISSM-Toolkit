#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs the AV update and Windows (OS) updates from local folders and writes an
    update log for the ISSM records.

.DESCRIPTION
    AV  : Microsoft Defender offline packages in -AVFolder
            UpdatePlatform*.exe  (platform, monthly)    installed first if present
            mpam-fe.exe          (definitions + engine)
    OS  : .msu / .cab files in -OSFolder, installed in file-name order with DISM.
          For Windows 11 checkpoint cumulative updates, keep all .msu files for the
          KB in the same folder; DISM picks up the prerequisite package automatically.

    Every install is appended to:
        <Root>\<Year>\<MM_Month>\AV_OS_Updates\Update_Log.csv
    with file hash, signature, exit code, result, and version before/after.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Install-Updates.ps1

.EXAMPLE
    .\Install-Updates.ps1 -AVOnly -AVFolder 'E:\Transfer\AV'

.EXAMPLE
    .\Install-Updates.ps1 -OSOnly -OSFolder 'E:\Transfer\OS'
#>
param(
    [string]$AVFolder = 'C:\ISSM_Staging\AV',
    [string]$OSFolder = 'C:\ISSM_Staging\OS',
    [string]$Root = 'C:\ISSM_Records',
    [switch]$AVOnly,
    [switch]$OSOnly
)

$ErrorActionPreference = 'Stop'
$now = Get-Date
$monthName = [Globalization.CultureInfo]::InvariantCulture.DateTimeFormat.GetMonthName($now.Month)
$logFolder = Join-Path (Join-Path (Join-Path $Root $now.Year) ('{0:D2}_{1}' -f $now.Month, $monthName)) 'AV_OS_Updates'
New-Item -ItemType Directory -Force -Path $logFolder | Out-Null
$logFile = Join-Path $logFolder 'Update_Log.csv'
$operator = "$env:USERDOMAIN\$env:USERNAME"

function Get-AVVersion {
    try {
        $s = Get-MpComputerStatus -ErrorAction Stop
        "Sig $($s.AntivirusSignatureVersion) | Engine $($s.AMEngineVersion) | Platform $($s.AMProductVersion)"
    } catch { 'Defender status unavailable' }
}

function Get-OSBuild {
    $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    "$($cv.DisplayVersion) build $($cv.CurrentBuild).$($cv.UBR)"
}

function Write-UpdateLog {
    param($Type, $File, $ExitCode, $Result, $Before, $After)
    $sig = Get-AuthenticodeSignature -LiteralPath $File.FullName
    [pscustomobject]@{
        Date          = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Computer      = $env:COMPUTERNAME
        Operator      = $operator
        Type          = $Type
        File          = $File.Name
        KB            = [regex]::Match($File.Name, 'KB\d{6,8}', 'IgnoreCase').Value.ToUpper()
        SHA256        = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash
        Signature     = "$($sig.Status) $(if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject.Split(',')[0] })"
        ExitCode      = $ExitCode
        Result        = $Result
        VersionBefore = $Before
        VersionAfter  = $After
    } | Export-Csv -LiteralPath $logFile -NoTypeInformation -Append -Encoding UTF8
}

$rebootNeeded = $false

# ---------------------------------------------------------------------------
# AV update
# ---------------------------------------------------------------------------
if (-not $OSOnly) {
    Write-Host "`nAV UPDATE  ($AVFolder)" -ForegroundColor Cyan
    $avFiles = @()
    if (Test-Path -LiteralPath $AVFolder) {
        $avFiles += @(Get-ChildItem -LiteralPath $AVFolder -Filter 'UpdatePlatform*.exe' -File | Sort-Object LastWriteTime | Select-Object -Last 1)
        $avFiles += @(Get-ChildItem -LiteralPath $AVFolder -Filter 'mpam-fe*.exe' -File | Sort-Object LastWriteTime | Select-Object -Last 1)
    }
    if ($avFiles.Count -eq 0) {
        Write-Host '  No mpam-fe.exe or UpdatePlatform*.exe found - skipping AV.' -ForegroundColor Yellow
    }
    foreach ($f in $avFiles) {
        $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName
        if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike '*O=Microsoft Corporation*') {
            Write-Host "  $($f.Name): signature is $($sig.Status) / not Microsoft - NOT installed." -ForegroundColor Red
            Write-UpdateLog 'AV' $f '' 'BLOCKED - invalid signature' (Get-AVVersion) ''
            continue
        }
        $before = Get-AVVersion
        Write-Host "  Installing $($f.Name)..."
        $p = Start-Process -FilePath $f.FullName -Wait -PassThru
        Start-Sleep -Seconds 5
        $after = Get-AVVersion
        if ($p.ExitCode -ne 0) { $result = 'FAILED' }
        elseif ($after -eq $before) { $result = 'SUCCESS - already current (no version change)' }
        else { $result = 'SUCCESS' }
        Write-Host "  $result" -ForegroundColor $(if ($result -like 'FAILED*') { 'Red' } else { 'Green' })
        Write-Host "    Before: $before"
        Write-Host "    After : $after"
        Write-UpdateLog 'AV' $f $p.ExitCode $result $before $after
    }
}

# ---------------------------------------------------------------------------
# OS updates
# ---------------------------------------------------------------------------
if (-not $AVOnly) {
    Write-Host "`nOS UPDATES  ($OSFolder)" -ForegroundColor Cyan
    $osFiles = @()
    if (Test-Path -LiteralPath $OSFolder) {
        $osFiles = @(Get-ChildItem -LiteralPath $OSFolder -File | Where-Object { $_.Extension -in '.msu', '.cab' } | Sort-Object Name)
    }
    if ($osFiles.Count -eq 0) {
        Write-Host '  No .msu or .cab files found - skipping OS updates.' -ForegroundColor Yellow
    }
    foreach ($f in $osFiles) {
        $before = Get-OSBuild
        Write-Host "  Installing $($f.Name) (cumulative updates can take 10-60 minutes)..."
        $dismArgs = @('/Online', '/Add-Package', "/PackagePath:`"$($f.FullName)`"", '/Quiet', '/NoRestart')
        $p = Start-Process -FilePath "$env:SystemRoot\System32\dism.exe" -ArgumentList $dismArgs -Wait -PassThru -NoNewWindow
        $code = $p.ExitCode
        switch ($code) {
            0           { $result = 'SUCCESS' }
            3010        { $result = 'SUCCESS - reboot required'; $rebootNeeded = $true }
            -2146498530 { $result = 'NOT APPLICABLE (0x800F081E) - wrong version/architecture or already superseded' }
            -2146498525 { $result = 'FAILED (0x800F0823) - newer servicing stack/checkpoint update required first' }
            default     { $result = 'FAILED (0x{0:X8}) - see C:\Windows\Logs\DISM\dism.log' -f $code }
        }
        Write-Host "  $result" -ForegroundColor $(if ($result -like 'FAILED*') { 'Red' } elseif ($result -like 'NOT*') { 'Yellow' } else { 'Green' })
        Write-UpdateLog 'OS' $f $code $result $before (Get-OSBuild)
    }
}

Write-Host "`nUpdate log: $logFile" -ForegroundColor Green
if ($rebootNeeded -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')) {
    Write-Host 'REBOOT REQUIRED to finish installing updates. The new build shows after restart.' -ForegroundColor Yellow
}
