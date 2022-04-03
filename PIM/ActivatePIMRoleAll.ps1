$aadTenantID = '' #TenantID
$adminID = '' #UPN
$aadPIMRoleActReason = 'Needed for troubleshooting' #Reason for the role activation
$aadActiveRoleHours = 8 #number of hours that the role will be active

Connect-AzureAD -AccountId $adminID

$adminIDOID = (Get-AzureADUser -SearchString $adminID).ObjectID
write-host
Write-Host "Fetching eligible roles for the user '$($adminID)'..." -ForegroundColor Cyan
$aadAdminEligibleRoles = Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $aadTenantID -Filter "subjectId eq '$($adminIDOID)' and AssignmentState eq 'Eligible'"
write-host
if($aadAdminEligibleRoles.count -eq 1){
    Write-host "Found 1 elegible role:" -ForegroundColor Cyan
}else{
    Write-host "Found $($aadAdminEligibleRoles.count) elegible roles:" -ForegroundColor Cyan
}


foreach($aadER in $aadAdminEligibleRoles){
    $aadPIMRoleOID = $aadER.RoleDefinitionId
    $aadPIMRoleDN = (Get-AzureADMSRoleDefinition -Id $aadPIMRoleOID).DisplayName
    Write-Host "- $($aadPIMRoleDN)" -ForegroundColor Yellow
}

$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule 
$schedule.Type = "Once" 
$schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") 
$schedule.endDateTime = (Get-Date).ToUniversalTime().addHours($aadActiveRoleHours).ToString("yyyy-MM-ddTHH:mm:ss.fffZ") 

foreach($aadEligibleRole in $aadAdminEligibleRoles){
    $aadPIMRoleOID = $aadEligibleRole.RoleDefinitionId
    $aadPIMRoleDisplayName = (Get-AzureADMSRoleDefinition -Id $aadPIMRoleOID).DisplayName
    Write-Host
    Write-Host "Trying to enable role: $($aadPIMRoleDisplayName)..." -ForegroundColor Cyan
    if(Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $aadTenantID -RoleDefinitionId $aadPIMRoleOID -SubjectId $adminIDOID -Type 'userAdd' -AssignmentState 'Active' -Schedule $schedule -Reason $aadPIMRoleActReason){
        Write-Host "Role enabled successfully" -ForegroundColor Green
    }else{
        Write-Host "Fail to enable '$($aadPIMRoleDisplayName)' Role" -ForegroundColor Red
    }
}

write-host
Read-Host "Press Enter to close the window..."