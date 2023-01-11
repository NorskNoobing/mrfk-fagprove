#Region '.\Public\New-FpAdUser.ps1' 0
function New-FpAdUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][ValidateSet("Standard","Admin")][string]$UserType,
        [Parameter(Mandatory)][string]$Path
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
        
        $splat = @{
            "AccountPassword" = Read-Host "Please enter a new password for user `"$Username`"" -AsSecureString
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
#EndRegion '.\Public\New-FpAdUser.ps1' 58
