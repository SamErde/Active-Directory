Import-Module ActiveDirectory

Function Get-UnusedGroups {

[CmdletBinding()]

Param(
    [Parameter(Mandatory = $True)]
    [string]$searchBase
    )

Get-ADGroup -Filter * -Properties members, isCriticalSystemObject -SearchBase $searchBase | Where-Object {
    ($_.members.count -eq 0 `
    -AND !($_.IsCriticalSystemObject) -eq 1 `
    -AND $_.DistinguishedName -notmatch 'Exchange Security' `
    -AND $_.DistinguishedName -notmatch 'Dns' `
    -AND $_.DistinguishedName -notmatch 'gMSA' `
    -AND $_.DistinguishedName -notmatch 'Exchange Install' `
    -AND $_.DistinguishedName -notmatch 'GPO Exception' `
    -AND $_.DistinguishedName -notmatch 'Users' `
    -AND $_.DistinguishedName -notmatch 'Builtin')
}

$searchBase = $null

} #end function Get-UnusedGroups