function Remove-AllADGroupMembership {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$SAMAccountName
    )
    begin {

    }
    process {
        $User = Get-ADUser $SAMAccountName -Properties memberof
        $User.memberof | ForEach-Object {
            Get-ADGroup $_ | Remove-ADGroupMember -Member $SAMAccountName
        }
    }
    end {

    }
}
