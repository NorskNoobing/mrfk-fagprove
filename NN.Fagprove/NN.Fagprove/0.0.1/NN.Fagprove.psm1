#Region '.\Public\New-AdStructure.ps1' 0
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
                switch ($item.usertype) {
                    Admin {
                        $result = New-FpAdUser -DisplayName $item.name -UserType "Admin" -Path $Path -Password ($UserTempPassword | ConvertTo-SecureString)
                    }
                    Standard {
                        $result = New-FpAdUser -DisplayName $item.name -UserType "Standard" -Path $Path -Password ($UserTempPassword | ConvertTo-SecureString)
                    }
                }
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
#EndRegion '.\Public\New-AdStructure.ps1' 43
#Region '.\Public\New-FpAdUser.ps1' 0
function New-FpAdUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][ValidateSet("Standard","Admin")][string]$UserType,
        [Parameter(Mandatory)][string]$Path,
        [securestring]$Password
    )

    process {
        $NameSplit = ($DisplayName -split " ")
    
        [string]$GivenName = $NameSplit[0..$NameSplit.IndexOf($NameSplit[-2])]
        $Surname = $NameSplit[-1]

        #Set username
        switch ($UserType) {
            Standard {
                $UsernameStr = $GivenName.Substring(0,3) + $Surname.Substring(0,3)
            }
            Admin {
                $UsernameStr = "adm_" + $GivenName.Substring(0,3) + $Surname.Substring(0,3)
                $DisplayName = "$DisplayName (Admin)"
            }
        }

        $UsernameStr = $UsernameStr.ToLower()
        $StartNum = "1"

        #Auto inrement username if it's already taken
        while (!$ExitLoop) {
            $Username = $UsernameStr + $StartNum.PadLeft(2,"0")
            try {
                $UserExists = Get-ADUser $Username
            }
            catch {}

            if (!$UserExists) {
                $ExitLoop = $true
            } else {
                $StartNum++
            }
        }

        if (!$Password) {
            $Password = Read-Host "Please enter a new password for user `"$Username`"" -AsSecureString
        }
        
        $splat = @{
            "AccountPassword" = $Password
            "DisplayName" = $DisplayName
            "Enabled" = $true
            "GivenName" = $GivenName
            "Surname" = $Surname
            "SamAccountName" = $Username
            "Name" = $Username
            "Path" = $Path
            "PassThru" = $true
        }
        New-ADUser @splat
    }
}
#EndRegion '.\Public\New-FpAdUser.ps1' 63
