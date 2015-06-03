$ssa = Get-SPEnterpriseSearchServiceApplication
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active

$activeComponents = Get-SPEnterpriseSearchComponent -SearchTopology $active
$activeComponents

$filename = Join-Path $PSScriptRoot "ActiveTopology.txt"
$activeComponents > $filename