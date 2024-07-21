# AuditWSBackup

## Purpose:

Prepare an audit of the Windows Server Backup installation on a Windows Server.

This may assist you in auditing your backup rotation scheme and backup retention policy.

The report includes:
- The history of backup operations on the server, including the number of versions available.
- The details of disk volumes on the server
- The overall performance setting and the performanace setting of each volume configured in the backup
- The online status of each target in the backut set
- For each target in the backup set, the volume label (and iSCSI related data, if applicable) and the history of each backup version stored on this target, in reverse chronological order.

A transcript log of the console output is stored on the user's desktop and named C:\Users\<LoggedOnUser>\Desktop\WSBCatalogAudit.txt

Please note that the Windows Server Catalog may contains data for targets that no longer exist.



------
>**Caution:**	This script requires **elevated** execution privileges.

Quoting from Microsoft's "about_Execution_Policies" : "PowerShell's
execution policy is a safety feature that controls the conditions
under which PowerShell loads configuration files and runs scripts."

In order to execute this script using a right-click "Run with PowerShell",
the user's session must be able to run unsigned scripts and perform
privilege elevation. Use any configuration that is the equivalent of the
following commnand executed from an elevated PowerShell prompt:

			Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
------
### Sample console output

```

Windows Server Backup Catalog Audit for TOOTHLESS [ Microsoft Windows Server 2022 Standard ]
------------------------------------------------------------------------------------------


NextBackupTime                  : 2024-03-16 04:30:00
NumberOfVersions                : 101
LastSuccessfulBackupTime        : 2024-03-15 11:16:38
LastSuccessfulBackupTargetPath  : \\?\Volume{61776c53-3eeb-447b-b38e-a6cd3bee7fbb}
LastSuccessfulBackupTargetLabel : Toothle 2023_11_18 13:54 DISK_01
LastBackupTime                  : 2024-03-15 11:16:38
LastBackupTarget                : Toothle 2023_11_18 13:54 DISK_01
DetailedMessage                 :
LastBackupResultHR              : 0
LastBackupResultDetailedHR      : 0
CurrentOperationStatus          : NoOperationInProgress





Volume                                            DriveLetter CapacityGB FreeSpaceGB FileSystem
------                                            ----------- ---------- ----------- ----------
\\?\Volume{d024c4eb-73dd-4957-be00-6edecc804b8e}\                   0,44        0,12 NTFS
\\?\Volume{9b601a34-cbdc-4544-8d71-c3e122dea71d}\ C:              125,48       98,77 NTFS
\\?\Volume{69f2f7c0-a75a-47e8-b856-80c25cc10dd1}\                   0,97        0,49 NTFS
\\?\Volume{600e1d1d-6e0c-404c-8e67-f0a7800c8a8e}\ V:              804,43      500,74 NTFS
\\?\Volume{61776c53-3eeb-447b-b38e-a6cd3bee7fbb}\                 931,18      461,31 NTFS
\\?\Volume{69ab88da-0bec-45a0-8bab-6878d40ba04c}\ P:                3,98        3,96 NTFS
\\?\Volume{f204afd6-08f0-4c8a-9b5e-383ea81f91f2}\                 357,48       23,89 NTFS
\\?\Volume{910f13d8-3319-47fa-becd-5a18ae5ebd7d}\                   0,09        0,07 FAT32


Overall Performance Setting: AlwaysFull

Performance Setting for Disque local (C:) set to  AlwaysFull
Performance Setting for Library (V:) set to  AlwaysFull


-------------------------------------------------------------------------------------------------------------------------------------------

Status of the backup set:

Label                            Path                                             LastBackup Online
-----                            ----                                             ---------- ------
Toothle 2023_11_18 13:54 DISK_01 \\?\Volume{61776c53-3eeb-447b-b38e-a6cd3bee7fbb}       True   True
Toothle 2024_03_15 11:11 DISK_03 \\?\Volume{f204afd6-08f0-4c8a-9b5e-383ea81f91f2}      False   True


-------------------------------------------------------------------------------------------------------------------------------------------
Toothle 2023_11_18 13:54 DISK_01 [ \\?\Volume{61776c53-3eeb-447b-b38e-a6cd3bee7fbb}\ ]

    iSCSI Target: iqn.2013-03.com.wdc:archives:toothless-volume1 - 192.168.18.50


MaxSpaceGB AllocatedSpaceGB UsedSpaceGB
---------- ---------------- -----------
Unlimited            142,88      112,71



VersionID        BackupTime          VssBackupOption SnapshotId                           Shadow
---------        ----------          --------------- ----------                           ------
03/15/2024-15:16 2024-03-15 11:16:38   VssFullBackup 58d04a46-e192-435f-a9a6-71db4de8a1ba \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy121
03/14/2024-08:30 2024-03-14 04:30:27   VssFullBackup c075f930-0eb8-4b55-a08d-20faf1219959 \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy100
03/13/2024-08:30 2024-03-13 04:30:17   VssFullBackup 62b78b2d-f756-48f5-91fb-df50bfe801d7 \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy99
[ ... 96 lines deleted for clarity ... ]
11/20/2023-09:30 2023-11-20 04:30:18   VssFullBackup f22f18be-4515-4da9-9804-cf0047e819aa \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2
11/19/2023-09:30 2023-11-19 04:30:18   VssFullBackup 4a71d090-7c3a-4019-82fb-8b073042eb1c \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1


-------------------------------------------------------------------------------------------------------------------------------------------
Toothle 2024_03_15 11:11 DISK_03 [ \\?\Volume{f204afd6-08f0-4c8a-9b5e-383ea81f91f2}\ ]

    iSCSI Target: iqn.2013-03.com.wdc:semaine2:toothless-vol2 - 192.168.18.23


MaxSpaceGB AllocatedSpaceGB UsedSpaceGB
---------- ---------------- -----------
Unlimited             21,02        18,8



VersionID        BackupTime          VssBackupOption SnapshotId                           Shadow
---------        ----------          --------------- ----------                           ------
[ ... 20 lines deleted for clarity ... ]

```
