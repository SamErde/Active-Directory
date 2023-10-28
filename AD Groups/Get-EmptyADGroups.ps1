Import-Module ActiveDirectory
Get-ADGroup -Filter {GroupCategory -eq 'Security'} -SearchBase "OU=Security Groups,DC=,DC=" -SearchScope Subtree | Where-Object {@(Get-ADGroupMember $_).Length -eq 0} | Select-Object Name
