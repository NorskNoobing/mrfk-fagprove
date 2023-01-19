param (
    $Hostname = "SR-WINSRV19-003",
    $Domain = "corp.local",
    $OUPath = "OU=Servers,OU=Computers,OU=CORP,DC=corp,DC=local",

    #Misc
    $ScheduledTaskName = "Printserver config",
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

#Install Print role
Install-WindowsFeature -Name Print-Server -IncludeManagementTools

#Cleanup
Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
Remove-Item -Path $RunDetectionPath

#Allow user to read outputs before exiting
pause