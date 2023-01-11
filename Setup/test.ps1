function New-AdStructure {
    param (
        [Parameter(Mandatory)][xml]$Node,
        [string]$Path
    )

    $DomainRoot = (Get-ADDomain).DistinguishedName
    if ($Node.OU) {
        New-ADOrganizationalUnit -Path $DomainRoot -Name $Node.OU.Name
    } elseif ($Node.Group) {

    }

    if ($Node.object) {
        New-AdStructure -Node $Node.object -Path ($Path + <#todo: Insert AD DN path of OU #>)
    }
}

[xml]$xml = Get-Content -Raw "$PSScriptRoot\AD-structure.xml"