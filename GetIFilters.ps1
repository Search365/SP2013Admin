$filename = Join-Path $PSScriptRoot "IFilters.csv"

$searchServiceApplication = Get-SPEnterpriseSearchServiceApplication
Get-SPEnterpriseSearchFileFormat -SearchApplication $searchServiceApplication | Export-Csv $filename