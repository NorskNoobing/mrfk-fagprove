<#
    Set up client VM
#>
param (
    [string]$ComputerName = "MSHPV01.intern.mrfylke.no",
    [string]$VmPath = "D:\students\$env:USERNAME",
    [string]$ClientSwitch = "stud-klient-danhol",
    [string]$Windows10Iso = "D:\isos\SW_DVD9_Win_Pro_10_21H2.5_64BIT_Norwegian_Pro_Ent_EDU_N_MLF_X23-11148.ISO",
    #Set VmName
    [string]$VmName = "$($env:USERNAME)_client01",
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
    "SwitchName" = $ClientSwitch
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
    "Path" = $Windows10Iso
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