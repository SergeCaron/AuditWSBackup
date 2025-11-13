##******************************************************************
## Revision date: 2025.11.13
##
## Copyright (c) 2021 PC-Évolution enr.
## This code is licensed under the GNU General Public License (GPL).
##
## THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
## ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
## IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
## PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
##
##******************************************************************

## Dump the current status of Windows Server Backup on this server.

# Privilege Elevation Source Code: https://stackoverflow.com/questions/7690994/running-a-command-as-administrator-using-powershell

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole)) {
	# We are running as an administrator, so change the title and background colour to indicate this
	$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
	$Host.UI.RawUI.BackgroundColor = "DarkBlue"
	Clear-Host
}
else {
	# We are not running as an administrator, so relaunch as administrator

	# Create a new process object that starts PowerShell
	$newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"

	# Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
	$newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"

	# Indicate that the process should be elevated
	$newProcess.Verb = "runas"

	# Start the new process
	[System.Diagnostics.Process]::Start($newProcess)

	# Exit from the current, unelevated, process
	exit
}

# Run your code that needs to be elevated here...

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

Start-Transcript -Path "$DesktopPath\WSBCatalogAudit.txt" -Append

$OSCaption = (Get-WmiObject Win32_OperatingSystem).Caption
if ((Get-WmiObject Win32_OperatingSystem).ProductType -eq 1) {
	Write-Host
	Write-Host "Windows Backup Catalog Audit for" $env:ComputerName "[" $OSCaption "]"
	Write-Host "------------------------------------------------------------------------------------------"

	# There is limited WBEngine support on Windows Workstations
	$WBConfig = $(wbadmin enable backup)
	$WBadminRelease = $($WBConfig[0] -split "-")[0].Trim()
	if ( $WBadminRelease -eq "wbadmin 1.0" ) {
		if ( ($Null -eq $WBConfig[7]) -and ($Null -eq $WBConfig[12]) ) {
			# Nothing is scheduled yet
			Write-Warning $WBConfig[3]
		}
		else {
			$Schedule = $($WBConfig[12] -split ": ")[1].Trim() -split ","
			$BackupSet = $($WBConfig[11] -split ": ")[1].Trim() -split ","
			Write-Host "Schedule: ", $Schedule
			Write-Host
			Write-Host "Configured targets: "
			$BackupSet.ForEach({ "    " + $_ })
			Write-Host
			$Versions = $(WBAdmin.exe get versions) | Select-String "version"
			Write-Host $Versions.Count "available backups."
			$ListAvailableBackups = $(Read-Host "Enter Yes to enumerate all backups, not just those online").tolower().StartsWith('yes')
			Write-Host
			Write-Host "Disk(s) online:"

			[System.Object[]] $Sessions = Get-IscsiSession
			foreach ($Session in $Sessions) {
				$Volume = $Session | Get-Disk | Get-Partition | Get-Volume
				foreach ($Drive in $BackupSet) {
					if ( $Drive + "\" -eq $Volume.Path) {
						$Server = (Get-IscsiConnection -IscsiSession $Session).TargetAddress
						$iSCSIQualifiedName = ($Session | Get-IscsiTarget).NodeAddress
						$Discard, $TargetName = $iSCSIQualifiedName.split(":")
						Write-Host
						$Volume | Out-String
						# The IQN may contain multiple delimiters
						Write-Host "  iSCSI target: $($iSCSIQualifiedName) - $($Server)"
						Write-Host "        Volume: $($TargetName) -> [$($Volume.FileSystemLabel)]"
						Write-Host "wbadmin target: $Drive"
					}
				}
			}
			Write-Host
			if ($ListAvailableBackups) { WBAdmin.exe get versions }
		}
	}
 else { Write-Warning "Update this script for $WBadminRelease" }

	Stop-Transcript

	Pause
	exit 0
}


# Adapted from https://www.nsoftware.com/kb/articles/powershell-server-changing-terminal-width.rst
$pshost = Get-Host              # Get the PowerShell Host.
$pswindow = $pshost.UI.RawUI    # Get the PowerShell Host's UI.

$newsize = $pswindow.BufferSize # Get the UI's current Buffer Size.
$newsize.width = 150            # Set the new buffer's width to 150 columns.
$pswindow.buffersize = $newsize # Set the new Buffer Size as active.

$newsize = $pswindow.windowsize # Get the UI's current Window Size.
try {
	$newsize.width = 150            # Set the new Window Width to 150 columns.
	$pswindow.windowsize = $newsize 
} # Set the new Window Size as active.
catch {
 $newsize.width = 102            # Set the new Window Width to MAX columns for a batch job.
	$pswindow.windowsize = $newsize 
} # Set the new Window Size as active.

Write-Host
Write-Host "Windows Server Backup Catalog Audit for" $env:ComputerName "[" $OSCaption "]"
Write-Host "------------------------------------------------------------------------------------------"
# Dump the current WSB Summary (Note: somehow, the output is deferred.)
Get-WBSummary

Write-Host
# Dump attached volumes
# Inspired from https://stackoverflow.com/questions/62801341/volume-shadow-copy-monitoring-script
$Storage = Get-WmiObject -Class "Win32_Volume" |
	Select-Object @{n = "Volume"; e = { $_.DeviceID } },
	@{n = "DriveLetter"; e = { $_.DriveLetter } },
	@{n = "CapacityGB"; e = { ([math]::Round([int64]($_.Capacity) / 1GB, 2)) } },
	@{n = "FreeSpaceGB"; e = { ([math]::Round([int64]($_.FreeSpace) / 1GB, 2)) } },
	@{n = "FileSystem"; e = { $_.FileSystem } }

$Storage | Format-Table -AutoSize

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
	Write-Warning "You must run this script in an elevated command prompt to see this audit."
	Stop-Transcript
	exit 911
}

# Dump Windows Server Backup performance settings
Write-Host "Overall Performance Setting:" (Get-WBPerformanceConfiguration -OverallPerformanceSetting)
Write-Host
$ThisSetup = Get-WBPolicy
$Sources = Get-WBVolume -Policy $ThisSetup
foreach ($Source in $Sources) {
	if ($Source.MountPath -ne "") {
		$ThisVolume = Get-WBVolume -VolumePath $Source.MountPath
		Write-Host "Performance Setting for $Source set to " (Get-WBPerformanceConfiguration -Volume $ThisVolume)
	}
}
Write-Host
Write-Host

$ShadowProviders = Get-CimInstance -ClassName Win32_ShadowProvider

# Get last known good backup
$LastKnownGoodBackupVolume = (Get-WBSummary).LastSuccessfulBackupTargetPath + "\"

# Presume any "unexposed" shadow that is not "client accessible" is a Windows Backup created shadow
$WBShadows = Get-CimInstance -ClassName Win32_ShadowCopy | Where-Object { ($_.ExposedLocally -or $_.ExposedRemotely) -xor ! $_.ClientAccessible }
# Get a list of ONLINE volumes
[System.Object[]] $WBOnlineShadows = $WBShadows.VolumeName | Sort-Object -Unique

# Output the backup set status
Write-Host "-------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host
Write-Host "Status of the backup set:"
$WBVolume = @()
$WBPaths = @()
foreach ($Target in $ThisSetup.BackupTargets) {
	$WBVolume += New-Object -Type PSObject -Property @{
		Label      = $Target.Label
		Path       = $Target.Path
		Online     = $WBOnlineShadows.Contains($Target.Path + "\")
		LastBackup = $($Target.Path + "\") -eq $LastKnownGoodBackupVolume
	}
	$WBPaths += $Target.Path + "\"
}
$WBVolume | Format-Table -AutoSize

$OtherShadows = Get-CimInstance -ClassName Win32_ShadowCopy | Where-Object { ! $WBPaths.Contains($_.VolumeName) -and ($_.ExposedLocally -or $_.ExposedRemotely) }
$OtherVolumes = $OtherShadows.VolumeName | Sort-Object -Unique

# Enumerate shadows exposed by other system components
$InUse = @()
foreach ( $Orphan in $OtherShadows ) {
	$InUse += New-Object -Type PSObject -Property @{
		VolumeLetter = (Get-Volume -UniqueId $Orphan.VolumeName).DriveLetter
		VolumeLabel  = (Get-Volume -UniqueId $Orphan.VolumeName).FileSystemLabel
		InstallDate  = $Orphan.InstallDate
		DeviceObject = $Orphan.DeviceObject
		ProviderName = ($ShadowProviders | Where-Object { $_.ID -eq $Orphan.ProviderID }).Name
		Persistent   = $Orphan.Persistent
		Differential = $Orphan.Differential
	}
}
if ($InUse.Count -gt 0) {
	Write-Host "-------------------------------------------------------------------------------------------------------------------------------------------"
	Write-Host
	Write-Host "Active shadows in use on this system : "
	Write-Host "(Note: other than Windows Server Backup shadows"
	Write-Host "       unexposed File Share Shadows are not enumerated here.)"
	$InUse | Format-List *
}




# Get the list of WSB destinations
$Volumes = $ThisSetup.BackupTargets

# Get properties of active shadow storage
# Inspired from https://stackoverflow.com/questions/62801341/volume-shadow-copy-monitoring-script
$ShadowStorage = Get-WmiObject -Class "Win32_ShadowStorage" |
	Select-Object @{n = "Volume"; e = { $_.Volume.Replace("\\", "\").Replace("Win32_Volume.DeviceID=", "").Replace("`"", "") } },
	@{n = "DiffVolume"; e = { $_.DiffVolume.Replace("\\", "\").Replace("Win32_Volume.DeviceID=", "").Replace("`"", "") } },
	@{n = "MaxSpaceGB"; e = { if ($_.MaxSpace -eq [UInt64]::MaxValue) { "Unlimited" } else { ([math]::Round([UInt64]($_.MaxSpace) / 1GB, 2)) } } },
	@{n = "AllocatedSpaceGB"; e = { ([math]::Round([int64]($_.AllocatedSpace) / 1GB, 2)) } },
	@{n = "UsedSpaceGB"; e = { ([math]::Round([int64]($_.UsedSpace) / 1GB, 2)) } }

# Get a list of active shadow copies
$shadowcopies = Get-WmiObject -Class "Win32_ShadowCopy"

# Get a list of active iSCSI sessions
[System.Object[]] $Sessions = Get-IscsiSession


Write-Host "-------------------------------------------------------------------------------------------------------------------------------------------"
foreach ($Volume in $Volumes) {
	$Lint = $Volume.Path + '\' # BackTicks to avoid regex
	Write-Host $Volume.Label, "[", $Lint, "]"

	# If this volume is a iSCSI target, show it's location
	foreach ($Session in $Sessions) {
		$VolumeLabel = ($Session | Get-Disk | Get-Partition | Get-Volume )
		if ( $VolumeLabel.Path -eq $Lint ) {
			$Server = (Get-IscsiConnection -IscsiSession $Session).TargetAddress
			$iSCSIQualifiedName = ($Session | Get-IscsiTarget).NodeAddress
			# The IQN may contain multiple delimiters
			Write-Host
			Write-Host "    iSCSI Target: $($iSCSIQualifiedName) - $($Server)"
			Write-Host
		}
	}

	$ShadowStorage | Where-Object { $_.DiffVolume -eq $Lint } | Format-Table MaxSpaceGB, AllocatedSpaceGB, UsedSpaceGB -AutoSize
	$Copies = $shadowcopies | Where-Object { $_.VolumeName -eq $Lint } | Sort-Object -Property ID
	$WBSet = Get-WBBackupSet | Where-Object { $_.BackupTarget.Path -eq $Volume.Path } | Sort-Object -Property SnapshotId 
	$Connected = foreach ($WB in $WBSet) {
		[pscustomobject]@{
			VersionID       = $WB.VersionID
			BackupTime      = $WB.BackupTime
			VssBackupOption = $WB.VssBackupOption
			SnapshotId      = $WB.SnapshotId
			Shadow          = $Copies | Where-Object { $_.ID -eq '{' + $WB.SnapshotId + '}' } | Select-Object -ExpandProperty DeviceObject
		}
	}
	$Connected | Sort-Object -Property BackupTime -Descending | Format-Table -AutoSize
	#	$Copies | ft DeviceObject, ID  -AutoSize
	#	Write-Host "-".PadRight(138, "-")
	Write-Host "-------------------------------------------------------------------------------------------------------------------------------------------"
}

Stop-Transcript

Pause
exit 0
