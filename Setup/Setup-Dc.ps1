param (
    #DC settings
    $IP = "10.0.10.10",
    $DefaultGateway = "10.0.10.1",
    $SubnetMask = "24",
    $DNS = "127.0.0.1",
    $Hostname = "SR-WINSRV19-001",

    #AD
    $DomainName = "corp.local",
    $DomainNetbiosName = "corp",
    $OUPath = "OU=Servers,OU=Computers,OU=CORP,DC=corp,DC=local",

    #DNS
    $DNSForwarders = @("1.1.1.1","8.8.8.8"),

    #DHCP
    $DnsServer = $IP,

    $DhcpScopeArr = @(
        @{
            "ScopeName" = "Server"
            "StartRange" = "10.0.10.1"
            "EndRange" = "10.0.10.254"
            "SubnetMask" = "255.255.255.0"
            "ExclusionStartRange" = "10.0.10.1"
            "ExclusionEndRange" = "10.0.10.20"
        },
        @{
            "ScopeName" = "Client"
            "StartRange" = "10.0.20.1"
            "EndRange" = "10.0.21.254"
            "SubnetMask" = "255.255.254.0"
            "ExclusionStartRange" = "10.0.20.1"
            "ExclusionEndRange" = "10.0.20.25"
        },
        @{
            "ScopeName" = "Print"
            "StartRange" = "10.0.30.1"
            "EndRange" = "10.0.30.254"
            "SubnetMask" = "255.255.255.0"
            "ExclusionStartRange" = "10.0.30.1"
            "ExclusionEndRange" = "10.0.30.10"
        }
    ),

    #Misc
    $ScheduledTaskName = "DC config",
    $PathsPrefix = "$env:PUBLIC\Documents",
    $RunDetectionPath = "$PathsPrefix\InstallationScriptRun.txt",
    $AdDsSafeModePwdPath = "$PathsPrefix\AdDsSafeModePwd.xml",
    $AdUserTempPwdPath = "$PathsPrefix\AdUserTempPwd.xml"
)

if (!(Test-Path -Path $RunDetectionPath)) {
    Read-Host "Enter ADDS safe-mode password" -AsSecureString | ConvertFrom-SecureString | 
    Export-Clixml $AdDsSafeModePwdPath
    Read-Host "Please enter a temp-password for the AD-Users" -AsSecureString | 
    ConvertFrom-SecureString | Export-Clixml $AdUserTempPwdPath

    #Disable IE Enchanced Security
    Set-ItemProperty -Path @"
HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}
"@ -Name "IsInstalled" -Value 0

    #Disable IPv6 on the first network adapter with the name "*eth*"
    (Get-NetAdapterBinding).Where({
        ($_.ComponentID -eq 'ms_tcpip6') -and ($_.Name -like "*eth*")
    })[0] | Disable-NetAdapterBinding

    #Get the index of the first network adapter with the name "*eth*"
    $NetworkInterfaceIndex = (Get-NetAdapter | 
    Where-Object {$_.Name -like "*eth*"})[0].InterfaceIndex
    #Set static IP
    New-NetIPAddress -IPAddress $IP -DefaultGateway $DefaultGateway `
    -PrefixLength $SubnetMask -InterfaceIndex $NetworkInterfaceIndex
    #Set DNS settings
    Set-DnsClientServerAddress -InterfaceIndex $NetworkInterfaceIndex -ServerAddresses $DNS

    #Change the name of the computer
    Rename-Computer -NewName $Hostname

    #Create first run detection file
    New-Item -ItemType File -Path $RunDetectionPath -Value "1"

    $Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" -Argument "-command `". '$($MyInvocation.MyCommand.Path)'`""
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
        "SafeModeAdministratorPassword" = Import-Clixml $AdDsSafeModePwdPath | 
        ConvertTo-SecureString
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
New-AdStructure -Node $xml.object -Path $DomainRoot `
-UserTempPassword (Import-Clixml $AdUserTempPwdPath)

#Move DC into the right OU
Move-ADObject -Identity (Get-ADComputer $Hostname).DistinguishedName -TargetPath $OUPath

#Install DNS
Install-WindowsFeature -Name DNS -IncludeManagementTools

#Add DNS forwarders
$DNSForwarders.ForEach({
    Add-DnsServerForwarder -IPAddress $_
})

#Install DHCP
Install-WindowsFeature -Name DHCP -IncludeManagementTools

#Set DHCP server settings
Set-DhcpServerv4OptionValue -DnsServer $DnsServer -DnsDomain $DomainName

#Add all DHCP scopes
$DhcpScopeArr.ForEach({
    $splat = @{
        "Name" = $_.ScopeName
        "StartRange" = $_.StartRange
        "EndRange" = $_.EndRange
        "SubnetMask" = $_.SubnetMask
        "PassThru" = $true
    }
    $result = Add-DhcpServerv4Scope @splat

    $splat = @{
        "ScopeId" = $result.ScopeId
        "StartRange" = $_.ExclusionStartRange
        "EndRange" = $_.ExclusionEndRange
    }
    Add-Dhcpserverv4ExclusionRange @splat

    $splat = @{
        "ScopeId" = $result.ScopeId
        "Router" = $_.StartRange
    }
    Set-DhcpServerv4OptionValue @splat
})

#Authorize DHCP server in domain
Add-DhcpServerInDC -DnsName $Hostname -IPAddress $IP

#Cleanup
Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
$FilepathArr = @($RunDetectionPath,$AdDsSafeModePwdPath,$AdUserTempPwdPath)
$FilePathArr.ForEach({
    Remove-Item -Path $_
})

#Allow user to read outputs before exiting
pause