<#

    Use at your own risk. This isn't production ready, but feel free to use bits of it to accomplish something similar.
    This is at best "organized snippets" and got a job done for me, but won't scale well yet in a large forest.

#>

break


Import-Module ActiveDirectory

# Create an array of the 15 extensionAttribute names
$extensionAttributes = (1..15) | ForEach-Object { "extensionAttribute$_" }

# Get all users and all extensionAttributes using one of these two lines:
$Users = Get-ADUser -Filter * -Properties $extensionAttributes
$Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties extensionattribute1,extensionattribute2,extensionattribute3,extensionattribute4,extensionattribute5,extensionattribute6,extensionattribute7,extensionattribute8,extensionattribute9,extensionattribute10,extensionattribute11,extensionattribute12,extensionattribute13,extensionattribute14,extensionattribute15

# Get the count of users with extensionAttribute1 populated
(($Users | Group-Object extensionAttribute1).Group).Count
# Clear the first 100 users' extensionAttribute1
($Users | Group-Object extensionAttribute1).Group | Select-Object -First 100 | Set-ADUser -Clear "extensionAttribute1"

# Will be slow in large environments!
$Users = Get-ADUser -Filter * -Properties $extensionAttributes



# List the extensionAttribute names and then get each user that uses each of the attribute names
$StartTime = Get-Date
Write-Host "Start Time: $StartTime" -ForegroundColor Yellow -BackgroundColor Black
if (Get-Variable -Name Results -ErrorAction SilentlyContinue) { Remove-Variable -Name Results -ErrorAction SilentlyContinue }
$extensionAttributes = 1..15 | ForEach-Object { "extensionAttribute$_"}
foreach ($attribute in $extensionAttributes) {
    $attributeValue = Get-ADUser -Filter "Enabled -eq `$true -and $attribute -like `"*`"" -Properties $attribute
    Write-Output "${attribute}: $($attributeValue.Count)"
    $Results += [PSCustomObject]@{
        Attribute = $attribute
        UsedBy = $attributeValue.Count
    }
}
$Results
$EndTime = Get-Date
Write-Host "End Time: $EndTime" -ForegroundColor Yellow -BackgroundColor Black



# Get all users and all extensionAttributes, then create a group for each extensionAttribute to find out how many times each one is used.
$StartTime = Get-Date
Write-Host "Start Time: $StartTime" -ForegroundColor Yellow -BackgroundColor Black
$Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties extensionattribute1,extensionattribute2,extensionattribute3,extensionattribute4,extensionattribute5,extensionattribute6,extensionattribute7,extensionattribute8,extensionattribute9,extensionattribute10,extensionattribute11,extensionattribute12,extensionattribute13,extensionattribute14,extensionattribute15
(1..15) | ForEach-Object { 
    $ext = $Users | Group-Object "extensionAttribute$_" -NoElement | Where-Object {$_.Name }
    if ($ext.Count -gt 0) {
        Write-Host -ForegroundColor Yellow "extensionAttribute$_ has values on $($ext.Count) accounts and should be reviewed." 
    }
    else {
        Write-Host -ForegroundColor Green "extensionAttribute$_ is not used on any user objects."
    }
}
$EndTime = Get-Date
Write-Host "End Time: $EndTime" -ForegroundColor Yellow -BackgroundColor Black
