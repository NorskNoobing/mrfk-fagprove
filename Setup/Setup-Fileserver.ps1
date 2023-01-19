param (
    $Hostname = "SR-WINSRV19-002",
    $Domain = "corp.local",
    $OUPath = "OU=Servers,OU=Computers,OU=CORP,DC=corp,DC=local",

    $DriveLetter = "F",

    #Misc
    $ScheduledTaskName = "Fileserver config",
    $PathsPrefix = "$env:PUBLIC\Documents",
    $RunDetectionPath = "$PathsPrefix\InstallationScriptRun.txt"
)

if (!(Test-Path -Path $RunDetectionPath)) {
    #Disable IE Enchanced Security
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0

    #Change the name of the computer
    Rename-Computer -NewName $Hostname

    #Create first run detection file
    New-Item -ItemType File -Path $RunDetectionPath -Value "1"

    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-command `". '$($MyInvocation.MyCommand.Path)'`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName $ScheduledTaskName -Trigger $Trigger -Action $Action

    #Restart Computer
    Restart-Computer
    return
}

if ((Get-Content $RunDetectionPath) -eq "1") {
    Add-Computer -DomainName $Domain -OUPath $OUPath

    #Create first run detection file
    Out-File -InputObject "2" -FilePath $RunDetectionPath

    Restart-Computer
    return
}

#Install required modules
$RequiredModulesNameArray = @('NTFSSecurity')
$RequiredModulesNameArray.ForEach({
    if (Get-InstalledModule $_ -ErrorAction SilentlyContinue) {
        Import-Module $_ -Force
    } else {
        Install-Module $_ -Force -Repository PSGallery
    }
})

#Get the ID of the disk where we're creating shares
$DiskId = (Get-Disk).where({
    $_.PartitionStyle -eq "RAW"
})[0].UniqueId

#Initialize the disk
Initialize-Disk -UniqueId $DiskId -PartitionStyle "GPT"
#Create partition
New-Partition -DiskId $DiskId -DriveLetter $DriveLetter -UseMaximumSize
#Format partition
Format-Volume -DriveLetter $DriveLetter

#Create folders from xml file
$RepoRoot = (Get-Item $PSScriptRoot).parent.fullname
Import-Module "$RepoRoot\NN.Fagprove\NN.Fagprove\0.0.1\NN.Fagprove.psm1"
[xml]$xml = Get-Content -Raw "$PSScriptRoot\Fileserver-FolderStructure.xml"
New-FolderStructure -Node $xml.object

#Disable inheritance and remove default access
(Get-ChildItem "$($DriveLetter):\").FullName.ForEach({
    Disable-NTFSAccessInheritance -Path $_

    (Get-NTFSAccess -Path $_).where({
        $_.Account -eq "BUILTIN\Users"
    }) | Remove-NTFSAccess
})

#Add NTFS access and set up home share
$HomeShare = @{
    "Path" = "F:\Home"
    "Access" = "CORP\Domain Users"
    "Name" = "Home$"
    "AppliesTo" = "ThisFolderOnly"
    "AccessRights" = "Traverse,ListDirectory"
}
Add-NTFSAccess -Path $HomeShare.Path -Account $HomeShare.Access -AccessRights $HomeShare.AccessRights -AppliesTo $HomeShare.AppliesTo
Add-NTFSAccess -Path $HomeShare.Path -Account "CORP\Domain Admins" -AccessRights "FullControl" -AppliesTo "ThisFolderSubfoldersAndFiles"
New-SmbShare -FullAccess @("CORP\Domain Users","CORP\Domain Admins") -Name $HomeShare.Name -Path $HomeShare.Path -FolderEnumerationMode "AccessBased"

#Add NTFS access and set up Felles share
$FellesShare = @{
    "Path" = "F:\Felles"
    "Access" = "CORP\Employees"
    "Name" = "Felles"
    "AppliesTo" = "ThisFolderSubfoldersAndFiles"
    "AccessRights" = "Modify"
}
Add-NTFSAccess -Path $FellesShare.Path -Account $FellesShare.Access -AccessRights $FellesShare.AccessRights -AppliesTo $FellesShare.AppliesTo
Add-NTFSAccess -Path $FellesShare.Path -Account "CORP\Domain Admins" -AccessRights "FullControl" -AppliesTo "ThisFolderSubfoldersAndFiles"
New-SmbShare -FullAccess @("CORP\Employees","CORP\Domain Admins") -Name $FellesShare.Name -Path $FellesShare.Path -FolderEnumerationMode "AccessBased"

#Add NTFS access and set up GPO share
$GPOShare = @{
    "Path" = "F:\GPO"
    "Access" = "CORP\Domain Users","CORP\Domain Computers"
    "Name" = "GPO$"
    "AppliesTo" = "ThisFolderOnly"
    "AccessRights" = "Traverse,ListDirectory"
}
Add-NTFSAccess -Path $GPOShare.Path -Account $GPOShare.Access -AccessRights $GPOShare.AccessRights -AppliesTo $GPOShare.AppliesTo
Add-NTFSAccess -Path $GPOShare.Path -Account "CORP\Domain Admins" -AccessRights "FullControl" -AppliesTo "ThisFolderSubfoldersAndFiles"
New-SmbShare -FullAccess @("CORP\Domain Users","CORP\Domain Computers","CORP\Domain Admins") -Name $GPOShare.Name -Path $GPOShare.Path -FolderEnumerationMode "AccessBased"

#Add NTFS access to GPO share subfolders
$splat = @{
    "AppliesTo" = "ThisFolderSubfoldersAndFiles"
    "AccessRights" = "ReadAndExecute"
}
Add-NTFSAccess @splat -Path "$($GPOShare.Path)\user-policies" -Account "CORP\Domain Users"
Add-NTFSAccess @splat -Path "$($GPOShare.Path)\computer-policies" -Account "CORP\Domain Computers"
Add-NTFSAccess @splat -Path "$($GPOShare.Path)\user-computer-policies" -Account @("CORP\Domain Users","CORP\Domain Computers")

#Cleanup
Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
Remove-Item -Path $RunDetectionPath

#Allow user to read outputs before exiting
pause