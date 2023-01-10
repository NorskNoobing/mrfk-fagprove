function New-AdAdminUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$DisplayName,
        [int]$StartNum = "1"
    )

    process {
        $NameSplit = ($DisplayName -split " ")
    
        $GivenName = $NameSplit[0..$NameSplit.IndexOf($NameSplit[-2])]
        $Surname = $NameSplit[-1]
    
        while ($UserExists) {
            $Username = ("adm_" + $GivenName.Substring(0,3) + $Surname.Substring(0,3) + $StartNum.PadLeft(2,"0")).ToLower()
            $UserExists = Get-ADUser $Username -ErrorAction SilentlyContinue
        }
        
        $splat = @{
            "AccountPassword" = Read-Host "Please enter a new password for user `"$Username`"" -AsSecureString
            "DisplayName" = "$DisplayName (Admin)"
            "Enabled" = $true
            "GivenName" = $GivenName
            "Surname" = $Surname
            "SamAccountName" = $Username
        }
        New-ADUser @splat
    }
}

New-ADOrganizationalUnit -Name "Admins"

$AdminsArr = @("Ola Nordmann")
$AdminsArr.ForEach({
    New-AdAdminUser -DisplayName $_
})