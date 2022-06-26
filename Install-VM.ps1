#New
New-STUDVM -VMName "danhol_FW-01" -MemoryStartupBytes "2GB" -NewVHDSizeBytes "20GB" -Generation "1" -ISOPath "D:\isos\pfsense-ce-2.6.0-release-amd64.iso" -SwitchName "stud-Internett","stud-server-danhol","stud-print-danhol","stud-klient-danhol"
New-STUDVM -VMName "danhol_DC-01" -MemoryStartupBytes "2GB" -NewVHDSizeBytes "60GB" -Generation "2" -ISOPath "D:\isos\SW_DVD9_Win_Server_STD_CORE_2019_1809.10_64Bit_English_DC_STD_MLF_X22-47318.iso" -SwitchName "stud-server-danhol"
New-STUDVM -VMName "danhol_Share-01" -MemoryStartupBytes "2GB" -NewVHDSizeBytes "40GB","10GB" -AdditionalVHDNames "Share" -Generation "2" -ISOPath "D:\isos\SW_DVD9_Win_Server_STD_CORE_2019_1809.10_64Bit_English_DC_STD_MLF_X22-47318.iso" -SwitchName "stud-server-danhol"
New-STUDVM -VMName "danhol_Klient-01" -MemoryStartupBytes "2GB" -NewVHDSizeBytes "40GB" -Generation "2" -ISOPath "D:\isos\SW_DVD9_Win_Pro_10_21H2.5_64BIT_Norwegian_Pro_Ent_EDU_N_MLF_X23-11148.iso" -SwitchName "stud-klient-danhol"

#Old
New-VM -ComputerName "mshpv01" -Name "danhol_FW-01" -MemoryStartupBytes "2GB" -NewVHDPath "D:\vhd\danhol_FW-01.vhdx" -NewVHDSizeBytes "20GB" -Generation "1" -SwitchName "stud-server-danhol"
Add-VMDVDDrive -ComputerName "mshpv01" -VMName "danhol_FW-01" -Path "D:\isos\pfsense-ce-2.6.0-release-amd64.iso"
Add-VMNetworkAdapter -ComputerName "mshpv01" -VMName "danhol_FW-01" -SwitchName "stud-Internett"
Add-VMNetworkAdapter -ComputerName "mshpv01" -VMName "danhol_FW-01" -SwitchName "stud-print-danhol"
Add-VMNetworkAdapter -ComputerName "mshpv01" -VMName "danhol_FW-01" -SwitchName "stud-klient-danhol"
Set-VMFirmware -ComputerName "mshpv01" -VMName "danhol_FW-01" -EnableSecureBoot "Off"