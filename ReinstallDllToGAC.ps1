param([Parameter(Mandatory = $false, Position = 0, ParameterSetName = "RunSet")]
	  [string]$DeploymentDirectoryPath,
      [Parameter(Mandatory = $true, ParameterSetName = "RunSet")]
	  [string]$ConnectorDllFile
)

function die {
	param($message)	
	Write-Host -ForegroundColor Red -BackgroundColor Black $message
	exit(1)
}

function log {
	param($message)
	[string] $date = get-date -uformat "%G-%m-%d %T"
	Write-Host "[$date] " -ForegroundColor green -nonewline
	[string] $thisHost = ($env:COMPUTERNAME+'.'+$env:USERDNSDOMAIN).toLower()
	Write-Host "[$thisHost] " -ForegroundColor green -nonewline
	Write-Host "".padright(4) -Foregroundcolor green -nonewline
	Write-Host -ForegroundColor green "$message"
}

#################################################
### Validate that the dll library file exists ###
#################################################
if (-not $DeploymentDirectoryPath) { $DeploymentDirectoryPath = $pwd }
$dllFilePath = join-path $DeploymentDirectoryPath $ConnectorDllFile
if (-not (Test-Path $dllFilePath -pathType leaf)) { die "Library file $dllFilePath not found!" }

###########################################
### Remove the dll library from the GAC ###
###########################################
log "Attempting to remove Library file '$dllFilePath' from GAC"
if ($null -eq ([AppDomain]::CurrentDomain.GetAssemblies() |? { $_.FullName -eq "System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" }) ) {
	[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
}
$publishObj = New-Object System.EnterpriseServices.Internal.Publish
$loadedAssembly = [System.Reflection.Assembly]::LoadFile($dllFilePath)
$publishObj.GacRemove($dllFilePath)
log "Library file '$dllFilePath' successfully removed from GAC"

#########################################
### Deploy the dll library to the GAC ###
#########################################
log "Attempting to deploy Library file '$dllFilePath' to GAC"
$publishObj = New-Object System.EnterpriseServices.Internal.Publish
$loadedAssembly = [System.Reflection.Assembly]::LoadFile($dllFilePath)
if ($loadedAssembly.GetName().GetPublicKey().Length -eq 0) { die "The library file '$dllFilePath' must be strongly signed." }
$publishObj.GacInstall($dllFilePath)
log "Library file '$dllFilePath' successfully deployed to GAC"