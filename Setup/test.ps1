#Import module with function to create users
$RepoRoot = (Get-Item $PSScriptRoot).parent.fullname
Import-Module "$RepoRoot\NN.Fagprove\NN.Fagprove\0.0.1\NN.Fagprove.psm1"

[xml]$xml = Get-Content -Raw "$PSScriptRoot\AD-structure.xml"
$DomainRoot = (Get-ADDomain).DistinguishedName
New-AdStructure -Node $xml.object -Path $DomainRoot