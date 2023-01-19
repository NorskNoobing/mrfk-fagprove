param (
    $HashtableArr = @(
        #Set static IP for fileserver
        @{
            "Hostname" = "SR-WINSRV19-002"
            "ScopeName" = "Server"
            "IPAddress" = "10.0.10.5"
        },
        #Set static IP for printserver
        @{
            "Hostname" = "SR-WINSRV19-003"
            "ScopeName" = "Server"
            "IPAddress" = "10.0.10.15"
        }
    )
)

$HashtableArr.ForEach({
    $ScopeId = $DHCPLease = $null

    $Params = $_
    $ScopeId = (Get-DhcpServerv4Scope).where({$_.Name -eq $Params.ScopeName}).ScopeId
    $DHCPLease = (Get-DhcpServerv4Lease $ScopeId).where({$_.HostName -like "$($Params.Hostname)*"})
    Add-DhcpServerv4Reservation -ScopeId $ScopeId -Name $DHCPLease.Hostname -IPAddress $Params.IPAddress -ClientId $DHCPLease.ClientId
})

