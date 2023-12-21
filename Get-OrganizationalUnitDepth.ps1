function Get-OrganizationalUnitDepth {
    [CmdletBinding()]
    [Alias("Get-OUDepth")]
    param (
        [parameter(ValueFromPipeline)]
        $OrganizationalUnit,

        [parameter()]
            [switch]$Deepest
    )
    
    begin {
        Import-Module ActiveDirectory
    }
    
    process {
        # Get the specified OU or get all OUs if none is specified.
        if ($OrganizationalUnit) {
            $OUs = Get-ADOrganizationalUnit $OrganizationalUnit -Properties CanonicalName
        } else {
            $OUs = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName
        }

        <# Get the Deepest OUs:
            This script block pipes the full list of OUs to a Group-Object command...
            They are grouped by a script block that counts the number of forward slashes in the CanonicalName...
            The results of Group-Object contain the OU depth in the group 'Name' column, which we rename to "Depth"...
            and the Group column contains the OUs at that depth...
            Sorting by group Depth and selecting the last 1 gives us the group with the highest number (deepest OUs)...
            The Tee-Object cmdlet cmdlet saves the depth for future reference...
            and the final Select-Object statement pulls the OU objects from that grouped object.            
        #>
        if ($Deepest) {
            # The downside to counting by commas in the DistinguishedName is you need to account for an unknown of DC segments in the domain name.
            $DeepestOUs = $OUs | Group-Object { ([regex]::Matches($_.CanonicalName,'/')).Count } | Select-Object Count,@{Name="Depth"; Expression = {$_.Name}},Group |
                Sort-Object Depth | Select-Object -Last 1 | Tee-Object -Variable DeepestGroup | Select-Object -ExpandProperty Group
            $DeepestDepth = $DeepestGroup.Depth

            # Create an OutputMessage that can be used for host output, logging, or reporting.
            $OutputMessage = "The deepest OUs are $DeepestDepth levels deep:`n`n$(($DeepestOUs.CanonicalName) -join("`n"))"
            # Send the deepest OUs to the pipeline.
            $Output = $DeepestOUs
        }
    }
    
    end {
        Write-Information -MessageData $OutputMessage -InformationAction Continue
        $Output
    }
}
