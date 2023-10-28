Import-Module ActiveDirectory
Get-AdGroupMember “SourceGroupA-sAMAccountName” | %{Add-ADGroupMember –Identity “DestinationGroupB-sAMAccountName” –Members $_}