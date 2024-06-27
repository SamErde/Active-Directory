function Rename-GpoSecurityGroups {
    <#
        .SYNOPSIS
        Rename the security groups used for filtering GPOs.

        .DESCRIPTION
        Check the security filtering groups that are applied to group policy objects and rename them to align with the
        GPO name. This only performs the rename for groups that begin with the string "GPO".

        .PARAMETER GPO
        Name of the GPO to check for security filtering groups.

        .PARAMETER IgnoreWords
        Ignore security groups that have these words anywhere in their name. Not case-sensitive.

        .PARAMETER RequiredPrefix
        Only rename security groups that already begin with a specific prefix (eg: "GPO."). Not case-sensitive.

        .PARAMETER ReportOnly
        Only create a report of what would be renamed.

        .PARAMETER LogFile
        Path and filename to save logs in.

        .EXAMPLE
        Rename-GPOSecurityGroups -RequiredPrefix "GPO." -IgnoreWords "Phase"

        Run the script; only rename security groups that already begin with the string "GPO."
        and ignore any security groups that contain the word "Phase".

        .EXAMPLE
        Rename-GPOSecurityGroups -IgnoreWords @("Phase","AlsoIgnoreThis","And Ignore This")

        Run the script and ignore any security groups that contain the any of the words in an array of words.

        .NOTES
        Author: Sam Erde
        Version: 0.1.0
        Modified: 2024-06-27

        [x] Rename if they begin with "GPO*"
        [x] Log without renaming if the group name does not begin with "GPO*"
    #>

    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param (
        # Name of the GPO to find and rename groups for.
        [Parameter(Position = 0)]
        $GPO,

        # Only rename security groups that already begin with a specific prefix.
        [Parameter()]
        [string]
        $RequiredPrefix = 'GPO',

        # Skip GPOs that have these words anywhere in their name:
        [Parameter()]
        [System.Collections.Generic.List[string]]
        $IgnoreWords = @(),

        # Switch to run in "report-only" mode.
        [Parameter()]
        [switch]
        $ReportOnly,

        # Log path and filename. A default name will be generated if none is provided.
        [Parameter()]
        [string]
        $LogFile
    )

    begin {
        # Initialize the list of strings include for ignoring group names:
        [System.Collections.Generic.List[string]]$DefaultIgnoreWords = @(
            'Authenticated Users','Domain Computers','Domain Controllers'
        )
        Write-Output "Ignoring by default: $($DefaultIgnoreWords -join ', ')."
        if ($IgnoreWords) {
            Write-Output "Ignoring group names that include: $($IgnoreWords -join ', ')."
        }
        $IgnoreWords.AddRange($DefaultIgnoreWords)

        # Get the GPO so we can check its security filtering groups:
        if ($GPO) {
            Write-Verbose "Checking GPO named: $GPO"
            $GPOs = Get-Gpo $GPO
        } else {
            Write-Verbose "Checking all GPOs."
            $GPOs = Get-GPO -All
        }

        Write-Verbose "Inspecting $($GPOs.Count) GPOs."
    }

    process {

        # Loop through all GPOs to inspect ACEs with the GpoApply permission.
        foreach ($gpo in $GPOs) {
            [array]$GpoApply = $gpo | Get-GPPermission -All -TargetType Group | Where-Object {
                    $_.Permission -eq 'GpoApply' -and
                    $_.Trustee.SidType -eq 'Group'
                }
            # Check the group names if any are found with GpoApply permission.
            if ($GpoApply) {

                foreach ($ace in $GpoApply) {

                    # Ignore any group names that include words from the IgnoreWords list.
                    if ( $null -eq ($IgnoreWords | Where-Object { $($GpoApply.Trustee.Name) -match $_ }) ) {

                        $GpoName = $gpo.DisplayName
                        $GroupName = $ace.Trustee.Name

                        if ($GroupName -eq "GPO.$GpoName") {
                            # The group name matches the GPO name.
                        } else {
                            Write-Host "The group name does not match the GPO name:" -ForegroundColor Yellow -BackgroundColor Black
                            Write-Host "$($gpo.DisplayName)" -NoNewline
                            Write-Host "`t $($GpoApply.Trustee.Name)`n"
                            $Group = Get-ADGroup $GroupName
                            $NewGroupName = "GPO.$GpoName"
                            Set-ADGroup -WhatIf -Identity $Group -DisplayName $NewGroupName -SamAccountName $NewGroupName
                        }

                    } # end if no IgnoreWords in name
                } #end foreach ace

            } else {
                Continue
            } #end if GpoApply
        } # end foreach gpo

    } # end process block

    end {
        
    } # end end block
} # end function
