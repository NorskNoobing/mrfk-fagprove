param(
    $AdminsArr = @("Domeinar Admsen"),
    $UsersArr = @("Boss Baby","Deez Nutz","Joe Biden"),

    $DomainRootPath = "DC=corp,DC=local",
    $BaseOuPath = "OU=CORP,$DomainRootPath",
    $GroupOuPath = "OU=Groups,$BaseOuPath",
    $UsersOuPath = "OU=Users,$BaseOuPath",
    $AdminsOuPath = "OU=Admins,$BaseOuPath"
)

#Create OUs
New-ADOrganizationalUnit -Name "CORP" -Path $DomainRootPath
New-ADOrganizationalUnit -Name "Admins" -Path $BaseOuPath
New-ADOrganizationalUnit -Name "Users" -Path $BaseOuPath
New-ADOrganizationalUnit -Name "Groups" -Path $BaseOuPath

#Import module with function to create users
$ModuleRoot = (Get-Item $PSScriptRoot).parent.fullname
Import-Module "$ModuleRoot\NN.Fagprove\NN.Fagprove\0.0.1\NN.Fagprove.psm1"

#Create all users
$AdminsArr.ForEach({
    New-FpAdUser -DisplayName $_ -UserType "Admin" -Path $AdminsOuPath
})

$UsersArr.ForEach({
    New-FpAdUser -DisplayName $_ -UserType "Standard" -Path $UsersOuPath
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