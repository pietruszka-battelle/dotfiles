#!/usr/bin/env -S powershell.exe -ExecutionPolicy Bypass

param(
    [Parameter()]
    [string]$aadRole,

    [Parameter()]
    [string]$aadGroup
)
$connection = Connect-AzureAD -AzureEnvironmentName AzureUSGovernment
$reason = "Creating CUBE Environment"
$account = $connection.Account

if (!$aadRole.Length -eq 0) {
    Write-Host "Activating aadRole $aadRole"
    $hours_aadRole = 1
    $tenantId = $connection.TenantId
    $user = Get-AzureADUser -Filter "userPrincipalName eq '$($account.id)'"
    $objectId = $user.ObjectId
    $roleDefs = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId

    $roleDefinition = $roleDefs | Where-Object { $_.DisplayName -eq "$aadRole" }
    $roleDefinitionId = $roleDefinition.Id
    $filter = "(subjectId eq '$objectId') and (roleDefinitionId eq '$roleDefinitionId')"
    $assignment = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $tenantId -Filter $filter

    if (!$assignment) {
        Write-Error "There is no assignment for you as $aadRole"
    } elseif ($assignment.AssignmentState -eq "Active") {
        "Your role assignment as a $aadRole is already Active"
    } else {
        $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
        $schedule.Type = "Once"
        $now = (Get-Date).ToUniversalTime()
        $schedule.StartDateTime = $now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $schedule.EndDateTime = $now.AddHours($hours_aadRole).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        Open-AzureADMSPrivilegedRoleAssignmentRequest `
            -ProviderId 'aadRoles' `
            -ResourceId $tenantId `
            -RoleDefinitionId $roleDefinitionId `
            -SubjectId $objectId `
            -Type 'UserAdd' `
            -AssignmentState 'Active' `
            -Schedule $schedule -Reason $reason
        "Your assignment as $aadRole is now active"
    }
}

if (!$aadGroup.Length -eq 0) {
    Write-Host "Activating aadGroup $aadGroup"
    $resource = Get-AzureADMSPrivilegedResource -ProviderId aadGroups
    $user = Get-AzureADUser -Filter "userPrincipalName eq '$($account.id)'"
    $groupId = (Get-AzureADGroup -SearchString $aadGroup).ObjectId
    $roleDefinitionCollection = Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadGroups" -ResourceId $groupId

    foreach ($roleDefinition in $roleDefinitionCollection) {
        if ($roleDefinition.DisplayName -eq "Member") {
            $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
            $schedule.Type = "Once"
            $schedule.Duration="PT12H"
            $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            Open-AzureADMSPrivilegedRoleAssignmentRequest `
                -ProviderId "aadGroups" `
                -Schedule $schedule `
                -ResourceId $groupId `
                -RoleDefinitionId $roleDefinition.id `
                -SubjectId $user.ObjectId `
                -AssignmentState "Active" `
                -Type "UserAdd" `
                -Reason $reason
        "Your assignment as $aadGroup is now active"
        }
    }
}
