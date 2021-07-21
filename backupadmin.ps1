$userid = Read-Host "P1ease enter a userid for BackupAdmin"
$password = Read-Host "Please enter a password" | convertTo-SecureString -AsplainText -Force
New-AzADUser -DisplayName $userid -UserPrincipalName $userid@smselvan21outlook.onmicrosoft.com -Password $password -MailNickname "MyUser2"
New-AzRoleAssignment -SignInName $userid@smselvan21outlook.onmicrosoft.com `
-RoleDefinitionName "Backup Contributor" `
-Scope "/subscriptions/655d0f90-8754-4202-bbf3-5270b47e7a55/resourceGroups/eusrg"