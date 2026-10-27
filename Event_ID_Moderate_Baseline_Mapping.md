# Weekly Event ID Review - NISPOM (DCSA) / NIST SP 800-53 Moderate Baseline

Event IDs pulled by `Weekly-EventLog-Review.ps1`, which ones to review each week, and the controls each supports.

NISPOM classified systems are authorized by **DCSA** using the NIST SP 800-53 baselines. NIST does not publish a fixed Event ID list: AU-2 has each organization define its audited events, and AU-6 sets how often they are reviewed. **Confirm both values in your SSP.** The audit settings follow the **DISA Windows 11 STIG**, the usual hardening standard.

## Where to find each event

| Log (column in tables below) | Event Viewer path | Raw copy saved by the script |
|---|---|---|
| Security | Windows Logs > Security | Week folder `Security.evtx` |
| System | Windows Logs > System | Week folder `System.evtx` |
| PowerShell/Operational | Applications and Services Logs > Microsoft > Windows > PowerShell > Operational | Week folder `PowerShell.evtx` |
| Defender/Operational | Applications and Services Logs > Microsoft > Windows > Windows Defender > Operational | `AV_OS_Updates\Defender.evtx` |
| PrintService/Operational | Applications and Services Logs > Microsoft > Windows > PrintService > Operational | Week folder `PrintService.evtx` |
| Setup | Windows Logs > Setup | `AV_OS_Updates\Setup.evtx` |

In Event Viewer, open the log, click **Filter Current Log** on the right, and type the Event ID. In the script output, **Review** events are in `WeeklyReview.csv` and `Events.csv`; **Filter** and **Archive** events are in `Events.csv`; update events are in the month's `AV_OS_Updates` folder. Each CSV row also has `EventViewerPath` and `FoundIn` columns.

## How the list is organized

| Tier | Meaning | Where to find it |
|---|---|---|
| **Review** (60 IDs) | Look at every week; every occurrence should be explainable | `<HOST>_<date>_WeeklyReview.csv` (start here) |
| **Filter** (2 IDs) | High volume (4688 processes, 4104 PowerShell). Search them for unusual activity or during an investigation | `Events.csv`, filter `WeeklyReview = Filter` |
| **Archive** (26 IDs) | Collected and kept for evidence and investigations; no weekly review needed | `Events.csv` and the weekly `.evtx` files |

**Applies to every Event ID:** AU-2 (event logging), AU-3 (record content), AU-6 (review), AU-12 (record generation).

## Review every week

### Process & Execution

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 7045 | New service installed | CM-7, SI-4 | System | Yes |
| 4697 | Service installed (Security log) | CM-7, SI-4 | Security | Yes |
| 4698 | Scheduled task created | CM-7, SI-4 | Security | Yes |
| 4702 | Scheduled task updated | CM-7, SI-4 | Security | Yes |
| 5038 | Code integrity: file hash not valid | SI-7 | Security | Yes |

### Logon, Logoff & Sessions

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4624 | Successful account logon | AC-12, AC-2 | Security | Yes |
| 4625 | Failed account logon | AC-7 | Security | Yes |
| 4648 | Logon with explicit credentials (run as) | AC-6 | Security | Yes |
| 4672 | Special (admin) privileges assigned to new logon | AC-6, AC-6(9) | Security | Yes |
| 4634 | Account logged off | AC-12 | Security | Yes |
| 4647 | User initiated logoff | AC-12 | Security | Yes |
| 4800 | Workstation locked | AC-11 | Security | Yes |
| 4801 | Workstation unlocked | AC-11 | Security | Yes |
| 4740 | User account locked out | AC-7 | Security | Yes |
| 4767 | User account unlocked | AC-7 | Security | Yes |

### Account & Group Management

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4720 | User account created | AC-2 | Security | Yes |
| 4722 | User account enabled | AC-2 | Security | Yes |
| 4725 | User account disabled | AC-2 | Security |  |
| 4726 | User account deleted | AC-2 | Security | Yes |
| 4738 | User account changed | AC-2 | Security | Yes |
| 4781 | Account name changed | AC-2 | Security | Yes |
| 4723 | User changed own password | AC-2, IA-5 | Security |  |
| 4724 | Password reset by another account | AC-2, IA-5 | Security | Yes |
| 4731 | Local security group created | AC-2 | Security | Yes |
| 4734 | Local security group deleted | AC-2 | Security | Yes |
| 4735 | Local security group changed | AC-2 | Security | Yes |
| 4732 | Member added to local security group | AC-2, AC-6 | Security | Yes |
| 4733 | Member removed from local security group | AC-2, AC-6 | Security | Yes |
| 4704 | User right assigned | AC-6 | Security | Yes |
| 4705 | User right removed | AC-6 | Security | Yes |

### File, Share & Object Access

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4663 | Attempt to access an object | AU-12, AC-3 | Security |  |
| 4660 | Object deleted | AU-12, AC-3 | Security |  |
| 4670 | Permissions on an object changed | AC-3, CM-5 | Security | Yes |
| 6416 | New external device recognized (USB / removable) | MP-7 | Security | Yes |

### Audit, Logging & Time

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 1102 | Security audit log cleared | AU-9 | Security | Yes |
| 104 | Event log cleared (System, Application or other log) | AU-9 | System | Yes |
| 1100 | Event logging service shut down | AU-9, AU-5 | Security | Yes |
| 1104 | Security log is full | AU-5, AU-4 | Security | Yes |
| 1108 | Event logging service error | AU-5 | Security | Yes |
| 4612 | Audit resources exhausted - audit messages lost | AU-5 | Security | Yes |
| 4715 | Audit policy (SACL) on an object changed | AU-9 | Security | Yes |
| 4719 | System audit policy changed | AU-9, AU-12, CM-6 | Security | Yes |
| 4912 | Per-user audit policy changed | AU-9, AU-12 | Security | Yes |
| 4616 | System time changed | AU-8 | Security |  |

### Startup & Shutdown

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4608 | Windows is starting up | AU-5, CP-10 | Security |  |
| 6005 | Event log service started (system boot) | AU-5, CP-10 | System |  |
| 6006 | Event log service stopped (clean shutdown) | AU-5 | System |  |
| 6008 | Unexpected shutdown | AU-5, CP-10 | System | Yes |
| 1074 | Shutdown or restart initiated (by user or process) | AU-5 | System |  |

### Firewall & Security Policy

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4946 | Firewall rule added | SC-7, CM-6 | Security | Yes |
| 4947 | Firewall rule modified | SC-7, CM-6 | Security | Yes |
| 4948 | Firewall rule deleted | SC-7, CM-6 | Security | Yes |

### Malware Protection (Defender)

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 1116 | Malware detected | SI-3 | Defender/Operational | Yes |
| 1117 | Action taken on malware | SI-3 | Defender/Operational | Yes |
| 1118 | Malware remediation failed | SI-3 | Defender/Operational | Yes |
| 1119 | Critical malware remediation failure | SI-3 | Defender/Operational | Yes |
| 5001 | Real-time protection disabled | SI-3 | Defender/Operational | Yes |
| 5007 | Defender configuration changed (e.g., exclusions) | SI-3, CM-6 | Defender/Operational | Yes |
| 5013 | Tamper protection blocked a change | SI-3 | Defender/Operational | Yes |

### Printing

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 307 | Document printed (user, document, printer, pages) | AU-12, PE-5 | PrintService/Operational |  |

## Filter when needed

### Process & Execution

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4688 | New process created (program run, with command line) | AU-12, SI-4 | Security |  |
| 4104 | PowerShell script block executed | AU-12, SI-4 | PowerShell/Operational |  |

## Archive (collected, no weekly review)

### Process & Execution

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 7040 | Service start type changed | CM-7 | System |  |
| 4699 | Scheduled task deleted | CM-7, SI-4 | Security |  |
| 4700 | Scheduled task enabled | CM-7, SI-4 | Security |  |
| 4701 | Scheduled task disabled | CM-7, SI-4 | Security |  |

### Logon, Logoff & Sessions

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4778 | Session reconnected (RDP / fast user switching) | AC-12, AC-17 | Security |  |
| 4779 | Session disconnected | AC-12, AC-17 | Security |  |
| 4802 | Screen saver invoked | AC-11 | Security |  |
| 4803 | Screen saver dismissed | AC-11 | Security |  |
| 4776 | Credential validation (local account logon attempt) | AC-7, IA-2 | Security |  |

### Account & Group Management

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4728 | Member added to domain global group (domain only) | AC-2, AC-6 | Security | Yes |
| 4729 | Member removed from domain global group (domain only) | AC-2, AC-6 | Security | Yes |
| 4756 | Member added to domain universal group (domain only) | AC-2, AC-6 | Security | Yes |
| 4757 | Member removed from domain universal group (domain only) | AC-2, AC-6 | Security | Yes |

### File, Share & Object Access

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4656 | Handle to an object requested | AU-12, AC-3 | Security |  |
| 4657 | Registry value modified | CM-5, SI-4 | Security |  |
| 5140 | Network share accessed | AC-3 | Security |  |
| 5142 | Network share added | CM-7, AC-3 | Security | Yes |
| 5143 | Network share modified | CM-7, AC-3 | Security | Yes |
| 5144 | Network share deleted | CM-7, AC-3 | Security | Yes |

### Audit, Logging & Time

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 1105 | Security log archived automatically | AU-4, AU-11 | Security |  |

### Firewall & Security Policy

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 4950 | Firewall setting changed | SC-7, CM-6 | Security | Yes |
| 4713 | Kerberos policy changed | IA-5, CM-6 | Security | Yes |
| 4739 | Domain policy changed (domain only) | AC-7, IA-5, CM-6 | Security | Yes |

### Malware Protection (Defender)

| Event ID | Description | Controls | Log | Flagged |
|---|---|---|---|---|
| 5004 | Real-time protection configuration changed | SI-3 | Defender/Operational | Yes |
| 5010 | Antispyware scanning disabled | SI-3 | Defender/Operational | Yes |
| 5012 | Antivirus scanning disabled | SI-3 | Defender/Operational | Yes |

## Update events (saved to the month's `AV_OS_Updates` folder)

| Event ID | Description | Controls | Log |
|---|---|---|---|
| 2 | Update package installed (manual install / DISM) | SI-2 | Setup (Servicing) |
| 3 | Update package failed to install | SI-2 | Setup (Servicing) |
| 4 | Update requires a reboot | SI-2 | Setup (Servicing) |
| 19 | Windows update installed (Windows Update client only) | SI-2 | System (WindowsUpdateClient) |
| 20 | Windows update failed | SI-2 | System (WindowsUpdateClient) |
| 2000 | Defender definitions updated | SI-3 | Defender/Operational |
| 2001 | Defender definitions update failed (on air-gapped systems, mostly automatic online attempts; the CSV Note column marks these as expected) | SI-3 | Defender/Operational |

## Logged by the audit policy but not pulled into the CSV

| Event ID | Why |
|---|---|
| 4673, 4674 (Sensitive Privilege Use) | STIG requires the setting, but thousands per day. Kept in the weekly Security `.evtx`. |
| 4627 (Group Membership) | One per logon; duplicates 4624. Kept in the `.evtx`. |

## Storing the weekly output

| Control | How |
|---|---|
| AU-4 | Security log at least 1 GB (1024000 KB); Application/System at least 32 MB (checked each run) |
| AU-9 | Raw `.evtx` copies saved each week off the live log |
| AU-11 | Year / month / week folders keep records for the SSP retention period |

## Audit settings required (checked each run, applied by `Apply-AuditSettings.ps1`)

| Category | Subcategory | Setting | Generates |
|---|---|---|---|
| Account Logon | Credential Validation | Success and Failure | 4776 |
| Account Management | Other Account Management Events | Success | 4782, 4793 |
| Account Management | Security Group Management | Success | 4727-4735, 4754-4758 |
| Account Management | User Account Management | Success and Failure | 4720, 4722-4726, 4738, 4740, 4767, 4781 |
| Detailed Tracking | PNP Activity | Success | 6416 |
| Detailed Tracking | Process Creation | Success | 4688 |
| Logon/Logoff | Account Lockout | Failure | 4625 (locked account) |
| Logon/Logoff | Group Membership | Success | 4627 |
| Logon/Logoff | Logoff | Success | 4634, 4647 |
| Logon/Logoff | Logon | Success and Failure | 4624, 4625, 4648 |
| Logon/Logoff | Other Logon/Logoff Events | Success and Failure | 4778, 4779, 4800-4803 |
| Logon/Logoff | Special Logon | Success | 4672, 4964 |
| Object Access | File Share | Success and Failure | 5140, 5142-5144 |
| Object Access | File System | Success and Failure | 4656, 4660, 4663, 4670 - Also needs auditing (SACL) on the folders to watch |
| Object Access | Other Object Access Events | Success and Failure | 4698-4702 |
| Object Access | Registry | Success | 4657 - Also needs auditing (SACL) on the registry keys to watch |
| Object Access | Removable Storage | Success and Failure | 4656, 4663 (USB / removable media) |
| Policy Change | Audit Policy Change | Success and Failure | 4715, 4719, 4912 |
| Policy Change | Authentication Policy Change | Success | 4706, 4707, 4713, 4739 |
| Policy Change | Authorization Policy Change | Success | 4704, 4705 |
| Policy Change | MPSSVC Rule-Level Policy Change | Success and Failure | 4946-4950 |
| Policy Change | Other Policy Change Events | Success and Failure | STIG requirement |
| Privilege Use | Sensitive Privilege Use | Success and Failure | 4673, 4674 - Logged and kept in the .evtx; not pulled into the CSV (very high volume) |
| System | IPsec Driver | Success and Failure | 4960-4965 |
| System | Other System Events | Success and Failure | 5024-5027 (firewall service) |
| System | Security State Change | Success | 4608, 4616 |
| System | Security System Extension | Success | 4697, 4610, 4611, 4614, 4622 |
| System | System Integrity | Success and Failure | 4612, 5038, 6281 |

| Other setting | Value | For |
|---|---|---|
| Include command line in process creation events | 1 | 4688 command line |
| PowerShell Script Block Logging | 1 | 4104 |
| Force audit policy subcategory settings | 1 | all subcategories |
| Security log maximum size (KB) | 1024000 | AU-4 |
| Application log maximum size (KB) | 32768 | AU-4 |
| System log maximum size (KB) | 32768 | AU-4 |
| PrintService Operational log | Enabled | 307 |

Always logged (no setting needed): 2, 3, 4 (Setup), 104, 1100, 1102, 1104, 1105, 1108, 1074, 6005, 6006, 6008, 7040, 7045, 1116-1119, 5001, 5004, 5007, 5010, 5012, 5013, 19, 20, 2000, 2001.

**Notes**
- **Print records (307) include document names.** On a classified system a document title can itself be classified. Handle and mark the weekly CSVs and `.evtx` files at the classification level of the system.
- 4660, 4663, 4670 (files) are only written for folders that have auditing (SACL) set. Set it on the folders holding classified data.
- Domain-only events (4728, 4729, 4756, 4757, 4739) stay at 0 on standalone systems; that is expected.
- 4616 appears weekly from normal clock sync by LOCAL SERVICE; only changes by a user need review.
