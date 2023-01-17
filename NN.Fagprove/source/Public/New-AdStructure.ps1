function New-AdStructure {
    param (
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][string]$Path,
        [string]$UserTempPassword
    )

    foreach ($item in $Node) {
        $result = $null

        switch ($item.type) {
            ou {
                $result = New-ADOrganizationalUnit -Path $Path -Name $item.name -PassThru
    
                if ($item.object) {
                    New-AdStructure -Node $item.object -Path $result.DistinguishedName -UserTempPassword $UserTempPassword
                }
            }
            user {
                $result = New-FpAdUser -DisplayName $item.name -UserType $item.usertype -Path $Path -Password ($UserTempPassword | ConvertTo-SecureString)
            }
            group {
                $result = New-ADGroup -Path $Path -Name $item.name -PassThru -GroupScope Global
            }
        }

        if ($item.MemberOf) {
            foreach ($group in $item.MemberOf) {
                $AdGroup = $null
                $AdGroup = Get-ADGroup $group.name
                Add-ADGroupMember -Members $result.DistinguishedName -Identity $AdGroup.DistinguishedName
            }
        }
    }
}