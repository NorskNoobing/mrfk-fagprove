function New-STUDVM {
    param (
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][string]$MemoryStartupBytes,
        [Parameter(Mandatory)][array]$NewVHDSizeBytes,
        [array]$AdditionalVHDNames,
        [string]$ComputerName = "MSHPV01.intern.mrfylke.no",
        [Parameter(Mandatory)][int]$Generation,
        [Parameter(Mandatory)][string]$ISOPath,
        [Parameter(Mandatory)]$SwitchName,
        [switch]$DisableSecureBoot
    )
    
    New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -ComputerName $ComputerName -Generation $Generation
    Add-VMDVDDrive -ComputerName $ComputerName -VMName $VMName -Path $ISOPath

    $SwitchName | ForEach-Object {Add-VMNetworkAdapter -ComputerName $ComputerName -VMName $VMName -SwitchName $_}

    $i = 0
    while ($i -lt $NewVHDSizeBytes.count) {
        if ($i -eq 0) {
            $CurrentVHDName = $VMName
        } else {
            $CurrentVHDName = "$VMName-$($AdditionalVHDNames[$($i - 1)])"
        }

        New-VHD -Path "D:\vhd\$CurrentVHDName.vhdx" -Dynamic -SizeBytes $NewVHDSizeBytes[$i] -ComputerName $ComputerName
        Add-VMHardDiskDrive -VMName $VMName -Path "D:\vhd\$CurrentVHDName.vhdx" -ComputerName $ComputerName
        $i++
    }
    
    if ($DisableSecureBoot) {
        Set-VMFirmware -ComputerName $ComputerName -VMName $VMName -EnableSecureBoot Off
    }
}