Connect-AzAccount -TenantId "103f56da-bf53-4bd6-8e7c-49a7a9f7f20a"

$rg1 = "searg"
$loc = "Southeast Asia"
$vm1 = "webvm-1"
$rsv1 = "webrsv"

Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"

New-AzRecoveryServicesVault `
    -ResourceGroupName $rg1 `
    -Name $rsv1 `
	-Location $loc

Get-AzRecoveryServicesVault `
    -Name $rsv1 | Set-AzRecoveryServicesVaultContext

Get-AzRecoveryServicesVault `
    -Name $rsv1 | Set-AzRecoveryServicesBackupProperty -BackupStorageRedundancy LocallyRedundant

$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy"

Enable-AzRecoveryServicesBackupProtection `
    -ResourceGroupName $rg1 `
    -Name $vm1 `
    -Policy $policy

$namedContainer = Get-AzRecoveryServicesBackupContainer `
    -ContainerType "AzureVM" `
    -FriendlyName $vm1

$bkpItem = Get-AzRecoveryServicesBackupItem `
    -Container $namedContainer `
    -WorkloadType "AzureVM"

Backup-AzRecoveryServicesBackupItem -Item $bkpItem

Get-AzRecoveryservicesBackupJob