$userid = Read-Host "P1ease enter a userid for VMs Admin"
$password = Read-host "Please enter a password" | ConvertTo-SecureString -AsplainText -Force
New-AzADUser -DisplayName $userid -UserPrincipalName $userid@smselvan21outlook.onmicrosoft.com -Password $password -MailNickname "MyUser1"
New-AzRoleAssignment -SignInName $userid@smselvan21outlook.onmicrosoft.com `
-RoleDefinitionName "Virtual Machine Contributor" `
-Scope "/subscriptions/655d0f90-8754-4202-bbf3-5270b47e7a55"