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
            $OUs = Get-ADOrganizationalUnit $OrganizationalUnit
        } else {
            $OUs = Get-ADOrganizationalUnit -Filter *
        }

        <# Get the Deepest OUs:
            This script block pipes the full list of OUs to a Group-Object command...
            They are grouped by a script block that counts the number of commas in the DistinguishedName...
            We subtract one because the domain root doesn't count as a level...
            The results of Group-Object contain the OU depth in the group 'Name' column, 
            and the Group column contains the OUs at that depth...
            Sorting by group Name and selecting the last 1 gives us the group with the highest number (deepest OUs)...
            The Tee-Object cmdlet cmdlet saves the depth for future reference...
            and the final Select-Object statement pulls the OU objects from that grouped object.            
        #>
        if ($Deepest) {
            $DeepestOUs = $OUs | Group-Object { ([regex]::Matches($_.DistinguishedName,',')).Count -1 } |
                Sort-Object Name | Select-Object -Last 1 | Tee-Object -Variable DepthGroup | Select-Object -ExpandProperty Group
            $DeepestDepth = $DepthGroup.Name

            # Create an OutputMessage that can be used for host output, logging, or reporting.
            $OutputMessage = "The deepest OUs are $DeepestDepth levels deep:`n`n$(($DeepestOUs.DistinguishedName) -join("`n"))"
            # Send the deepest OUs to the pipeline.
            $Output = $DeepestOUs
        }
    }
    
    end {
        Write-Information -MessageData $OutputMessage -InformationAction Continue
        $Output
    }
}
