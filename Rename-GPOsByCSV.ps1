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
        
        .PARAMETER LogFile
        Path and filename to save logs in.

        .EXAMPLE
        Rename-GPOsByCSV -GpoCsvPath 'C:\Path\To\GPO Renaming List.csv' -BatchSize 25 -Delay 1800

        Renames the GPOs listed in the CSV file 'C:\Path\To\GPO Renaming List.csv' in batches of 25
        with a delay of 1800 seconds (30 minutes) between each batch.
    #>

    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$GpoCsvPath,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 25,

        [Parameter(Mandatory = $false)]
        $Delay = (New-TimeSpan -Minutes 15).TotalSeconds,

        # Log path and filename. A default name will be generated if none is provided.
        [Parameter()]
        [string]
        $LogFile
    )

    begin {
        $StartTime = Get-Date

        # Generate a log file name if one was not specified in the parameters.
        if ( -not $PSBoundParameters.ContainsKey($LogFile) ) {
            $LogFile = "Renaming GPOs from CSV {0}.txt" -f ($StartTime.ToString("yyyy-MM-dd HH_mm_ss"))
        }

        # Start the log string builder.
        $LogStringBuilder = [System.Text.StringBuilder]::New()

        Write-Log "Renaming Group Policy Objects from a CSV"
        Write-Log $StartTime

        Import-Module GroupPolicy
    }

    process {

        try {
            # Import the list of GPOs to rename from a CSV file that contains values in two columns: OldName and NewName
            $GPOs = Import-Csv -Path $GpoCsvPath | Where-Object { $null -ne $_.OldName -and $null -ne $_.NewName }
            $GpoCount = $GPOs.Count
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

    end {
        # Write the log file
        $FinishTime = Get-Date
        Write-Log "`n`nFinished processing $GpoCount GPOs at $FinishTime.`n"
        try {
            $LogStringBuilder.ToString() | Out-File -FilePath $LogFile -Encoding utf8 -Force
            Write-Output "The log file has been written to $LogFile."
        } catch {
            Write-Warning -Message "Unable to write to the logfile `'$LogFile`'."
            $_
        }
    } # end end block

} # end function Rename-GPOsByCsv

function Write-Log {
    # Write a string of text to the host and a log file simultaneously.
    [CmdletBinding()]
    [OutputType([string])]
        param (
            # The message to display and write to a log
            [Parameter(Mandatory)]
            [string]
            $LogText,

            # Type of output to send
            [Parameter()]
            [ValidateSet('Both','HostOnly','LogOnly')]
            [string]
            $Output = 'Both'
        )

        switch ($Output) {
            Both {
                Write-Host "$LogText"
                [void]$LogStringBuilder.AppendLine($LogText)
            }
            HostOnly {
                Write-Host "$LogText"
            }
            LogOnly {
                [void]$LogStringBuilder.AppendLine($LogText)
            }
        }
} # end function Write-Log
