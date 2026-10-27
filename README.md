# ISSM Weekly Toolkit - Windows 11 Enterprise (Moderate, Air-Gapped)

| File | What it is |
|---|---|
| `Run-All.ps1` / `Run-All.bat` | Runs the event review, password report, and update install in one go |
| `Apply-AuditSettings.ps1` | Turns on all 28 STIG audit subcategories, logging settings and log sizes (backs up first, then verifies) |
| `Audit_Settings_Fix_Text.md` | STIG-style fix text for each audit setting (GPO path, command, registry) |
| `GPO\audit.csv`, `GPO\registry.pol` | The same settings as Group Policy files (import with LGPO.exe or into a domain GPO) |
| `Event_ID_Moderate_Baseline_Mapping.md` | Every Event ID, which ones to review weekly (NISPOM / DCSA), and the NIST 800-53 controls each supports |
| `Weekly-EventLog-Review.ps1` | Checks audit settings, then pulls 88 Event IDs (60 marked for weekly review, incl. printing) + update events (Setup 2, 3, 4; 19, 20; 2000, 2001) for the last 7 days into CSVs and `.evtx` files |
| `Install-Updates.ps1` | Installs the AV update (`mpam-fe.exe`) and OS updates (`.msu`/`.cab`) and writes `Update_Log.csv` |
| `User-Password-Report.ps1` | Lists each user's last logon, last password change, and next change due (60 days), saved as CSV |
| `Update_Search_Guide.md` | Copy-paste searches to find the right Windows, .NET and Defender updates each month/week |
| `New-YearFolders.ps1` | Builds next year's folder template (the zip has it pre-built) |

## Folder layout

```
C:\ISSM_Records\2027\
    01_January\
        Week1_01-07\        weekly WeeklyReview.csv (start here), Events.csv, EventCounts.csv, AuditSettings.csv, .evtx files
        Week2_08-14\
        Week3_15-21\
        Week4_22-28\
        Week5_29-31\
        AV_OS_Updates\      OS_Updates.csv, AV_Updates.csv, Setup/Defender .evtx, Update_Log.csv
    02_February\
    ...
```

Extract the template zip to `C:\` (or change `-Root` on each script).

## Root directories (change these if needed)

Every script uses these default locations. Change them to fit your system, either permanently in the script or for a single run.

| Directory | Default | Used for | Set in |
|---|---|---|---|
| Records root | `C:\ISSM_Records` | Year / month / week folders where all CSVs, `.evtx` files and logs are saved | `Weekly-EventLog-Review.ps1` line 31<br>`Install-Updates.ps1` line 31<br>`User-Password-Report.ps1` line 32<br>`New-YearFolders.ps1` line 22 |
| AV staging | `C:\ISSM_Staging\AV` | Where you place `mpam-fe.exe` / `UpdatePlatform*.exe` before installing | `Install-Updates.ps1` line 29 |
| OS staging | `C:\ISSM_Staging\OS` | Where you place the `.msu` / `.cab` update files before installing | `Install-Updates.ps1` line 30 |

**Permanent change:** open the script in Notepad or PowerShell ISE and edit the path inside the quotes on the line listed, for example:

```powershell
[string]$Root = 'D:\ISSM_Records',
```

Use the same records root in all four scripts so everything lands in the same folder tree.

**One-time change:** pass the path when you run the script:

```powershell
.\Weekly-EventLog-Review.ps1 -Root 'D:\ISSM_Records'
.\User-Password-Report.ps1  -Root 'D:\ISSM_Records'
.\New-YearFolders.ps1       -Root 'D:\ISSM_Records' -Year 2027
.\Install-Updates.ps1       -Root 'D:\ISSM_Records' -AVFolder 'E:\Transfer\AV' -OSFolder 'E:\Transfer\OS'
```

If you move the records root, extract the template zip to the new location (for example `D:\`) so the year folders sit directly under it.

## Run everything at once

Right-click **`Run-All.bat`** > **Run as administrator**, or in an Administrator PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\Run-All.ps1
```

It asks you to confirm the system clock, then runs, in order:
1. `Install-Updates.ps1` - only if update files are in the staging folders (runs first so the review records the installs)
2. `Weekly-EventLog-Review.ps1`
3. `User-Password-Report.ps1`

If one step fails the others still run, and a summary shows OK / FAILED / SKIPPED for each.

| Option | Does |
|---|---|
| `-SkipUpdates` | Don't install updates this run |
| `-Days 14` | Review more than 7 days (missed a week) |
| `-Domain` | Password report on Active Directory accounts |
| `-Root 'D:\ISSM_Records'` | Different records folder (also `-AVFolder`, `-OSFolder`) |
| `-NoClockCheck` | Skip the clock confirmation prompt |

The defaults in `Run-All.ps1` (lines 27-30) are passed to every script, so if you change the root directories, change them there too.

## Weekly (Monday)

Open PowerShell **as Administrator** in this folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\Weekly-EventLog-Review.ps1
```

Reviews from midnight 7 days ago up to the moment you run it, and files the results in the week folder for today's date. Running every Monday overlaps slightly with the previous run, so nothing is missed.

**Start with `<HOST>_<date>_WeeklyReview.csv`.** It holds only the 60 events to review each week. `Events.csv` has everything, with a `WeeklyReview` column: **Review** (look at weekly), **Filter** (4688 / 4104 - search when needed) or **Archive** (kept for evidence).

## User / password report

```powershell
powershell -ExecutionPolicy Bypass -File .\User-Password-Report.ps1            # local accounts
powershell -ExecutionPolicy Bypass -File .\User-Password-Report.ps1 -Domain    # Active Directory accounts
```

Saves `<HOST>_<date>_User_Password_Report.csv` in the current week folder. Status: EXPIRED, DUE SOON (7 days), OK, NEVER SET.

## Installing updates

1. Copy the transferred files to the staging folders:
   - `C:\ISSM_Staging\AV\` - `mpam-fe.exe` (and `UpdatePlatform*.exe` once a month)
   - `C:\ISSM_Staging\OS\` - the `.msu` / `.cab` files
2. Run as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-Updates.ps1           # AV then OS
powershell -ExecutionPolicy Bypass -File .\Install-Updates.ps1 -AVOnly
powershell -ExecutionPolicy Bypass -File .\Install-Updates.ps1 -OSOnly
```

3. Reboot if told to. The next weekly review captures the install events (Setup log 2/4, Defender 2000/2002) in `AV_OS_Updates`.

## Defender offline packages

| Package | Contains | How often |
|---|---|---|
| `mpam-fe.exe` | Security intelligence (definitions) **and** the antimalware engine | Weekly or more |
| `UpdatePlatform*.exe` | Defender platform (the antivirus client / service itself) | Monthly |

## Notes

- Some Event IDs only appear if auditing is enabled - see "Audit settings required" in the mapping file.
- If Group Policy enforces signed scripts, `-ExecutionPolicy Bypass` will not work; sign the scripts with your code-signing certificate.
