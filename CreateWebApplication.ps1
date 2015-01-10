# New-SPSite -Url "http://fwosearch.edc.hosts.devnetwork" -OwnerAlias "FirstServis\Administrator" -Name "FWO Search" -Template "STS#1"

$ap = New-SPAuthenticationProvider
New-SPWebApplication -Name "FWO Search" -Port 80 -HostHeader fwosearch.edc.hosts.devnetwork -URL "http://fwosearch.edc.hosts.devnetwork" -ApplicationPool "fwosearch.edc.hosts.devnetwork" -ApplicationPoolAccount (Get-SPManagedAccount "FirstServis\Administrator") -AuthenticationProvider $ap