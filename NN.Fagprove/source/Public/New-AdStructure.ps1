function New-AdStructure {
    param (
        [Parameter(Mandatory)][xml]$Node,
        [Parameter(Mandatory)][string]$Path,
        [string]$AdminsOuPath = "",
        [string]$UsersOuPath = ""
    )

    $Node.ForEach({
        $result = $null

        switch ($_.type) {
            ou {
                $result = New-ADOrganizationalUnit -Path $Path -Name $_.name -PassThru
    
                if ($_.object) {
                    New-AdStructure -Node $_.object -Path $result.DistinguishedName
                }
            }
            user {
                switch ($_.usertype) {
                    Admin {
                        $result = New-FpAdUser -DisplayName $_.name -UserType "Admin" -Path $AdminsOuPath
                    }
                    Standard {
                        $result = New-FpAdUser -DisplayName $_.name -UserType "Standard" -Path $UsersOuPath
                    }
                }
            }
            group {
                $result = New-ADGroup -Path $Path -Name $_.name -PassThru
            }
        }

        if ($_.MemberOf) {
            $_.MemberOf.ForEach({
                $AdGroup = $null
                $AdGroup = Get-ADGroup $_.name
                Add-ADGroupMember -Members $result.DistinguishedName -Identity $AdGroup.DistinguishedName
            })
        }
    })
}