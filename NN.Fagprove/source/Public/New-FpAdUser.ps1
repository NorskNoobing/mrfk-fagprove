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
        $UsernameStr = $GivenName.Substring(0,3) + $Surname.Substring(0,3)
        if ($UserType -eq "Admin") {
            $UsernameStr = "adm_" + $UsernameStr
            $DisplayName = "$DisplayName (Admin)"
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
            "UserPrincipalName" = "$($NameSplit -join ".")@pengebingen.net"
        }
        New-ADUser @splat
    }
}