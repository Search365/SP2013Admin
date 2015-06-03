$ssa = Get-SPEnterpriseSearchServiceApplication
$active = Get-SPEnterpriseSearchTopology -SearchApplication $ssa -Active
$clone = New-SPEnterpriseSearchTopology -SearchApplication $ssa -Clone -SearchTopology $active

Get-SPEnterpriseSearchComponent -SearchTopology $clone

$crawlComponent = Get-SPEnterpriseSearchComponent -SearchTopology $clone | Where-Object { $_.Name -like "CrawlComponent*" }
Remove-SPEnterpriseSearchComponent -Identity $crawlComponent -SearchTopology $clone

Get-SPEnterpriseSearchComponent -SearchTopology $clone

#Set-SPEnterpriseSearchTopology -Identity $clone

Write-Host "Complete"