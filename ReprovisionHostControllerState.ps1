$hostname = "fsspe001"
$inst = Get-SPServiceInstance | ? {$_.TypeName -eq “Search Host Controller Service”} | ? {$_.Server -match $hostname}
$sh = Get-SPServiceInstance | ? {$_.SearchServiceInstanceId -eq $inst.SearchServiceInstanceId.ToString()}
$sh.Status
$sh.Unprovision()
$sh.Status
$sh.Provision()
$sh.Status