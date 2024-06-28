function Rename-GroupsByCsv {
    [CmdletBinding()]
    param (
        # The CSV file containing a list of groups. Required columns: GroupName,NewGroupName. Optional column: GPO.
        [Parameter(Mandatory, Position = 0)]
        [string]
        $CsvFile
    )
    
    begin {
        $GroupsCsv = Import-Csv -Path $CsvFile
    }
    
    process {
        foreach ($group in $GroupsCsv) {
            try {
                $OldName = $group.GroupName
                $NewName = $group.NewGroupName
                Get-ADGroup $OldName | Set-ADGroup -SamAccountName $NewName -DisplayName $NewName -WhatIf
                Write-Output "$OldName has been renamed to $($Group.NewName)"
            } catch {
                Write-Output "Error: $_"
            }
        }
    }
    
    end {
        
    }
}
