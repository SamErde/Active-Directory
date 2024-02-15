function Get-OUDetails {
<#
.SYNOPSIS
    Get advanced details about an organizational unit (OU) in Active Directory.
.DESCRIPTION
    THIS IS STILL A CONCEPT WORK IN PROGRESS
#>
    Import-Module ActiveDirectory

    $OUs = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName, gPOptions, isCriticalSystemObject, showInAdvancedViewOnly | Sort-Object CanonicalName
    foreach ($OU in $OUs) {

        $CriticalLocation = if ($OU.isCriticalSystemObject) { $true } else { $false }
        $HiddenOU = if ($OU.showInAdvancedViewOnly) { $true } else { $false }

        [array]$OUDetails += [PSCustomObject]@{
            Name                    = $OU.Name
            DistinguishedName       = $OU.DistinguishedName
            CanonicalName           = $OU.CanonicalName
            Parent                  = Get-ParentOU $OU
            Child                   = Get-ChildOU $OU
            BlockInheritance        = Test-BlockInheritence $OU
            CriticalLocation        = $CriticalLocation
            ShowInAdvancedViewOnly  = $HiddenOU
        }
    }

    # Return the OUFamily array as the result of this function
    $OUDetails
}

function Get-ParentOU {
    # Get the parent organizational unit of an OU in Active Directory
    [CmdletBinding()]
    param (
        [Parameter()]
        $OrganizationalUnit
    )
    $DN = $OrganizationalUnit.DistinguishedName
    $ParentDN = ($DN.Replace("OU=$($OrganizationalUnit.Name),",''))

    if ($ParentDN -notlike "DC=*") {
        $ParentOU = Get-ADOrganizationalUnit -Identity "$ParentDN" -Properties CanonicalName
    } else {
        $ParentOU = $null
    }

    $ParentOU
}

function Get-ChildOU {
    # List the child OUs for an organizational unit in Active Directory
    [CmdletBinding()]
    param (
        [Parameter()]
        $OrganizationalUnit
    )
    $DN = $OrganizationalUnit.DistinguishedName
    $ChildOU = [array](Get-ADOrganizationalUnit -Filter * -SearchBase $DN -SearchScope OneLevel -Properties CanonicalName)

    $ChildOU
}

function Test-BlockInheritence {
    # Check if Block Inheritence is set on an organizational unit in Active Directory
    [CmdletBinding()]
    param (
        [Parameter()]
        $OrganizationalUnit
    )

    if ($OU.gPOptions -eq 1) {
        $true
    } else {
        $false
    }
}
