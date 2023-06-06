#!/usr/bin/env -S powershell.exe -ExecutionPolicy Bypass

# I use SPO Admin a lot, change it to your desired role
$roleToActivate = "Global Administrator" 
$hours = 1
$reason = "Creating CUBE Environment"
$connection = Connect-AzureAD -AzureEnvironmentName AzureUSGovernment
$account = $connection.Account
$tenantId = $connection.TenantId
$user = Get-AzureADUser -SearchString $account
$objectId = $user.ObjectId
$roleDefs = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId

$roleDefinition = $roleDefs | Where-Object { $_.DisplayName -eq $roleToActivate }
$roleDefinitionId = $roleDefinition.Id
$filter = "(subjectId eq '$objectId') and (roleDefinitionId eq '$roleDefinitionId')"
$assignment = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantId -Filter $filter

if (!$assignment) {
    Write-Error "There is no assignment for you as $roleToActivate"
} elseif ($assignment.AssignmentState -eq "Active") {
    "Your role assignment as a $roleToActivate is already Active"
} else { 
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $now = (Get-Date).ToUniversalTime()
    $schedule.StartDateTime = $now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.EndDateTime = $now.AddHours($hours).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    Open-AzureADMSPrivilegedRoleAssignmentRequest `
      -ProviderId 'aadRoles' `
      -ResourceId $tenantId `
      -RoleDefinitionId $roleDefinitionId `
      -SubjectId $objectId `
      -Type 'UserAdd' `
      -AssignmentState 'Active' `
      -Schedule $schedule -Reason $reason
    "Your assignment as $roleToActivate is now active" 
}
