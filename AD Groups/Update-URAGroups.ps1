Import-Module ActiveDirectory

$uraTable =@{
    "BatchJobLogon"="SeBatchLogonRight";
    "ReplaceProcessLevelToken"="SeAssignPrimaryTokenPrivilege";
    "ServiceLogon"="SeServiceLogonRight"
}

$uraGroups = Get-ADGroup -Filter {Name -like '*- service*'} -SearchBase "OU=Server User Rights,OU=Security Groups,dc=domain,dc=com"
foreach ($group in $uraGroups) {
    [string]$serverName = $group.Name.Replace(" ","").Split("-")[0]
    [string]$uraName = $group.Name.Replace(" ","").Split("-")[1]
    
    if ($uraTable.ContainsKey("$uraName")) {
        $newGroup = $serverName + " - " + $uraTable.$uraName
        Write-Output ($group.Name + " will be copied to " + $newGroup).Replace("`n","")

        try { New-ADGroup -Name $newGroup -SamAccountName $newGroup -DisplayName $newGroup -GroupCategory Security -GroupScope Global -Path "OU=Server User Rights,OU=Security Groups,dc=domain,dc=com" }
        catch { Write-Warning $_.Exception.Message }
        
        try { Get-AdGroupMember $group | ForEach-Object {Add-ADGroupMember -Identity $newGroup -Members $_} }
        catch { Write-Warning $_.Exception.Message }
    }
}
