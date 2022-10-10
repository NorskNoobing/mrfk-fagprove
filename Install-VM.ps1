#Share
    $splat = @{
        "VMName" = "danhol_Share-01"
        "MemoryStartupBytes" = "2GB"
        "NewVHDSizeBytes" = "40GB","10GB"
        "AdditionalVHDNames" = "Share"
        "Generation" = "2"
        "ISOPath" = "D:\isos\SW_DVD9_Win_Server_STD_CORE_2019_1809.10_64Bit_English_DC_STD_MLF_X22-47318.iso"
        "SwitchName" = "stud-server-danhol"
    }
    New-STUDVM @splat
#Router
    $splat = @{
        "VMName" = "danhol_fw-01"
        "MemoryStartupBytes" = "2GB"
        "NewVHDSizeBytes" = "20GB"
        "Generation" = "1"
        "ISOPath" = "D:\isos\pfsense-ce-2.6.0-release-amd64.iso"
        "SwitchName" = "stud-Internett","stud-server-danhol","stud-print-danhol","stud-klient-danhol"
    }
    New-STUDVM @splat

    #Remove boot media
    $VMName = "danhol_fw-01"
    $ComputerName = "MSHPV01.intern.mrfylke.no"
    $ISOPath = "D:\isos\pfsense-ce-2.6.0-release-amd64.iso"
    Stop-VM -ComputerName $ComputerName -VMName $VMName -Force
    (Get-VMDvdDrive -ComputerName $ComputerName -VMName $VMName).where{$_.Path -eq $ISOPath} | Remove-VMDvdDrive
    Start-VM -ComputerName $ComputerName -VMName $VMName

    #Get NIC MacAddress
    Get-VMNetworkAdapter -ComputerName $ComputerName -VMName $VMName | Select-Object SwitchName,MacAddress
#DC
    $splat = @{
        "VMName" = "danhol_dc-01"
        "MemoryStartupBytes" = "2GB"
        "NewVHDSizeBytes" = "60GB"
        "Generation" = "2"
        "ISOPath" = "D:\isos\SW_DVD9_Win_Server_STD_CORE_2019_1809.10_64Bit_English_DC_STD_MLF_X22-47318.iso"
        "SwitchName" = "stud-server-danhol","stud-print-danhol","stud-klient-danhol"
    }
    New-STUDVM @splat
#Client
    $splat = @{
        "VMName" = "danhol_client-01" 
        "MemoryStartupBytes" = "2GB"
        "NewVHDSizeBytes" = "40GB"
        "Generation" = "2"
        "ISOPath" = "D:\isos\SW_DVD9_Win_Pro_10_21H2.5_64BIT_Norwegian_Pro_Ent_EDU_N_MLF_X23-11148.iso"
        "SwitchName" = "stud-klient-danhol"
    }
    New-STUDVM @splat