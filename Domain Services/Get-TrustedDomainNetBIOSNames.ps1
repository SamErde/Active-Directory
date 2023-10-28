Import-Module ActiveDirectory
[Array] $ADDomainTrusts = (Get-ADObject -Filter {ObjectClass -eq "trustedDomain"}).Name
[Array]$NetBIOSDomainNames = @()

foreach ($trust in $ADDomainTrusts)
{
    $trustedDNSDomainName = $trust
    $NetBIOSDomainNames += ((Get-ADDomain $trustedDNSDomainName | Select-Object NetBIOSName)| Out-String).Trim()
}

$NetBIOSDomainNames


# http://blogs.metcorpconsulting.com/tech/?p=313

<# ***** OR *****
$TrustedDomains = @{}           
$TrustedDomains += Get-ADObject -Filter {ObjectClass -eq "trustedDomain"} -Properties * |
    Select @{ Name = 'NetBIOSName'; Expr = { $_.FlatName } },
           @{ Name = 'DNSName'; Expr = { $_.Name } },
$TrustedDomains

#Foreach ($Domain in $TrustedDomains) 
{
    
    @{ Name = 'Server'; Expr = { (Get-ADDomainController -Discover -ForceDiscover -Writable -Service ADWS -DomainName $_.Name).Hostname[0] } }
}
#>