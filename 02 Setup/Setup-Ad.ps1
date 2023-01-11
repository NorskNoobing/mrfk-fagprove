param(
    $AdminsArr = @("Domeinar Admsen"),
    $UsersArr = @("Boss Baby","Deez Nutz","Joe Biden"),

    $DomainRootPath = "DC=corp,DC=local",
    $BaseOuPath = "OU=CORP,$DomainRootPath",
    $GroupOuPath = "OU=Groups,$BaseOuPath",
    $UsersOuPath = "OU=Users,$BaseOuPath",
    $AdminsOuPath = "OU=Admins,$BaseOuPath"
)

function New-MrfkAdUser {
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
        }
        New-ADUser @splat
    }
}

#Create OUs
New-ADOrganizationalUnit -Name "CORP" -Path $DomainRootPath
New-ADOrganizationalUnit -Name "Admins" -Path $BaseOuPath
New-ADOrganizationalUnit -Name "Users" -Path $BaseOuPath
New-ADOrganizationalUnit -Name "Groups" -Path $BaseOuPath

#Create all users
$AdminsArr.ForEach({
    New-MrfkAdUser -DisplayName $_ -UserType "Admin" -Path $AdminsOuPath
})

$UsersArr.ForEach({
    New-MrfkAdUser -DisplayName $_ -UserType "Standard" -Path $UsersOuPath
})

#Create AD-groups
New-ADGroup -Name "Ansatte" -Path $GroupOuPath -GroupScope Global
New-ADGroup -Name "Salg" -Path $GroupOuPath -GroupScope Global
New-ADGroup -Name "Produksjon" -Path $GroupOuPath -GroupScope Global
New-ADGroup -Name "Ledelse" -Path $GroupOuPath -GroupScope Global

#Add AD-group members
Add-ADGroupMember -Identity "CN=Ansatte,$GroupOuPath" -Members @(
    "CN=Salg,$GroupOuPath",
    "CN=Produksjon,$GroupOuPath",
    "CN=Ledelse,$GroupOuPath"
)

#Add domain admins to group
Add-ADGroupMember -Identity "CN=Domain Admins,CN=Users,$DomainRootPath" -Members @(
    "CN=adm_olanor01,$AdminsOuPath"
)

#Add users to Ledelse group
Add-ADGroupMember -Identity "CN=Ledelse,$GroupOuPath" -Members @(
    "CN=bosbab01,$UsersOuPath"
)

#Add users to Salg group
Add-ADGroupMember -Identity "CN=Salg,$GroupOuPath" -Members @(
    "CN=joebid01,$UsersOuPath"
)

#Add users to Produksjon group
Add-ADGroupMember -Identity "CN=Produksjon,$GroupOuPath" -Members @(
    "CN=deenut01,$UsersOuPath"
)