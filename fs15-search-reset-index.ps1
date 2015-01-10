$ssa = Get-SPEnterpriseSearchServiceApplication
$disableAlerts = $true
$ignoreUnreachableServer = $true

$ssa.reset($disableAlerts, $ignoreUnreachableServer)
if (-not $?) {
 Write-Error "Reset failed"
}

 