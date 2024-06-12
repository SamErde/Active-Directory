function Rename-GPOsByCSV {
    <#
        .SYNOPSIS
        Renames a list of Group Policy Objects (GPOs) based on a CSV file.

        .DESCRIPTION
        This function renames a list of Group Policy Objects (GPOs) based on a CSV file
        that contains values in two columns: OldName and NewName.

        .PARAMETER GpoCsvPath
        The path to the CSV file that contains the list of GPOs to rename.

        .PARAMETER BatchSize
        The number of GPOs to rename in each batch. The default value is 20.
        Batching is used to avoid replication congestion with many changes.

        .PARAMETER Delay
        The number of seconds to wait between batches. The default value is 900 seconds (15 minutes).

        .EXAMPLE
        Rename-GPOsByCSV -GpoCsvPath 'C:\Path\To\GPO Renaming List.csv' -BatchSize 25 -Delay 1800

        Renames the GPOs listed in the CSV file 'C:\Path\To\GPO Renaming List.csv' in batches of 25
        with a delay of 1800 seconds (30 minutes) between each batch.

        .NOTES
        [ ] Add logging
        [ ] Automatically rename security filtering groups applied to affected GPOs
            [ ] Rename if they begin with "GPO*"
            [ ] Log without renaming if the group name does not begin with "GPO*"
            [ ] Ignore groups with "Phase" in the name
    #>


    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$GpoCsvPath,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 25,

        [Parameter(Mandatory = $false)]
        $Delay = (New-TimeSpan -Minutes 15).TotalSeconds
    )

    Import-Module GroupPolicy

    try {
        # Import the list of GPOs to rename from a CSV file that contains values in two columns: OldName and NewName
        $GPOs = Import-Csv -Path $GpoCsvPath | Where-Object { $null -ne $_.OldName -and $null -ne $_.NewName }
    } catch {
        Write-Host "Failed to import the GPO renaming list: $_"
        return
    }

    # Loop through the GPOs in batches
    for ($i = 0; $i -lt $GPOs.Count; $i += $BatchSize) {
        # Get the current batch of GPOs
        $Batch = $GPOs[$i..($i + $BatchSize - 1)]

        # Rename each GPO in the batch
        foreach ($gpo in $Batch) {
            try {
                # Get the old GPO and rename it:
                $OldGpo = (Get-GPO -Name $gpo.OldName).DisplayName

                # Check if -WhatIf parameter is specified
                if ($PSCmdlet.ShouldProcess("Rename GPO '$($gpo.OldName)' to '$($gpo.NewName)'")) {
                    # Rename the GPO and suppress the host output
                    Rename-GPO -Name $OldGpo -TargetName $gpo.NewName | Out-Null
                    Write-Output "[Rename-GPOsByCSV] $(Get-Date) [Success] Renamed GPO '$($gpo.OldName)' to '$($gpo.NewName)'."
                }
            }
            catch {
                Write-Host "[Rename-GPOsByCSV] $(Get-Date) [Error] Failed to rename GPO '$($gpo.OldName)': $_"
            }
        }

        # Pause between batches to avoid overloading domain controller replication.
        if ($i + $BatchSize -lt $GPOs.Count) {
            Start-Sleep -Seconds $Delay
        }
    }
}
