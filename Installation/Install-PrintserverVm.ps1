<#
    Set up DC VM
#>
param (
    [string]$ComputerName = "MSHPV01.intern.mrfylke.no",
    [string]$VmPath = "D:\students\$env:USERNAME",
    [string]$ServerSwitch = "stud-server-danhol",
    [string]$WindowsServerIso = "D:\isos\eval\17763.737.190906-2324.rs5_release_svc_refresh_server_eval_x64fre_en-us_1 (1).iso",
    #Set VmName
    [string]$VmName = "$($env:USERNAME)_PengebingenAs-print01",
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
    "MemoryStartupBytes" = "4GB"
    #Name of the default virtual switch
    "SwitchName" = $ServerSwitch
    #Local path to where the VHD should be saved on the Hyper-V host
    "NewVHDPath" = $VhdPath
    #Size of the VHD in GB
    "NewVHDSizeBytes" = "40GB"
    #Hyper-V BIOS version of the VM
    "Generation" = "2"
}
#Run function that creates the VM
$null = New-VM @splat

#Set all Add-VMDVDDrive function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "VMName" = $VmName
    #Local path to the ISO file
    "Path" = $WindowsServerIso
}
#Run function that adds ISO file to your VM
Add-VMDVDDrive @splat

#Set all Set-VMFirmware function params
$splat = @{
    #Hostname of the computer running the Hyper-V service
    "ComputerName" = $ComputerName
    #Name of the VM
    "VMName" = $VmName
    #Get the virtual DVD drive for the ISO file, and add it boot priority param
    "FirstBootDevice" = Get-VMDvdDrive -ComputerName $ComputerName -VMName $VmName
}
#Run function that sets the boot priority to ISO file
Set-VMFirmware @splat

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