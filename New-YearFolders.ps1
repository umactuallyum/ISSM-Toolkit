<#
.SYNOPSIS
    Creates the yearly records folder template.

    <Root>\2027\
        01_January\
            Week1_01-07\
            Week2_08-14\
            Week3_15-21\
            Week4_22-28\
            Week5_29-31\
            AV_OS_Updates\
        02_February\
        ...

.EXAMPLE
    .\New-YearFolders.ps1 -Year 2027
    .\New-YearFolders.ps1 -Year 2027 -Root 'D:\ISSM_Records'
#>
param(
    [int]$Year = (Get-Date).Year,
    [string]$Root = 'C:\ISSM_Records'
)

$culture = [Globalization.CultureInfo]::InvariantCulture
for ($m = 1; $m -le 12; $m++) {
    $monthFolder = Join-Path (Join-Path $Root $Year) ('{0:D2}_{1}' -f $m, $culture.DateTimeFormat.GetMonthName($m))
    $daysInMonth = [DateTime]::DaysInMonth($Year, $m)
    for ($w = 1; $w -le 5; $w++) {
        $first = ($w - 1) * 7 + 1
        if ($first -gt $daysInMonth) { break }
        $last = [Math]::Min($w * 7, $daysInMonth)
        New-Item -ItemType Directory -Force -Path (Join-Path $monthFolder ('Week{0}_{1:D2}-{2:D2}' -f $w, $first, $last)) | Out-Null
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $monthFolder 'AV_OS_Updates') | Out-Null
}
Write-Host "Created $Year folders under $Root" -ForegroundColor Green
