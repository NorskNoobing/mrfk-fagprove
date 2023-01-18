param (
    $hostname = "SR-PFSENSE-001",
    $DC_IP = "10.0.10.10",
    $SMB_IP = "10.0.10.5"
)

#Install required modules
$RequiredModulesNameArray = @('NN.pfSense')
$RequiredModulesNameArray.ForEach({
    if (Get-InstalledModule $_ -ErrorAction SilentlyContinue) {
        Import-Module $_ -Force
    } else {
        Install-Module $_ -Force -Repository PSGallery
    }
})

#SkipCertificateCheck
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12

#Change pfSense hostname
Update-PfHostname -domain ((Get-ADDomain).forest) -hostname $hostname

#Update interfaces
Update-PfInterface -id "hn1" -ipaddr "10.0.10.1" -subnet "24" -descr "Server" -type "staticv4" -enable "true"
Update-PfInterface -id "hn2" -ipaddr "10.0.20.1" -subnet "23" -descr "Client" -type "staticv4" -enable "true"
Update-PfInterface -id "hn3" -ipaddr "10.0.30.1" -subnet "24" -descr "Print" -type "staticv4" -enable "true"

#Apply interface changes
Invoke-PfInterfaceApply

#Add firewall aliases
$splat = @{
    "name" = "RFC1918"
    "descr" = "Private network IPs"
    "type" = "network"
    "address" = @("10.0.0.0/8","172.16.0.0/12","192.168.0.0/16")
    "detail" = @("Class A","Class B","Class C")
}
New-PfFirewallAlias @splat

$ports = @(
    "389",
    "636",
    "3268",
    "3269",
    "88",
    "53",
    "445",
    "25",
    "135",
    "5722",
    "123",
    "464",
    "138",
    "9389",
    "67",
    "2535",
    "137",
    "139",
    "49152:65535"
)

$detail = @(
    "LDAP",
    "LDAP SSL",
    "LDAP GC",
    "LDAP GC SSL",
    "Kerberos",
    "DNS",
    "SMB,CIFS,SMB2, DFSN, LSARPC, NbtSS, NetLogonR, SamR, SrvSvc",
    "SMTP",
    "RPC, EPM",
    "RPC, DFSR (SYSVOL)",
    "Windows Time",
    "Kerberos change/set password",
    "DFSN, NetLogon, NetBIOS Datagram Service",
    "SOAP",
    "DHCP, MADCAP",
    "DHCP, MADCAP",
    "NetLogon, NetBIOS Name Resolution",
    "DFSN, NetBIOS Session Service, NetLogon",
    "DFSR RPC"
)

$splat = @{
    "name" = "ADDS"
    "descr" = "Active Directory Domain Services"
    "type" = "port"
    "address" = $ports
    "detail" = $detail
}
New-PfFirewallAlias @splat

#Remove all existing firewall rules
(Get-PfFirewallRules).data.tracker.ForEach({
    Remove-PfFirewallRule -tracker $_
})

#Create firewall rules
$splat = @{
    "top" = "true"
    "type" = "pass"
    "interface" = "Server"
    "ipprotocol" = "inet"
    "protocol" = "any"
    "src" = "Server"
    "dst" = "!RFC1918"
    "descr" = "WAN access"
}
New-PfFirewallRule @splat

$splat = @{
    "top" = "true"
    "type" = "pass"
    "interface" = "Client"
    "ipprotocol" = "inet"
    "protocol" = "any"
    "src" = "Client"
    "dst" = "!RFC1918"
    "descr" = "WAN access"
}
New-PfFirewallRule @splat

$splat = @{
    "top" = "true"
    "type" = "pass"
    "interface" = "Client"
    "ipprotocol" = "inet"
    "protocol" = "tcp/udp"
    "src" = "Client"
    "srcport" = "any"
    "dst" = $DC_IP
    "dstport" = "ADDS"
    "descr" = "ADDS services"
}
New-PfFirewallRule @splat

$splat = @{
    "top" = "true"
    "type" = "pass"
    "interface" = "Client"
    "ipprotocol" = "inet"
    "protocol" = "tcp/udp"
    "src" = "Client"
    "srcport" = "any"
    "dst" = $SMB_IP
    "dstport" = "445"
    "descr" = "SMB"
}
New-PfFirewallRule @splat

#Apply firewall rule changes
Invoke-PfFirewallApply

#Change pfSense admin password
Update-PfUser -username admin -password (Read-Host "Please enter a new pfSense password for the user `"admin`"")

pause