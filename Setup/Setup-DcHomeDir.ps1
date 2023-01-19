#Install required modules
$RequiredModulesNameArray = @('NTFSSecurity')
$RequiredModulesNameArray.ForEach({
    if (Get-InstalledModule $_ -ErrorAction SilentlyContinue) {
        Import-Module $_ -Force
    } else {
        Install-Module $_ -Force -Repository PSGallery
    }
})

(Get-ADUser -Filter * -Properties DisplayName).where({
    $_.DistinguishedName -like "*OU=Users,OU=CORP,DC=corp,DC=local"
}).ForEach({
    $HomeDir = "\\SR-WINSRV19-002\Home$\$($_.Name)" 
    $splat = @{
        "Identity" = $_.Name
        "HomeDirectory" = $HomeDir
        "HomeDrive" = "H:"
    }
    Set-ADUser @splat

    New-Item -ItemType "Directory" -Path $HomeDir
    Add-NTFSAccess -Path $HomeDir -Account "CORP\$($_.Name)" -AccessRights "FullControl" -AppliesTo "ThisFolderSubfoldersAndFiles"
})