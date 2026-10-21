#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Weekly Event Viewer pull for the ISSM.

.DESCRIPTION
    Run every Monday as Administrator. Reviews from midnight 7 days ago up to the moment it runs.

    Into the WEEK folder  (<Root>\<Year>\<MM_Month>\WeekN_dd-dd\):
        <HOST>_<date>_AuditSettings.csv   PASS/FAIL for the audit settings each Event ID needs (AU-12)
        <HOST>_<date>_WeeklyReview.csv    ONLY the events to review each week (start here)
        <HOST>_<date>_Events.csv          every monitored Event ID with key fields (Review, Filter, Archive)
        <HOST>_<date>_EventCounts.csv     count per Event ID (zeros included)
        <HOST>_<date>_Security.evtx       raw logs for the 7 days (open in Event Viewer)
        <HOST>_<date>_System.evtx
        <HOST>_<date>_PowerShell.evtx
        <HOST>_<date>_PrintService.evtx

    Into the month's AV_OS_Updates folder:
        <HOST>_<date>_OS_Updates.csv      Windows update installs/failures (Setup log 2, 3, 4 for manual installs; System log 19, 20)
        <HOST>_<date>_AV_Updates.csv      Defender definition updates (2000) and failures (2001; Note column marks expected offline failures)
        <HOST>_<date>_Setup.evtx
        <HOST>_<date>_Defender.evtx

    Folders are created automatically if missing.

    WHERE TO FIND EACH EVENT
    ------------------------
    Event Viewer: Start > type "Event Viewer" > open the log path below > Filter Current Log > enter the Event ID.
    Script output: Review events -> WeeklyReview.csv AND Events.csv; Filter/Archive events -> Events.csv only.
    Every event also stays in the raw .evtx copy for its log (open with Event Viewer > Action > Open Saved Log).

    Log                      Event Viewer path, then saved .evtx copy
    Security                 Windows Logs > Security
                             -> Week folder\<HOST>_<date>_Security.evtx
    System                   Windows Logs > System
                             -> Week folder\<HOST>_<date>_System.evtx
    PowerShell/Operational   Applications and Services Logs > Microsoft > Windows > PowerShell > Operational
                             -> Week folder\<HOST>_<date>_PowerShell.evtx
    Defender/Operational     Applications and Services Logs > Microsoft > Windows > Windows Defender > Operational
                             -> AV_OS_Updates\<HOST>_<date>_Defender.evtx
    PrintService/Operational Applications and Services Logs > Microsoft > Windows > PrintService > Operational
                             -> Week folder\<HOST>_<date>_PrintService.evtx
    Setup                    Windows Logs > Setup
                             -> AV_OS_Updates\<HOST>_<date>_Setup.evtx

    ID     Tier     Log                       Description
    104    Review   System                    Event log cleared (System, Application or other log)
    307    Review   PrintService/Operational  Document printed (user, document, printer, pages)
    1074   Review   System                    Shutdown or restart initiated (by user or process)
    1100   Review   Security                  Event logging service shut down
    1102   Review   Security                  Security audit log cleared
    1104   Review   Security                  Security log is full
    1105   Archive  Security                  Security log archived automatically
    1108   Review   Security                  Event logging service error
    1116   Review   Defender/Operational      Malware detected
    1117   Review   Defender/Operational      Action taken on malware
    1118   Review   Defender/Operational      Malware remediation failed
    1119   Review   Defender/Operational      Critical malware remediation failure
    4104   Filter   PowerShell/Operational    PowerShell script block executed
    4608   Review   Security                  Windows is starting up
    4612   Review   Security                  Audit resources exhausted - audit messages lost
    4616   Review   Security                  System time changed
    4624   Review   Security                  Successful account logon
    4625   Review   Security                  Failed account logon
    4634   Review   Security                  Account logged off
    4647   Review   Security                  User initiated logoff
    4648   Review   Security                  Logon with explicit credentials (run as)
    4656   Archive  Security                  Handle to an object requested
    4657   Archive  Security                  Registry value modified
    4660   Review   Security                  Object deleted
    4663   Review   Security                  Attempt to access an object
    4670   Review   Security                  Permissions on an object changed
    4672   Review   Security                  Special (admin) privileges assigned to new logon
    4688   Filter   Security                  New process created (program run, with command line)
    4697   Review   Security                  Service installed (Security log)
    4698   Review   Security                  Scheduled task created
    4699   Archive  Security                  Scheduled task deleted
    4700   Archive  Security                  Scheduled task enabled
    4701   Archive  Security                  Scheduled task disabled
    4702   Review   Security                  Scheduled task updated
    4704   Review   Security                  User right assigned
    4705   Review   Security                  User right removed
    4713   Archive  Security                  Kerberos policy changed
    4715   Review   Security                  Audit policy (SACL) on an object changed
    4719   Review   Security                  System audit policy changed
    4720   Review   Security                  User account created
    4722   Review   Security                  User account enabled
    4723   Review   Security                  User changed own password
    4724   Review   Security                  Password reset by another account
    4725   Review   Security                  User account disabled
    4726   Review   Security                  User account deleted
    4728   Archive  Security                  Member added to domain global group (domain only)
    4729   Archive  Security                  Member removed from domain global group (domain only)
    4731   Review   Security                  Local security group created
    4732   Review   Security                  Member added to local security group
    4733   Review   Security                  Member removed from local security group
    4734   Review   Security                  Local security group deleted
    4735   Review   Security                  Local security group changed
    4738   Review   Security                  User account changed
    4739   Archive  Security                  Domain policy changed (domain only)
    4740   Review   Security                  User account locked out
    4756   Archive  Security                  Member added to domain universal group (domain only)
    4757   Archive  Security                  Member removed from domain universal group (domain only)
    4767   Review   Security                  User account unlocked
    4776   Archive  Security                  Credential validation (local account logon attempt)
    4778   Archive  Security                  Session reconnected (RDP / fast user switching)
    4779   Archive  Security                  Session disconnected
    4781   Review   Security                  Account name changed
    4800   Review   Security                  Workstation locked
    4801   Review   Security                  Workstation unlocked
    4802   Archive  Security                  Screen saver invoked
    4803   Archive  Security                  Screen saver dismissed
    4912   Review   Security                  Per-user audit policy changed
    4946   Review   Security                  Firewall rule added
    4947   Review   Security                  Firewall rule modified
    4948   Review   Security                  Firewall rule deleted
    4950   Archive  Security                  Firewall setting changed
    5001   Review   Defender/Operational      Real-time protection disabled
    5004   Archive  Defender/Operational      Real-time protection configuration changed
    5007   Review   Defender/Operational      Defender configuration changed (e.g., exclusions)
    5010   Archive  Defender/Operational      Antispyware scanning disabled
    5012   Archive  Defender/Operational      Antivirus scanning disabled
    5013   Review   Defender/Operational      Tamper protection blocked a change
    5038   Review   Security                  Code integrity: file hash not valid
    5140   Archive  Security                  Network share accessed
    5142   Archive  Security                  Network share added
    5143   Archive  Security                  Network share modified
    5144   Archive  Security                  Network share deleted
    6005   Review   System                    Event log service started (system boot)
    6006   Review   System                    Event log service stopped (clean shutdown)
    6008   Review   System                    Unexpected shutdown
    6416   Review   Security                  New external device recognized (USB / removable)
    7040   Archive  System                    Service start type changed
    7045   Review   System                    New service installed
    --- Update events (month folder\AV_OS_Updates) ---
    19     Update   System                    Windows update installed           -> <HOST>_<date>_OS_Updates.csv
    20     Update   System                    Windows update failed              -> <HOST>_<date>_OS_Updates.csv
    2000   Update   Defender/Operational      Defender definitions updated       -> <HOST>_<date>_AV_Updates.csv
    2001   Update   Defender/Operational      Defender definitions update failed -> <HOST>_<date>_AV_Updates.csv

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Weekly-EventLog-Review.ps1

.EXAMPLE
    .\Weekly-EventLog-Review.ps1 -Days 14 -Root 'D:\ISSM_Records'
#>
param(
    [string]$Root = 'C:\ISSM_Records',
    [int]$Days = 7,
    [switch]$IncludeToday   # kept so older commands still work; now always on
)

$ErrorActionPreference = 'Stop'
$computer = $env:COMPUTERNAME

# ---------------------------------------------------------------------------
# Event IDs reviewed each week
# ---------------------------------------------------------------------------
$Monitored = @(
    # WeeklyReview: Review = look at every week | Filter = search when needed | Archive = kept in CSV/.evtx, no weekly review
    # Process & Execution
    @{ Id = 4688; Log = 'Security'; Description = 'New process created (program run, with command line)'; Control = 'AU-12, SI-4'; Provider = ''; Flag = $false; WeeklyReview = 'Filter' },
    @{ Id = 4104; Log = 'Microsoft-Windows-PowerShell/Operational'; Description = 'PowerShell script block executed'; Control = 'AU-12, SI-4'; Provider = ''; Flag = $false; WeeklyReview = 'Filter' },
    @{ Id = 7045; Log = 'System'; Description = 'New service installed'; Control = 'CM-7, SI-4'; Provider = 'Service Control Manager'; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4697; Log = 'Security'; Description = 'Service installed (Security log)'; Control = 'CM-7, SI-4'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 7040; Log = 'System'; Description = 'Service start type changed'; Control = 'CM-7'; Provider = 'Service Control Manager'; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4698; Log = 'Security'; Description = 'Scheduled task created'; Control = 'CM-7, SI-4'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4699; Log = 'Security'; Description = 'Scheduled task deleted'; Control = 'CM-7, SI-4'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4700; Log = 'Security'; Description = 'Scheduled task enabled'; Control = 'CM-7, SI-4'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4701; Log = 'Security'; Description = 'Scheduled task disabled'; Control = 'CM-7, SI-4'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4702; Log = 'Security'; Description = 'Scheduled task updated'; Control = 'CM-7, SI-4'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 5038; Log = 'Security'; Description = 'Code integrity: file hash not valid'; Control = 'SI-7'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    # Logon, Logoff & Sessions
    @{ Id = 4624; Log = 'Security'; Description = 'Successful account logon'; Control = 'AC-12, AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4625; Log = 'Security'; Description = 'Failed account logon'; Control = 'AC-7'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4648; Log = 'Security'; Description = 'Logon with explicit credentials (run as)'; Control = 'AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4672; Log = 'Security'; Description = 'Special (admin) privileges assigned to new logon'; Control = 'AC-6, AC-6(9)'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4634; Log = 'Security'; Description = 'Account logged off'; Control = 'AC-12'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4647; Log = 'Security'; Description = 'User initiated logoff'; Control = 'AC-12'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4778; Log = 'Security'; Description = 'Session reconnected (RDP / fast user switching)'; Control = 'AC-12, AC-17'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4779; Log = 'Security'; Description = 'Session disconnected'; Control = 'AC-12, AC-17'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4800; Log = 'Security'; Description = 'Workstation locked'; Control = 'AC-11'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4801; Log = 'Security'; Description = 'Workstation unlocked'; Control = 'AC-11'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4802; Log = 'Security'; Description = 'Screen saver invoked'; Control = 'AC-11'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4803; Log = 'Security'; Description = 'Screen saver dismissed'; Control = 'AC-11'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4776; Log = 'Security'; Description = 'Credential validation (local account logon attempt)'; Control = 'AC-7, IA-2'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4740; Log = 'Security'; Description = 'User account locked out'; Control = 'AC-7'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4767; Log = 'Security'; Description = 'User account unlocked'; Control = 'AC-7'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    # Account & Group Management
    @{ Id = 4720; Log = 'Security'; Description = 'User account created'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4722; Log = 'Security'; Description = 'User account enabled'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4725; Log = 'Security'; Description = 'User account disabled'; Control = 'AC-2'; Provider = ''; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 4726; Log = 'Security'; Description = 'User account deleted'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4738; Log = 'Security'; Description = 'User account changed'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4781; Log = 'Security'; Description = 'Account name changed'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4723; Log = 'Security'; Description = 'User changed own password'; Control = 'AC-2, IA-5'; Provider = ''; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 4724; Log = 'Security'; Description = 'Password reset by another account'; Control = 'AC-2, IA-5'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4731; Log = 'Security'; Description = 'Local security group created'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4734; Log = 'Security'; Description = 'Local security group deleted'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4735; Log = 'Security'; Description = 'Local security group changed'; Control = 'AC-2'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4732; Log = 'Security'; Description = 'Member added to local security group'; Control = 'AC-2, AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4733; Log = 'Security'; Description = 'Member removed from local security group'; Control = 'AC-2, AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4728; Log = 'Security'; Description = 'Member added to domain global group (domain only)'; Control = 'AC-2, AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 4729; Log = 'Security'; Description = 'Member removed from domain global group (domain only)'; Control = 'AC-2, AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 4756; Log = 'Security'; Description = 'Member added to domain universal group (domain only)'; Control = 'AC-2, AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 4757; Log = 'Security'; Description = 'Member removed from domain universal group (domain only)'; Control = 'AC-2, AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 4704; Log = 'Security'; Description = 'User right assigned'; Control = 'AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4705; Log = 'Security'; Description = 'User right removed'; Control = 'AC-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    # File, Share & Object Access
    @{ Id = 4656; Log = 'Security'; Description = 'Handle to an object requested'; Control = 'AU-12, AC-3'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 4663; Log = 'Security'; Description = 'Attempt to access an object'; Control = 'AU-12, AC-3'; Provider = ''; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 4660; Log = 'Security'; Description = 'Object deleted'; Control = 'AU-12, AC-3'; Provider = ''; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 4670; Log = 'Security'; Description = 'Permissions on an object changed'; Control = 'AC-3, CM-5'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4657; Log = 'Security'; Description = 'Registry value modified'; Control = 'CM-5, SI-4'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 5140; Log = 'Security'; Description = 'Network share accessed'; Control = 'AC-3'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 5142; Log = 'Security'; Description = 'Network share added'; Control = 'CM-7, AC-3'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 5143; Log = 'Security'; Description = 'Network share modified'; Control = 'CM-7, AC-3'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 5144; Log = 'Security'; Description = 'Network share deleted'; Control = 'CM-7, AC-3'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 6416; Log = 'Security'; Description = 'New external device recognized (USB / removable)'; Control = 'MP-7'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    # Audit, Logging & Time
    @{ Id = 1102; Log = 'Security'; Description = 'Security audit log cleared'; Control = 'AU-9'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 104; Log = 'System'; Description = 'Event log cleared (System, Application or other log)'; Control = 'AU-9'; Provider = 'Microsoft-Windows-Eventlog'; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1100; Log = 'Security'; Description = 'Event logging service shut down'; Control = 'AU-9, AU-5'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1104; Log = 'Security'; Description = 'Security log is full'; Control = 'AU-5, AU-4'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1105; Log = 'Security'; Description = 'Security log archived automatically'; Control = 'AU-4, AU-11'; Provider = ''; Flag = $false; WeeklyReview = 'Archive' },
    @{ Id = 1108; Log = 'Security'; Description = 'Event logging service error'; Control = 'AU-5'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4612; Log = 'Security'; Description = 'Audit resources exhausted - audit messages lost'; Control = 'AU-5'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4715; Log = 'Security'; Description = 'Audit policy (SACL) on an object changed'; Control = 'AU-9'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4719; Log = 'Security'; Description = 'System audit policy changed'; Control = 'AU-9, AU-12, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4912; Log = 'Security'; Description = 'Per-user audit policy changed'; Control = 'AU-9, AU-12'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4616; Log = 'Security'; Description = 'System time changed'; Control = 'AU-8'; Provider = ''; Flag = $false; WeeklyReview = 'Review' },
    # Startup & Shutdown
    @{ Id = 4608; Log = 'Security'; Description = 'Windows is starting up'; Control = 'AU-5, CP-10'; Provider = ''; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 6005; Log = 'System'; Description = 'Event log service started (system boot)'; Control = 'AU-5, CP-10'; Provider = 'EventLog'; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 6006; Log = 'System'; Description = 'Event log service stopped (clean shutdown)'; Control = 'AU-5'; Provider = 'EventLog'; Flag = $false; WeeklyReview = 'Review' },
    @{ Id = 6008; Log = 'System'; Description = 'Unexpected shutdown'; Control = 'AU-5, CP-10'; Provider = 'EventLog'; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1074; Log = 'System'; Description = 'Shutdown or restart initiated (by user or process)'; Control = 'AU-5'; Provider = 'User32'; Flag = $false; WeeklyReview = 'Review' },
    # Firewall & Security Policy
    @{ Id = 4946; Log = 'Security'; Description = 'Firewall rule added'; Control = 'SC-7, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4947; Log = 'Security'; Description = 'Firewall rule modified'; Control = 'SC-7, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4948; Log = 'Security'; Description = 'Firewall rule deleted'; Control = 'SC-7, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 4950; Log = 'Security'; Description = 'Firewall setting changed'; Control = 'SC-7, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 4713; Log = 'Security'; Description = 'Kerberos policy changed'; Control = 'IA-5, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 4739; Log = 'Security'; Description = 'Domain policy changed (domain only)'; Control = 'AC-7, IA-5, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    # Malware Protection (Defender)
    @{ Id = 1116; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Malware detected'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1117; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Action taken on malware'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1118; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Malware remediation failed'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 1119; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Critical malware remediation failure'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 5001; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Real-time protection disabled'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 5004; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Real-time protection configuration changed'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 5007; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Defender configuration changed (e.g., exclusions)'; Control = 'SI-3, CM-6'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    @{ Id = 5010; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Antispyware scanning disabled'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 5012; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Antivirus scanning disabled'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Archive' },
    @{ Id = 5013; Log = 'Microsoft-Windows-Windows Defender/Operational'; Description = 'Tamper protection blocked a change'; Control = 'SI-3'; Provider = ''; Flag = $true; WeeklyReview = 'Review' },
    # Printing
    @{ Id = 307; Log = 'Microsoft-Windows-PrintService/Operational'; Description = 'Document printed (user, document, printer, pages)'; Control = 'AU-12, PE-5'; Provider = 'Microsoft-Windows-PrintService'; Flag = $false; WeeklyReview = 'Review' }
)

$UpdateEvents = @(
    @{ Type = 'OS'; Log = 'System'; Provider = 'Microsoft-Windows-WindowsUpdateClient'; Ids = @(19, 20) },
    # Manual installs (DISM / Install-Updates.ps1 / double-clicked .msu) are logged here, not as 19/20
    @{ Type = 'OS'; Log = 'Setup'; Provider = 'Microsoft-Windows-Servicing'; Ids = @(2, 3, 4) },
    @{ Type = 'AV'; Log = 'Microsoft-Windows-Windows Defender/Operational'; Provider = ''; Ids = @(2000, 2001) }
)

# Where each log lives in Event Viewer, and where the script saves its raw copy
$LogLocations = @{
    'Security'                                       = @{ Viewer = 'Event Viewer > Windows Logs > Security'; Evtx = 'Security.evtx (week folder)' }
    'System'                                         = @{ Viewer = 'Event Viewer > Windows Logs > System'; Evtx = 'System.evtx (week folder)' }
    'Setup'                                          = @{ Viewer = 'Event Viewer > Windows Logs > Setup'; Evtx = 'Setup.evtx (AV_OS_Updates)' }
    'Microsoft-Windows-PowerShell/Operational'       = @{ Viewer = 'Event Viewer > Applications and Services Logs > Microsoft > Windows > PowerShell > Operational'; Evtx = 'PowerShell.evtx (week folder)' }
    'Microsoft-Windows-Windows Defender/Operational' = @{ Viewer = 'Event Viewer > Applications and Services Logs > Microsoft > Windows > Windows Defender > Operational'; Evtx = 'Defender.evtx (AV_OS_Updates)' }
    'Microsoft-Windows-PrintService/Operational'     = @{ Viewer = 'Event Viewer > Applications and Services Logs > Microsoft > Windows > PrintService > Operational'; Evtx = 'PrintService.evtx (week folder)' }
}
function Get-FoundIn {
    param([string]$Tier, [string]$Log)
    $csv = $(if ($Tier -eq 'Review') { 'WeeklyReview.csv + Events.csv' } else { 'Events.csv' })
    '{0}; raw: {1}' -f $csv, $LogLocations[$Log].Evtx
}
$UpdateDescriptions = @{
    'OS-19' = 'Update installed (Windows Update client)'; 'OS-20' = 'Update install FAILED (Windows Update client)'
    'OS-2' = 'Update package installed'; 'OS-3' = 'Update package FAILED'; 'OS-4' = 'Update requires reboot'
    'AV-2000' = 'Security intelligence (definitions) updated'; 'AV-2001' = 'Security intelligence update FAILED'
    'AV-2002' = 'Engine updated'; 'AV-2003' = 'Engine update FAILED'
}

# Audit settings that must be ON for the Event IDs above to be generated (AU-12).
# GUIDs are used so the check works on any display language.
$AuditSettings = @(
    @{ Name = 'Credential Validation'; Guid = '{0CCE923F-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4776' },
    @{ Name = 'Other Account Management Events'; Guid = '{0CCE923A-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4782, 4793' },
    @{ Name = 'Security Group Management'; Guid = '{0CCE9237-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4727-4735, 4754-4758' },
    @{ Name = 'User Account Management'; Guid = '{0CCE9235-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4720, 4722-4726, 4738, 4740, 4767, 4781' },
    @{ Name = 'PNP Activity'; Guid = '{0CCE9248-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '6416' },
    @{ Name = 'Process Creation'; Guid = '{0CCE922B-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4688' },
    @{ Name = 'Account Lockout'; Guid = '{0CCE9217-69AE-11D9-BED3-505054503030}'; Success = $false; Failure = $true; Events = '4625 (locked account)' },
    @{ Name = 'Group Membership'; Guid = '{0CCE9249-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4627' },
    @{ Name = 'Logoff'; Guid = '{0CCE9216-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4634, 4647' },
    @{ Name = 'Logon'; Guid = '{0CCE9215-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4624, 4625, 4648' },
    @{ Name = 'Other Logon/Logoff Events'; Guid = '{0CCE921C-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4778, 4779, 4800-4803' },
    @{ Name = 'Special Logon'; Guid = '{0CCE921B-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4672, 4964' },
    @{ Name = 'File Share'; Guid = '{0CCE9224-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '5140, 5142-5144' },
    @{ Name = 'File System'; Guid = '{0CCE921D-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4656, 4660, 4663, 4670' },
    @{ Name = 'Other Object Access Events'; Guid = '{0CCE9227-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4698-4702' },
    @{ Name = 'Registry'; Guid = '{0CCE921E-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4657' },
    @{ Name = 'Removable Storage'; Guid = '{0CCE9245-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4656, 4663 (USB / removable media)' },
    @{ Name = 'Audit Policy Change'; Guid = '{0CCE922F-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4715, 4719, 4912' },
    @{ Name = 'Authentication Policy Change'; Guid = '{0CCE9230-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4706, 4707, 4713, 4739' },
    @{ Name = 'Authorization Policy Change'; Guid = '{0CCE9231-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4704, 4705' },
    @{ Name = 'MPSSVC Rule-Level Policy Change'; Guid = '{0CCE9232-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4946-4950' },
    @{ Name = 'Other Policy Change Events'; Guid = '{0CCE9234-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = 'STIG requirement' },
    @{ Name = 'Sensitive Privilege Use'; Guid = '{0CCE9228-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4673, 4674' },
    @{ Name = 'IPsec Driver'; Guid = '{0CCE9213-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4960-4965' },
    @{ Name = 'Other System Events'; Guid = '{0CCE9214-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '5024-5027 (firewall service)' },
    @{ Name = 'Security State Change'; Guid = '{0CCE9210-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4608, 4616' },
    @{ Name = 'Security System Extension'; Guid = '{0CCE9211-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $false; Events = '4697, 4610, 4611, 4614, 4622' },
    @{ Name = 'System Integrity'; Guid = '{0CCE9212-69AE-11D9-BED3-505054503030}'; Success = $true; Failure = $true; Events = '4612, 5038, 6281' }
)
$RegistrySettings = @(
    @{ Name = 'Include command line in process creation events'; Path = 'HKLM:\\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit'; Value = 'ProcessCreationIncludeCmdLine_Enabled'; Expected = 1; Events = '4688 command line' },
    @{ Name = 'PowerShell Script Block Logging'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'; Value = 'EnableScriptBlockLogging'; Expected = 1; Events = '4104' },
    @{ Name = 'Force audit policy subcategory settings'; Path = 'HKLM:\\System\CurrentControlSet\Control\Lsa'; Value = 'SCENoApplyLegacyAuditPolicy'; Expected = 1; Events = 'all subcategories' },
    @{ Name = 'Security log maximum size (KB)'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\EventLog\Security'; Value = 'MaxSize'; Expected = 1024000; Events = 'AU-4' },
    @{ Name = 'Application log maximum size (KB)'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\EventLog\Application'; Value = 'MaxSize'; Expected = 32768; Events = 'AU-4' },
    @{ Name = 'System log maximum size (KB)'; Path = 'HKLM:\\Software\Policies\Microsoft\Windows\EventLog\System'; Value = 'MaxSize'; Expected = 32768; Events = 'AU-4' }
)

# ---------------------------------------------------------------------------
# Period and folders
# ---------------------------------------------------------------------------
$end = Get-Date                         # right now - includes everything up to the moment it runs
$start = $end.Date.AddDays(-$Days)      # midnight, 7 days ago (a small overlap with last week's run is intentional - no gaps)
$lastDay = $end.Date                    # filed under today's date / week folder
$stamp = $lastDay.ToString('yyyy-MM-dd')

$monthName = [Globalization.CultureInfo]::InvariantCulture.DateTimeFormat.GetMonthName($lastDay.Month)
$monthFolder = Join-Path (Join-Path $Root $lastDay.Year) ('{0:D2}_{1}' -f $lastDay.Month, $monthName)
$week = [int][Math]::Ceiling($lastDay.Day / 7)
$weekFirst = ($week - 1) * 7 + 1
$weekLast = [Math]::Min($week * 7, [DateTime]::DaysInMonth($lastDay.Year, $lastDay.Month))
$weekFolder = Join-Path $monthFolder ('Week{0}_{1:D2}-{2:D2}' -f $week, $weekFirst, $weekLast)
$updateFolder = Join-Path $monthFolder 'AV_OS_Updates'
foreach ($f in $weekFolder, $updateFolder) { New-Item -ItemType Directory -Force -Path $f | Out-Null }

Write-Host ''
Write-Host "Weekly event review for $computer" -ForegroundColor Cyan
Write-Host ("Period : {0}  to  {1}" -f $start.ToString('yyyy-MM-dd HH:mm'), $end.AddSeconds(-1).ToString('yyyy-MM-dd HH:mm'))
Write-Host "Week   : $weekFolder"
Write-Host "Updates: $updateFolder"
Write-Host ''

# ---------------------------------------------------------------------------
# 0. Audit settings check (AU-12) - report only, changes nothing
# ---------------------------------------------------------------------------
Write-Host 'Checking audit settings (AU-12)...' -ForegroundColor Cyan
$auditResults = New-Object System.Collections.Generic.List[object]
foreach ($a in $AuditSettings) {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $raw = @(& auditpol.exe /get "/subcategory:$($a.Guid)" /r 2>&1 | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
    $ErrorActionPreference = $prev
    $setting = 'Unable to read'
    if ($raw.Count -ge 2) {
        $setting = [string](($raw[1] | ConvertFrom-Csv -Header 'Machine', 'Target', 'Subcategory', 'Guid', 'Inclusion', 'Exclusion').Inclusion)
    }
    $need = @(); if ($a.Success) { $need += 'Success' }; if ($a.Failure) { $need += 'Failure' }
    $ok = ((-not $a.Success) -or $setting -match 'Success') -and ((-not $a.Failure) -or $setting -match 'Failure')
    $auditResults.Add([pscustomobject]@{ Setting = "Audit $($a.Name)"; Required = ($need -join ' and '); Actual = $setting; Status = $(if ($ok) { 'PASS' } else { 'FAIL' }); Generates = $a.Events })
}
foreach ($rs in $RegistrySettings) {
    if ($rs.Value -eq 'MaxSize') {
        # Check the log's actual maximum size (however it was set)
        $logName = Split-Path -Leaf $rs.Path
        $kb = $null
        try { $kb = [int64]((Get-WinEvent -ListLog $logName -ErrorAction Stop).MaximumSizeInBytes / 1KB) } catch { }
        $auditResults.Add([pscustomobject]@{ Setting = $rs.Name; Required = ">= $($rs.Expected)"; Actual = $(if ($null -eq $kb) { 'Unable to read' } else { "$kb" }); Status = $(if ($kb -ge $rs.Expected) { 'PASS' } else { 'FAIL' }); Generates = $rs.Events })
        continue
    }
    $val = $null
    try { $val = (Get-ItemProperty -LiteralPath $rs.Path -Name $rs.Value -ErrorAction Stop).($rs.Value) } catch { }
    $auditResults.Add([pscustomobject]@{ Setting = $rs.Name; Required = "Enabled ($($rs.Expected))"; Actual = $(if ($null -eq $val) { 'Not set' } else { "$val" }); Status = $(if ($val -eq $rs.Expected) { 'PASS' } else { 'FAIL' }); Generates = $rs.Events })
}
$printEnabled = $null
try { $printEnabled = (Get-WinEvent -ListLog 'Microsoft-Windows-PrintService/Operational' -ErrorAction Stop).IsEnabled } catch { }
$auditResults.Add([pscustomobject]@{ Setting = 'PrintService Operational log enabled'; Required = 'Enabled'; Actual = $(if ($null -eq $printEnabled) { 'Unable to read' } elseif ($printEnabled) { 'Enabled' } else { 'Disabled' }); Status = $(if ($printEnabled) { 'PASS' } else { 'FAIL' }); Generates = '307' })
$auditCsv = Join-Path $weekFolder "$($computer)_$($stamp)_AuditSettings.csv"
$auditResults | Export-Csv -LiteralPath $auditCsv -NoTypeInformation -Encoding UTF8
$auditFails = @($auditResults | Where-Object { $_.Status -ne 'PASS' })
foreach ($ar in $auditResults) {
    $color = $(if ($ar.Status -eq 'PASS') { 'Green' } else { 'Yellow' })
    Write-Host ('  {0,-4}  {1,-50} {2}' -f $ar.Status, $ar.Setting, $ar.Actual) -ForegroundColor $color
}
if ($auditFails.Count) {
    Write-Host "  WARNING: $($auditFails.Count) setting(s) not configured - counts of 0 for these events may not be accurate." -ForegroundColor Yellow
}
Write-Host "  Saved $(Split-Path -Leaf $auditCsv)" -ForegroundColor Green
Write-Host ''

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Get-Events {
    param([string]$LogName, [int[]]$Ids, [string]$Provider)
    # Query in groups of 20 IDs (Windows rejects queries with too many IDs at once)
    for ($i = 0; $i -lt $Ids.Count; $i += 20) {
        $chunk = $Ids[$i..([Math]::Min($i + 19, $Ids.Count - 1))]
        $filter = @{ LogName = $LogName; Id = $chunk; StartTime = $start; EndTime = $end }
        if ($Provider) { $filter.ProviderName = $Provider }
        try {
            Get-WinEvent -FilterHashtable $filter -ErrorAction Stop
        } catch {
            if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') {
                Write-Host "  WARNING: could not read $LogName - $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}

function Get-EventData {
    param($WinEvent)
    $xml = [xml]$WinEvent.ToXml()
    $data = @{}
    foreach ($n in $xml.SelectNodes("//*[local-name()='EventData']/*[local-name()='Data']")) {
        if ($n.GetAttribute('Name')) { $data[$n.GetAttribute('Name')] = $n.InnerText }
    }
    foreach ($n in $xml.SelectNodes("//*[local-name()='UserData']/*/*")) { $data[$n.LocalName] = $n.InnerText }
    $data
}

function Get-Val {
    param($Data, [string]$Key)
    $v = [string]$Data[$Key]
    if ($v -eq '-') { '' } else { $v }
}

$AccessNames = @{
    '%%1537' = 'DELETE'; '%%1538' = 'READ_CONTROL'; '%%1539' = 'WRITE_DAC'; '%%1540' = 'WRITE_OWNER'; '%%1541' = 'SYNCHRONIZE'
    '%%4416' = 'ReadData/ListDirectory'; '%%4417' = 'WriteData/AddFile'; '%%4418' = 'AppendData/AddSubdirectory'
    '%%4419' = 'ReadEA'; '%%4420' = 'WriteEA'; '%%4421' = 'Execute/Traverse'; '%%4422' = 'DeleteChild'
    '%%4423' = 'ReadAttributes'; '%%4424' = 'WriteAttributes'
}
function Convert-AccessList {
    param([string]$Text)
    $parts = @($Text -split '\s+' | Where-Object { $_ })
    ($parts | ForEach-Object { if ($AccessNames.ContainsKey($_)) { $AccessNames[$_] } else { $_ } }) -join ', '
}

function Format-Account {
    param([string]$Domain, [string]$User)
    if (-not $User) { '' } elseif ($Domain) { "$Domain\$User" } else { $User }
}

function Export-Evtx {
    param([string]$LogName, [string]$File)
    $q = "*[System[TimeCreated[@SystemTime>='{0}' and @SystemTime<'{1}']]]" -f `
        $start.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'), $end.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $null = & wevtutil.exe epl $LogName $File "/q:$q" /ow:true 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($code -eq 0) { Write-Host "  Saved $(Split-Path -Leaf $File)" -ForegroundColor Green }
    else { Write-Host "  WARNING: could not export $LogName (exit $code)" -ForegroundColor Yellow }
}

function Format-Message {
    param($WinEvent)
    $m = ''
    try { $m = [string]$WinEvent.Message } catch { }
    ($m -replace '\s+', ' ').Trim()
}

# ---------------------------------------------------------------------------
# 1. Monitored Event IDs -> week folder
# ---------------------------------------------------------------------------
Write-Host 'Pulling monitored Event IDs...' -ForegroundColor Cyan
$logonTypes = @{ '2' = 'Interactive'; '3' = 'Network'; '4' = 'Batch'; '5' = 'Service'; '7' = 'Unlock'; '8' = 'NetworkCleartext'; '9' = 'NewCredentials'; '10' = 'RemoteInteractive (RDP)'; '11' = 'CachedInteractive' }
$descById = @{}
$controlById = @{}
$providerByKey = @{}
$tierById = @{}
foreach ($m in $Monitored) { $descById[[int]$m.Id] = $m.Description; $controlById[[int]$m.Id] = $m.Control; $providerByKey["$($m.Log)|$($m.Id)"] = $m.Provider; $tierById[[int]$m.Id] = $m.WeeklyReview }

$rows = New-Object System.Collections.Generic.List[object]
foreach ($group in ($Monitored | Group-Object { $_.Log })) {
    $ids = @($group.Group | ForEach-Object { [int]$_.Id })
    $events = @(Get-Events -LogName $group.Name -Ids $ids)
    Write-Host ("  {0}: {1} events" -f $group.Name, $events.Count)

    foreach ($e in $events) {
        $prov = $providerByKey["$($e.LogName)|$($e.Id)"]
        if ($prov -and $e.ProviderName -ne $prov) { continue }   # same ID from an unrelated source
        $d = Get-EventData $e
        $subject = Format-Account (Get-Val $d 'SubjectDomainName') (Get-Val $d 'SubjectUserName')
        if ($e.Id -eq 307) { $subject = Get-Val $d 'Param3' }
        if (-not $subject -and $e.UserId) {
            try { $subject = $e.UserId.Translate([Security.Principal.NTAccount]).Value } catch { $subject = $e.UserId.Value }
        }
        if (-not $subject -and (Get-Val $d 'Detection User')) { $subject = Get-Val $d 'Detection User' }
        $target = Format-Account (Get-Val $d 'TargetDomainName') (Get-Val $d 'TargetUserName')
        $group2 = ''
        if ($e.Id -eq 4732 -or $e.Id -eq 4733) {
            $group2 = $target
            $target = Get-Val $d 'MemberName'
            if (-not $target) { $target = Get-Val $d 'MemberSid' }
        }
        $lt = Get-Val $d 'LogonType'
        $process = Get-Val $d 'NewProcessName'
        if (-not $process) { $process = Get-Val $d 'ProcessName' }
        $script = (Get-Val $d 'ScriptBlockText') -replace '\s+', ' '
        if ($script.Length -gt 1000) { $script = $script.Substring(0, 1000) + ' ...[truncated]' }

        $rows.Add([pscustomobject]@{
                TimeCreated   = $e.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')
                Computer      = $e.MachineName
                EventID       = $e.Id
                Description   = $descById[[int]$e.Id]
                WeeklyReview  = $tierById[[int]$e.Id]
                Control       = $controlById[[int]$e.Id]
                SubjectUser   = $subject
                TargetUser    = $target
                Group         = $group2
                LogonType     = $(if ($lt) { "$lt $($logonTypes[$lt])" } else { '' })
                SourceIP      = Get-Val $d 'IpAddress'
                Workstation   = Get-Val $d 'WorkstationName'
                FailureStatus = Get-Val $d 'SubStatus'
                Process       = $process
                ParentProcess = Get-Val $d 'ParentProcessName'
                CommandLine   = Get-Val $d 'CommandLine'
                ObjectName    = $(if ($e.Id -eq 104) { 'Log cleared: ' + (Get-Val $d 'Channel') } else { Get-Val $d 'ObjectName' })
                ObjectType    = Get-Val $d 'ObjectType'
                AccessRequested = (Convert-AccessList (Get-Val $d 'AccessList'))
                ServiceName   = Get-Val $d 'ServiceName'
                ServicePath   = Get-Val $d 'ImagePath'
                Document      = $(if ($e.Id -eq 307) { Get-Val $d 'Param2' } else { '' })
                Printer       = $(if ($e.Id -eq 307) { Get-Val $d 'Param5' } else { '' })
                Pages         = $(if ($e.Id -eq 307) { Get-Val $d 'Param8' } else { '' })
                ThreatName    = Get-Val $d 'Threat Name'
                ThreatPath    = Get-Val $d 'Path'
                ThreatAction  = Get-Val $d 'Action Name'
                Device        = $(if ($e.Id -eq 6416) { (Get-Val $d 'DeviceDescription') + ' [' + (Get-Val $d 'ClassName') + '] ' + (Get-Val $d 'DeviceId') } else { '' })
                TimeChange    = $(if ($e.Id -eq 4616) { (Get-Val $d 'PreviousTime') + ' -> ' + (Get-Val $d 'NewTime') } else { '' })
                ShareName     = Get-Val $d 'ShareName'
                TaskName      = Get-Val $d 'TaskName'
                FirewallRule  = Get-Val $d 'RuleName'
                Privileges    = $((Get-Val $d 'PrivilegeList') -replace '\s+', ' ')
                ScriptBlock   = $script
                Details       = $(($d.Keys | Where-Object { $_ -ne 'ScriptBlockText' -and [string]$d[$_] -and [string]$d[$_] -ne '-' } | ForEach-Object { $v = [string]$d[$_] -replace '\s+', ' '; if ($v.Length -gt 300) { $v = $v.Substring(0, 300) + '...' }; '{0}={1}' -f $_, $v }) -join '; ')
                Log           = $e.LogName
                EventViewerPath = $LogLocations[$e.LogName].Viewer
                FoundIn       = (Get-FoundIn $tierById[[int]$e.Id] $e.LogName)
                RecordID      = $e.RecordId
            })
    }
}

$eventsCsv = Join-Path $weekFolder "$($computer)_$($stamp)_Events.csv"
if ($rows.Count) {
    $rows | Sort-Object TimeCreated | Export-Csv -LiteralPath $eventsCsv -NoTypeInformation -Encoding UTF8
} else {
    Set-Content -LiteralPath $eventsCsv -Value '"No monitored events found in this period"' -Encoding UTF8
}
$reviewCsv = Join-Path $weekFolder "$($computer)_$($stamp)_WeeklyReview.csv"
$reviewRows = @($rows | Where-Object { $_.WeeklyReview -eq 'Review' })
if ($reviewRows.Count) {
    $reviewRows | Sort-Object TimeCreated | Export-Csv -LiteralPath $reviewCsv -NoTypeInformation -Encoding UTF8
} else {
    Set-Content -LiteralPath $reviewCsv -Value '"No weekly-review events found in this period"' -Encoding UTF8
}

$counts = foreach ($m in $Monitored) {
    [pscustomobject]@{
        EventID     = $m.Id
        Description = $m.Description
        WeeklyReview = $m.WeeklyReview
        Control     = $m.Control
        Log         = $m.Log
        Count       = @($rows | Where-Object { $_.EventID -eq $m.Id }).Count
        EventViewerPath = $LogLocations[$m.Log].Viewer
        FoundIn     = (Get-FoundIn $m.WeeklyReview $m.Log)
    }
}
$countsCsv = Join-Path $weekFolder "$($computer)_$($stamp)_EventCounts.csv"
$counts | Export-Csv -LiteralPath $countsCsv -NoTypeInformation -Encoding UTF8
Write-Host ("  Saved {0} ({1} events to review), {2} ({3} total) and {4}" -f (Split-Path -Leaf $reviewCsv), $reviewRows.Count, (Split-Path -Leaf $eventsCsv), $rows.Count, (Split-Path -Leaf $countsCsv)) -ForegroundColor Green

Write-Host 'Saving raw event logs (.evtx)...' -ForegroundColor Cyan
Export-Evtx 'Security' (Join-Path $weekFolder "$($computer)_$($stamp)_Security.evtx")
Export-Evtx 'System' (Join-Path $weekFolder "$($computer)_$($stamp)_System.evtx")
Export-Evtx 'Microsoft-Windows-PowerShell/Operational' (Join-Path $weekFolder "$($computer)_$($stamp)_PowerShell.evtx")
Export-Evtx 'Microsoft-Windows-PrintService/Operational' (Join-Path $weekFolder "$($computer)_$($stamp)_PrintService.evtx")

# ---------------------------------------------------------------------------
# 2. OS and AV update events -> month\AV_OS_Updates
# ---------------------------------------------------------------------------
Write-Host 'Pulling OS and AV update events...' -ForegroundColor Cyan
# Explains common update results so failures that are expected on an air-gapped system are easy to spot
$OfflineErrorCodes = @('0x80072EE7', '0x80072EFD', '0x80072EE2', '0x80072F8F', '0x8024402C', '0x8024401C', '0x80244022', '0x80240438', '0x8007045B', '0x80070422')
function Get-UpdateNote {
    param([int]$Id, [string]$Msg)
    $code = [regex]::Match($Msg, 'Error code:\s*(0x[0-9A-Fa-f]+)', 'IgnoreCase').Groups[1].Value.ToUpper()
    if ($Id -eq 2001) {
        if ($OfflineErrorCodes -contains $code -or $Msg -match 'could not be resolved|connection|network|timed out|Microsoft Update|Microsoft Malware Protection Center|MMPC|Internal Definition Update Server') {
            return 'EXPECTED (air-gapped): Defender tried to update online and could not reach Microsoft. Not a failed manual install.'
        }
        return 'REVIEW: definition update failed for a reason other than no network connection.'
    }
    if ($Id -eq 2000) { return 'Definitions updated.' }
    if ($Id -eq 2) { return 'Package installed (manual install / DISM).' }
    if ($Id -eq 3) { return 'REVIEW: package failed to install - see Update_Log.csv and C:\Windows\Logs\CBS\CBS.log.' }
    if ($Id -eq 4) { return 'Reboot required to finish installing.' }
    if ($Id -eq 19) { return 'Installed by Windows Update client.' }
    if ($Id -eq 20) { return 'REVIEW: Windows Update client install failed.' }
    ''
}
$updateRows = @{ OS = @(); AV = @() }
foreach ($u in $UpdateEvents) {
    $events = @(Get-Events -LogName $u.Log -Ids $u.Ids -Provider $u.Provider)
    Write-Host ("  {0} log, IDs {1}: {2} events" -f $u.Log, ($u.Ids -join ','), $events.Count)
    foreach ($e in $events) {
        $msg = Format-Message $e
        $updateRows[$u.Type] += [pscustomobject]@{
            TimeCreated = $e.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')
            Computer    = $e.MachineName
            Type        = $u.Type
            Log         = $u.Log
            EventViewerPath = $LogLocations[$u.Log].Viewer
            FoundIn     = ('AV_OS_Updates\{0}_Updates.csv; raw: {1}' -f $u.Type, $LogLocations[$u.Log].Evtx)
            EventID     = $e.Id
            Description = $UpdateDescriptions["$($u.Type)-$($e.Id)"]
            KB          = [regex]::Match($msg, 'KB\d{6,8}').Value
            NewVersion  = [regex]::Match($msg, 'Current (?:security intelligence|engine|signature) Version:\s*([\d\.]+)', 'IgnoreCase').Groups[1].Value
            UpdateSource = [regex]::Match($msg, 'Update Source:\s*(.+?)\s+(?:Update Stage|Source Path|Signature Type|Update Type|User|Current|Previous|Error)', 'IgnoreCase').Groups[1].Value
            ErrorCode   = [regex]::Match($msg, 'Error code:\s*(0x[0-9A-Fa-f]+)', 'IgnoreCase').Groups[1].Value
            Note        = (Get-UpdateNote $e.Id $msg)
            Message     = $msg
        }
    }
}
foreach ($type in 'OS', 'AV') {
    $csv = Join-Path $updateFolder "$($computer)_$($stamp)_$($type)_Updates.csv"
    if ($updateRows[$type].Count) {
        $updateRows[$type] | Sort-Object TimeCreated | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
    } else {
        Set-Content -LiteralPath $csv -Value '"TimeCreated","Computer","Type","Log","EventViewerPath","FoundIn","EventID","Description","KB","NewVersion","UpdateSource","ErrorCode","Note","Message"' -Encoding UTF8
    }
    Write-Host ("  {0} updates: {1} events -> {2}" -f $type, $updateRows[$type].Count, (Split-Path -Leaf $csv)) -ForegroundColor Green
}
Export-Evtx 'Setup' (Join-Path $updateFolder "$($computer)_$($stamp)_Setup.evtx")
Export-Evtx 'Microsoft-Windows-Windows Defender/Operational' (Join-Path $updateFolder "$($computer)_$($stamp)_Defender.evtx")

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host 'Event counts this period:' -ForegroundColor Cyan
foreach ($c in $counts) { Write-Host ('  {0,-6} {1,7}  {2}' -f $c.EventID, $c.Count, $c.Description) }
Write-Host ''
$flagIds = @($Monitored | Where-Object { $_.Flag } | ForEach-Object { [int]$_.Id })
$watch = @($counts | Where-Object { $flagIds -contains [int]$_.EventID -and $_.Count -gt 0 })
if ($watch.Count) {
    Write-Host 'REVIEW REQUIRED - these events occurred and need an explanation:' -ForegroundColor Yellow
    $watch | ForEach-Object { Write-Host ("  {0}  x{1}  {2}" -f $_.EventID, $_.Count, $_.Description) -ForegroundColor Yellow }
}
Write-Host "Done. Files are in $weekFolder and $updateFolder" -ForegroundColor Green
