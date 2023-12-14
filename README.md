# Active-Directory
Scripts and tools for Active Directory

## Test-IsProtectedUser

A simple thing that checks if the specified user is a member of the Protected Users group in Active Directory. This can be a helpful way to check if the account will be limited in certain cases when automating other things. (For example, NTLM authentication and credential caching are both disabled for Protected Users.)

Accepts an AD user object from the pipeline or any AD user identifier that works with the `Get-ADUser` cmdlet. The function returns either `$true` or `$false`.
