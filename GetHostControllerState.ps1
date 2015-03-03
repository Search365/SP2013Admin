<#
$inst = Get-SPServiceInstance | ? {$_.TypeName -eq "Search Host Controller Service" } | ? { $_.PrimaryHostController -eq $true }
$sh = Get-SPServiceInstance | ? {$_.SearchServiceInstanceId -eq $inst.SearchServiceInstanceId.ToString()}
$sh.Status
#>

$hostname = "fsspe001"
$sh = Get-SPServiceInstance | ? {$_.TypeName -eq “Search Host Controller Service”} | ? {$_.Server -match $hostname}
$sh.Status

Get-SPServiceInstance | sort TypeName | select TypeName, Status, Server, PrimaryHostController | ? {$_.TypeName -eq "Search Host Controller Service" }