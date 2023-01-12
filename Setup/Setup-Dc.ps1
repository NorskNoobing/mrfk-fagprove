param (
    #DC settings
    $IP = "10.0.10.10",
    $DefaultGateway = "10.0.10.1",
    $SubnetMask = "24",
    $DNS = "127.0.0.1",
    $Hostname = "SR-WINSRV19-001",

    #AD domain
    $DomainName = "corp.local",
    $DomainNetbiosName = "corp",

    #DHCP
    $DnsServer = $IP,

    $ServerStartRange = "10.0.10.1",
    $ServerEndRange = "10.0.10.254",
    $ServerSubnetMask = "255.255.255.0",
    $ServerExclusionStartRange = "10.0.10.1",
    $ServerExclusionEndRange = "10.0.10.10",

    $ClientStartRange = "10.0.20.1",
    $ClientEndRange = "10.0.21.254",
    $ClientSubnetMask = "255.255.254.0",
    $ClientExclusionStartRange = "10.0.20.1",
    $ClientExclusionEndRange = "10.0.20.25",

    $PrintStartRange = "10.0.30.1",
    $PrintEndRange = "10.0.30.254",
    $PrintSubnetMask = "255.255.255.0",
    $PrintExclusionStartRange = "10.0.30.1",
    $PrintExclusionEndRange = "10.0.30.10",

    #Misc
    $ScheduledTaskName = "DC config",
    $PathsPrefix = "$env:PUBLIC\Documents",
    $RunDetectionPath = "$PathsPrefix\InstallationScriptRun.txt",
    $AdDsSafeModePwdPath = "$PathsPrefix\AdDsSafeModePwd.xml",
    $AdUserTempPwdPath = "$PathsPrefix\AdUserTempPwd.xml"
)

if (!(Test-Path -Path $RunDetectionPath)) {
    Read-Host "Enter ADDS safe-mode password" -AsSecureString | ConvertFrom-SecureString | Export-Clixml $AdDsSafeModePwdPath
    Read-Host "Please enter a temp-password for the AD-Users" -AsSecureString | ConvertFrom-SecureString | Export-Clixml $AdUserTempPwdPath

    #Disable IE Enchanced Security
    #todo: explain Set-ItemProperty, reg paths
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0

    #Disable IPv6 on the first network adapter with the name "*eth*"
    #todo: explain where, where syntax, $_, |, [0], Get-NetAdapterBinding, and Disable-NetAdapterBinding
    (Get-NetAdapterBinding).Where({($_.ComponentID -eq 'ms_tcpip6') -and ($_.Name -like "*eth*")})[0] | Disable-NetAdapterBinding

    #Get the index of the first network adapter with the name "*eth*"
    $NetworkInterfaceIndex = (Get-NetAdapter | Where-Object {$_.Name -like "*eth*"})[0].InterfaceIndex
    #Set static IP
    New-NetIPAddress -IPAddress $IP -DefaultGateway $DefaultGateway -PrefixLength $SubnetMask -InterfaceIndex $NetworkInterfaceIndex
    #Set DNS settings
    Set-DnsClientServerAddress -InterfaceIndex $NetworkInterfaceIndex -ServerAddresses $DNS

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
    #Install AD
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    #Configure AD
    $splat = @{
        "DomainName" = $DomainName
        "DomainMode" = "7"
        "DomainNetbiosName" = $DomainNetbiosName
        "ForestMode" = "7"
        "NoRebootOnCompletion" = $true
        "Force" = $true
        "SafeModeAdministratorPassword" = Import-Clixml $AdDsSafeModePwdPath | ConvertTo-SecureString
    }
    Install-ADDSForest @splat

    #Create first run detection file
    Out-File -InputObject "2" -FilePath $RunDetectionPath

    Restart-Computer
    return
}

#Set AD password policy
$splat = @{
    "MaxPasswordAge" = "0"
    "MinPasswordAge" = "0"
    "Identity" = $DomainName
    "PasswordHistoryCount" = "1"
    "ComplexityEnabled" = $true
}
Set-ADDefaultDomainPasswordPolicy @splat

#Set up AD config
$RepoRoot = (Get-Item $PSScriptRoot).parent.fullname
Import-Module "$RepoRoot\NN.Fagprove\NN.Fagprove\0.0.1\NN.Fagprove.psm1"
[xml]$xml = Get-Content -Raw "$PSScriptRoot\AD-structure.xml"
$DomainRoot = (Get-ADDomain).DistinguishedName
New-AdStructure -Node $xml.object -Path $DomainRoot -UserTempPassword (Import-Clixml $AdUserTempPwdPath)

#Install DNS
Install-WindowsFeature -Name DNS -IncludeManagementTools

#Add DNS forwarders
Add-DnsServerForwarder -IPAddress "1.1.1.1"
Add-DnsServerForwarder -IPAddress "8.8.8.8"

#Install DHCP
Install-WindowsFeature -Name DHCP -IncludeManagementTools

#Set DHCP server settings
Set-DhcpServerv4OptionValue -DnsServer $DnsServer -DnsDomain $DomainName

#Add DHCP scope for server network
$splat = @{
    "Name" = "Server"
    "StartRange" = $ServerStartRange
    "EndRange" = $ServerEndRange
    "SubnetMask" = $ServerSubnetMask
}
Add-DhcpServerv4Scope @splat
#Set exclusion range
$ServerScopeId = (Get-DhcpServerv4Scope | Where-Object {$_.Name -eq "Server"}).ScopeId
Add-Dhcpserverv4ExclusionRange -ScopeId $ServerScopeId -StartRange $ServerExclusionStartRange -EndRange $ServerExclusionEndRange

#Add DHCP scope for client network
$splat = @{
    "Name" = "Client"
    "StartRange" = $ClientStartRange
    "EndRange" = $ClientEndRange
    "SubnetMask" = $ClientSubnetMask
}
Add-DhcpServerv4Scope @splat
#Set exclusion range
$ClientScopeId = (Get-DhcpServerv4Scope | Where-Object {$_.Name -eq "Client"}).ScopeId
Add-Dhcpserverv4ExclusionRange -ScopeId $ClientScopeId -StartRange $ClientExclusionStartRange -EndRange $ClientExclusionEndRange

#Add DHCP scope for print network
$splat = @{
    "Name" = "Print"
    "StartRange" = $PrintStartRange
    "EndRange" = $PrintEndRange
    "SubnetMask" = $PrintSubnetMask
}
Add-DhcpServerv4Scope @splat
#Set exclusion range
$PrintScopeId = (Get-DhcpServerv4Scope | Where-Object {$_.Name -eq "Print"}).ScopeId
Add-Dhcpserverv4ExclusionRange -ScopeId $PrintScopeId -StartRange $PrintExclusionStartRange -EndRange $PrintExclusionEndRange

#Cleanup
Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
Remove-Item -Path $RunDetectionPath
Remove-Item -Path $AdDsSafeModePwdPath
Remove-Item -Path $AdUserTempPwdPath

#Allow user to read outputs before exiting
pause