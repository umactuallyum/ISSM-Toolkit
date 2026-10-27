# Update Search Guide

Copy each search into Google or the [Microsoft Update Catalog](https://www.catalog.update.microsoft.com). Change the **year-month** (e.g. `2026-11`) and the **version** (run `winver`; 24H2 and 25H2 use the same update).

## Monthly (after Patch Tuesday, the 2nd Tuesday)

| Update | Search | Where |
|---|---|---|
| Windows cumulative update | `2026-10 Cumulative Update for Windows 11 Version 25H2 for x64` | Update Catalog |
| .NET Framework | `2026-10 Cumulative Update for .NET Framework Windows 11 Version 25H2 x64` | Update Catalog |
| Defender platform | `KB4052623` | Update Catalog |
| Confirm the KB number | `Windows 11 version 25H2 update history` | support.microsoft.com |

## Weekly

| Update | Search | Where |
|---|---|---|
| Defender definitions + engine (`mpam-fe.exe`) | `Microsoft Defender Antivirus security intelligence updates` | microsoft.com/wdsi/defenderupdates > "Manually download" > Windows 10 and Windows 11 > **64-bit** |

## Pick the right result

- **Take:** `x64-based Systems`, your version, newest **Last Updated**
- **Skip:** `Preview`, `Dynamic Update`, `arm64`, `Server`
- **Multiple .msu files listed?** Download all of them into the same folder (checkpoint update)
- **Rename** the definitions file with the date: `mpam-fe_2026-10-19.exe`
- **Record** the KB number / Defender version and SHA-256 in the transfer log

## Put files here on the air-gapped system

| Files | Folder |
|---|---|
| `mpam-fe*.exe`, `UpdatePlatform*.exe` | `C:\ISSM_Staging\AV` |
| `.msu` / `.cab` | `C:\ISSM_Staging\OS` |

Then run `Install-Updates.ps1` as Administrator.
