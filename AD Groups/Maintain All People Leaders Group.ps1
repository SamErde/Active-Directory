<# 
 .Synopsis
  Create and maintain an Active Directory group with all people leaders.
 .Description
  This PowerShell script will help create and maintain an AD group that contains all of an organization's "people 
  leaders." It is based on querying all Active Directory user objects that have a value in their DirectReports 
  property and then filtering that group by actual leadership/managerial titles. Thoe list of titles can be 
  customized to suit an organization's unique titles.
 .PARAMETER GridView
    To-Do: Add a parameter to present the output in a grid view control.
.EXAMPLE
   .\PeopleLeaders.ps1 -GridView
   To-Do: Output results of the script to a grid view control.
.EXAMPLE
   .\PeopleLeaders.ps1 -Create -GroupName "All People Leaders"
   To Do: Add a parameter and function to create the new group.
#>

#region Variables

    # Set preferred log file path
    $LogFilePath = "C:\Scripts\Logs\PeopleLeadersGroup.log"

    # Specify name of pre-existing group here.
    $PeopleLeadersGroup = "All People Leaders"

#endregion Variables

function Write-Log {
# Used within the script to write details to a log file.
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false)]
        [Switch]$NoTimeStamp = $false,
        [Parameter(Mandatory=$false)]
        [String]$Log,
        [Parameter(Mandatory=$false)]
        [Switch]$Header
    )

    if (($NoTimeStamp -eq $true) -and ($Log)) {
        $Log | Out-File $LogFilePath -Append
    }
    elseif (($NoTimeStamp -eq $false) -and ($Log)) {
        $TimeStamp = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'
        "`n$TimeStamp `t $Log" | Out-File $LogFilePath -Append
    }

    if ($Header) {
        "----------------------------"          | Out-File $LogFilePath -Append
        "Running PeopleLeaders Script"          | Out-File $LogFilePath -Append
        Get-Date -Format 'yyyy-MM-dd hh:mm:ss'  | Out-File $LogFilePath -Append
        "----------------------------"          | Out-File $LogFilePath -Append
    }

    if (!($Log)) {
        Write-Verbose "No log output was provided."
        Write-Debug "No log output was provided."
    }
}

#region Start
Write-Log -Header
Import-Module ActiveDirectory
#endregion Start

function Update-PeopleLeadersGroup {
    [CmdletBinding()]
    param
    ()

    # Create lists of managerial titles to include in the search and titles to exclude from the search.
    $TitlesToInclude = @("Chief","President","Director","Manager","Supervisor")
    $TitlesToExclude = @("Network Relationship Manager","Project Manager","Care Manager","Case Manager")

    # Make valid regex strings with escape characters where needed in the inclusion and exclusion strings.
    $RegExInclude = ( ($TitlesToInclude | ForEach-Object {[regex]::Escape($_)}) -join "|" )
    $RegExExclude = ( ($TitlesToExclude | ForEach-Object {[regex]::Escape($_)}) -join "|" )

    # Find all enabled users in Active Directory that have direct reports
    # where their title is in the TitlesToInclude list and not in the TitlesToExclude list.
    $PeopleLeaders = ( Get-ADUser -Properties Title,DirectReports -Filter { Enabled -eq "True" -and DirectReports -like "*" }
        ).Where({ $_.Title -match $RegExInclude -and $_.Title -notmatch $RegExExclude })
    Write-Log -Log "$($PeopleLeaders.Count) people leaders found."

    # Add any missing group members
    $GroupMembers = Get-ADGroupMember -Identity "All People Leaders"
    if ($GroupMembers) {
        $AddTogroup = (Compare-Object -ReferenceObject $GroupMembers -DifferenceObject $PeopleLeaders).InputObject
    }
    else {
        $AddTogroup = $PeopleLeaders
    }

    # Add new people leaders to the relevant Active Directory group
    if ($AddToGroup) {
        Write-Log "$($AddToGroup.Count) new people leaders found."
        try {
            Get-ADGroup -Identity $PeopleLeadersGroup | Add-ADGroupMember -Members $AddToGroup
            Write-Log "$($PeopleLeaders.Count) people leaders added to `"$PeopleLeadersGroup`"."
        }
        catch {
            Write-Log "A problem occured while adding users to `"$PeopleLeadersGroup`"."
        }
    }
    else {
        Write-Log "No new people leaders found."
    }

    # Remove group members who are no longer people leaders:
    # Get current members of the "All People Leaders" group.
    $GroupMembers = Get-ADGroupMember -Identity "All People Leaders"
    # Compare current members of the group with the freshly queried PeopleLeaders array.
    $RemoveFromGroup = (Compare-Object -ReferenceObject $PeopleLeaders -DifferenceObject $GroupMembers).InputObject
    # If any users exist in $RemoveFromGroup, run the Remove-ADGroupMember cdmlet to clean up.
    if ($RemoveFromGroup) {
        Remove-ADGroupMember -Identity "All People Leaders" -Members $RemoveFromGroup -Confirm$False
        Write-Log "$($RemoveFromGroup.Count) users removed from `"$PeopleLeadersGroup`": "
        $RemoveFromGroup | Sort-Object Name,Title | Format-Table @{Name='Action';Expression={"Removed"}},Name,Title | 
            Out-File -FilePath $LogFilePath -Append
    }
    else {
        Write-Log "0 users removed from `"$PeopleLeadersGroup`"."
    }
    Write-Log -Log "-----------------"
    Write-Log -Log "Script Completed."
} # End function

Update-PeopleLeadersGroup