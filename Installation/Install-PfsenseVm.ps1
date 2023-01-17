<#
    Set up Pfsense VM
#>
param (
    [string]$ComputerName = "MSHPV01.intern.mrfylke.no",
    [string]$VmPath = "D:\students\$env:USERNAME",
    [string]$WanSwitch = "stud-Internett",
    [string]$ServerSwitch = "stud-server-danhol",
    [string]$ClientSwitch = "stud-klient-danhol",
    [string]$PrintSwitch = "stud-print-danhol",
    [string]$PfsenseIso = "D:\isos\pfSense-CE-2.6.0-RELEASE-amd64.iso",
    #Set VmName
    [string]$VmName = "$($env:USERNAME)_PengebingenAs-fw01",
    #Set path for the VMs disk
    [string]$VhdPath = "$VmPath\disk\$VmName.vhdx"
)

#Set all New-VM function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "Name" = $VmName
    #Local path to where the VM should be saved on the Hyper-V host
    "Path" = $VmPath
    #Allocated RAM size
    "MemoryStartupBytes" = "2GB"
    #Name of the default virtual switch
    "SwitchName" = $WanSwitch
    #Local path to where the VHD should be saved on the Hyper-V host
    "NewVHDPath" = $VhdPath
    #Size of the VHD in GB
    "NewVHDSizeBytes" = "20GB"
    #Hyper-V BIOS version of the VM
    "Generation" = "1"
}
#Run function that creates the VM
$null = New-VM @splat

#Create an array for the extra network adapters
$VirtualSwitchArr = @($ServerSwitch,$ClientSwitch,$PrintSwitch)

#Set all Add-VMNetworkAdapter function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "VMName" = $VmName
}
<#
    Go through the items in $VirtualSwitchArr one by one, 
    and run the following function for each of them
#>
$VirtualSwitchArr.ForEach({
    #Run function that adds network adapter to VM
    Add-VMNetworkAdapter @splat -SwitchName $_
})

#Set all Add-VMDVDDrive function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "VMName" = $VmName
    #Local path to the ISO file
    "Path" = $PfsenseIso
}
#Run function that adds ISO file to your VM
Add-VMDVDDrive @splat

#Set all Set-VMMemory function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "VMName" = $VmName
    #Local path to the ISO file
    "DynamicMemoryEnabled" = $true
}
#Run function that enables dynamic VM memory
Set-VMMemory @splat

#Set all Set-VMProcessor function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "VMName" = $VmName
    #Number of virtual processors
    "Count" = "2"
}
#Run function that sets the processor to 2-cores instead of 1
Set-VMProcessor @splat

$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "Name" = $VmName
}
Start-VM @splat