# Audit Settings - Fix Text (AU-12)

Fix text for every setting checked by `Weekly-EventLog-Review.ps1` (`AuditSettings.csv`). The audit policy matches the **DISA Windows 11 STIG**. Apply all of them, whether the check shows PASS or FAIL.

## Three ways to apply

| Method | Use when | How |
|---|---|---|
| **Script** (fastest) | Standalone / air-gapped systems | Run as Administrator: `powershell -ExecutionPolicy Bypass -File .\Apply-AuditSettings.ps1 -SaclFolders 'D:\Sensitive'` |
| **GPO files** | You have Microsoft's LGPO.exe (Security Compliance Toolkit) | `LGPO.exe /ac GPO\audit.csv` and `LGPO.exe /m GPO\registry.pol`, then `gpupdate /force` |
| **Group Policy editor** | Domain GPO, or Local Group Policy (`gpedit.msc`) | Follow the fix text below |

If a domain GPO already controls auditing, make the change **in that GPO**. Local changes are overwritten at the next policy refresh.

## Required first: force subcategory settings

`Computer Configuration >> Windows Settings >> Security Settings >> Local Policies >> Security Options >>` "Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings" = **Enabled**  
Registry: `HKLM\SYSTEM\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy` = `1`

## Advanced Audit Policy (28 subcategories)

Path for all: `Computer Configuration >> Windows Settings >> Security Settings >> Advanced Audit Policy Configuration >> System Audit Policies >> <Category> >> <Subcategory>`

| # | Category | Subcategory | Set to | Command | Generates |
|---|---|---|---|---|---|
| 1 | Account Logon | Audit Credential Validation | **Success and Failure** | `auditpol /set /subcategory:"{0CCE923F-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4776 |
| 2 | Account Management | Audit Other Account Management Events | **Success** | `auditpol /set /subcategory:"{0CCE923A-69AE-11D9-BED3-505054503030}" /success:enable` | 4782, 4793 |
| 3 | Account Management | Audit Security Group Management | **Success** | `auditpol /set /subcategory:"{0CCE9237-69AE-11D9-BED3-505054503030}" /success:enable` | 4727-4735, 4754-4758 |
| 4 | Account Management | Audit User Account Management | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9235-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4720, 4722-4726, 4738, 4740, 4767, 4781 |
| 5 | Detailed Tracking | Audit PNP Activity | **Success** | `auditpol /set /subcategory:"{0CCE9248-69AE-11D9-BED3-505054503030}" /success:enable` | 6416 |
| 6 | Detailed Tracking | Audit Process Creation | **Success** | `auditpol /set /subcategory:"{0CCE922B-69AE-11D9-BED3-505054503030}" /success:enable` | 4688 |
| 7 | Logon/Logoff | Audit Account Lockout | **Failure** | `auditpol /set /subcategory:"{0CCE9217-69AE-11D9-BED3-505054503030}" /failure:enable` | 4625 (locked account) |
| 8 | Logon/Logoff | Audit Group Membership | **Success** | `auditpol /set /subcategory:"{0CCE9249-69AE-11D9-BED3-505054503030}" /success:enable` | 4627 |
| 9 | Logon/Logoff | Audit Logoff | **Success** | `auditpol /set /subcategory:"{0CCE9216-69AE-11D9-BED3-505054503030}" /success:enable` | 4634, 4647 |
| 10 | Logon/Logoff | Audit Logon | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9215-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4624, 4625, 4648 |
| 11 | Logon/Logoff | Audit Other Logon/Logoff Events | **Success and Failure** | `auditpol /set /subcategory:"{0CCE921C-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4778, 4779, 4800-4803 |
| 12 | Logon/Logoff | Audit Special Logon | **Success** | `auditpol /set /subcategory:"{0CCE921B-69AE-11D9-BED3-505054503030}" /success:enable` | 4672, 4964 |
| 13 | Object Access | Audit File Share | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9224-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 5140, 5142-5144 |
| 14 | Object Access | Audit File System | **Success and Failure** | `auditpol /set /subcategory:"{0CCE921D-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4656, 4660, 4663, 4670 (Also needs auditing (SACL) on the folders to watch) |
| 15 | Object Access | Audit Other Object Access Events | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9227-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4698-4702 |
| 16 | Object Access | Audit Registry | **Success** | `auditpol /set /subcategory:"{0CCE921E-69AE-11D9-BED3-505054503030}" /success:enable` | 4657 (Also needs auditing (SACL) on the registry keys to watch) |
| 17 | Object Access | Audit Removable Storage | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9245-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4656, 4663 (USB / removable media) |
| 18 | Policy Change | Audit Audit Policy Change | **Success and Failure** | `auditpol /set /subcategory:"{0CCE922F-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4715, 4719, 4912 |
| 19 | Policy Change | Audit Authentication Policy Change | **Success** | `auditpol /set /subcategory:"{0CCE9230-69AE-11D9-BED3-505054503030}" /success:enable` | 4706, 4707, 4713, 4739 |
| 20 | Policy Change | Audit Authorization Policy Change | **Success** | `auditpol /set /subcategory:"{0CCE9231-69AE-11D9-BED3-505054503030}" /success:enable` | 4704, 4705 |
| 21 | Policy Change | Audit MPSSVC Rule-Level Policy Change | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9232-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4946-4950 |
| 22 | Policy Change | Audit Other Policy Change Events | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9234-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | STIG requirement |
| 23 | Privilege Use | Audit Sensitive Privilege Use | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9228-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4673, 4674 (Logged and kept in the .evtx; not pulled into the CSV (very high volume)) |
| 24 | System | Audit IPsec Driver | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9213-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4960-4965 |
| 25 | System | Audit Other System Events | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9214-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 5024-5027 (firewall service) |
| 26 | System | Audit Security State Change | **Success** | `auditpol /set /subcategory:"{0CCE9210-69AE-11D9-BED3-505054503030}" /success:enable` | 4608, 4616 |
| 27 | System | Audit Security System Extension | **Success** | `auditpol /set /subcategory:"{0CCE9211-69AE-11D9-BED3-505054503030}" /success:enable` | 4697, 4610, 4611, 4614, 4622 |
| 28 | System | Audit System Integrity | **Success and Failure** | `auditpol /set /subcategory:"{0CCE9212-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable` | 4612, 5038, 6281 |

## Administrative Templates

**Include command line in process creation events** = **Enabled** (4688)  
`Computer Configuration >> Administrative Templates >> System >> Audit Process Creation`  
Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit\ProcessCreationIncludeCmdLine_Enabled` = `1`

**Turn on PowerShell Script Block Logging** = **Enabled** (4104; leave invocation logging unchecked)  
`Computer Configuration >> Administrative Templates >> Windows Components >> Windows PowerShell`  
Registry: `HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging\EnableScriptBlockLogging` = `1`

## Event log sizes (AU-4)

`Computer Configuration >> Administrative Templates >> Windows Components >> Event Log Service >> <Log> >>` "Specify the maximum log file size (KB)" = **Enabled**

| Log | Minimum (KB) | Registry (`HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\<Log>\MaxSize`) |
|---|---|---|
| Security | 1024000 | `...\EventLog\Security\MaxSize` = 1024000 |
| Application | 32768 | `...\EventLog\Application\MaxSize` = 32768 |
| System | 32768 | `...\EventLog\System\MaxSize` = 32768 |

## Print logging (307)

Windows does not record printed documents until this log is turned on.
**Fix:** Event Viewer > **Applications and Services Logs > Microsoft > Windows > PrintService** > right-click **Operational** > **Enable Log**  
**Command:** `wevtutil sl "Microsoft-Windows-PrintService/Operational" /e:true`  
`Apply-AuditSettings.ps1` does this automatically.

## Object auditing (SACLs) for 4656 / 4660 / 4663 / 4670 / 4657

**Folders:** right-click > **Properties > Security > Advanced > Auditing > Add** > Principal **Everyone** > Type **All** > Applies to **This folder, subfolders and files** > check **Write**, **Delete**, **Change permissions**, **Take ownership** > OK. Or: `Apply-AuditSettings.ps1 -SaclFolders 'D:\Folder1','D:\Folder2'`.  
**Registry keys (4657):** `regedit` > right-click the key > **Permissions > Advanced > Auditing > Add** > **Everyone** > **Set Value**, **Create Subkey**, **Delete**. Audit only specific sensitive keys.  
Avoid auditing whole drives or the whole registry; volume becomes very high.

## After applying

1. `gpupdate /force` (if you used Group Policy).
2. Run `Run-All.bat` or `Weekly-EventLog-Review.ps1`. Every line in `AuditSettings.csv` should show **PASS**.
3. Expect a **4719** event for the change. Note it in the weekly review as an authorized change.

## Files in the GPO folder

| File | What it is |
|---|---|
| `GPO\audit.csv` | All 28 Advanced Audit Policy subcategories. Import with `LGPO.exe /ac`, or place in a domain GPO at `Machine\Microsoft\Windows NT\Audit\audit.csv` |
| `GPO\registry.pol` | Command-line logging, script block logging, force-subcategory, and log sizes. Import with `LGPO.exe /m` |
| `GPO\Backup_<date>\` | Created by `Apply-AuditSettings.ps1`: settings before the change and results after |

**Rollback:** `auditpol /restore /file:"GPO\Backup_<date>\audit_before.csv"`; previous registry values are in `registry_before.csv`.
