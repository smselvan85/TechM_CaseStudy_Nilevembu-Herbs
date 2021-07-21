# Creates an new action group receiver object in memory
$receiver = New-AzActionGroupReceiver `
    -Name "Admin" `
    -EmailAddress "smselvan21@outlook.com"

# Creates a new or updates an existing action group.
$actionGroup = Set-AzActionGroup `
    -Name "Admin-Group" `
    -ShortName "ActionGroup" `
    -ResourceGroupName "searg" `
    -Receiver $receiver

# Creates an ActionGroup reference object in memory.
$actionGroupId = New-AzActionGroup -ActionGroupId $actionGroup.Id

# Creates a local criteria object that can be used to create a new metric alert
$condition = New-AzMetricAlertRuleV2Criteria `
    -MetricName "Percentage CPU" `
    -TimeAggregation Average `
    -Operator GreaterThan `
    -Threshold 0.8

    $windowSize = New-TimeSpan -Minutes 5
    $frequency = New-TimeSpan -Minutes 5 
    $targetResourceId = (Get-AzResource -Name webvm-0).ResourceId
    
# Adds or updates a V2 (non-classic) metric-based alert rule.
Add-AzMetricAlertRuleV2 `
    -Name "CPUMetric" `
    -ResourceGroupName "searg" `
    -WindowSize $windowSize `
    -Frequency $frequency `
    -TargetResourceId $targetResourceId `
    -Condition $condition `
    -ActionGroup $actionGroupId `
    -Severity 3

<#
# To Gets metric definitions
$validMetrics = Get-AzMetricDefinition `
    -MetricNamespace "Microsoft.Compute/virtualMachine" `
    -ResourceId $targetResourceId

# Get the values
$validMetrics.Name
#>