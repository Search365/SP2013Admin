# Create a new Search Service Application in SharePoint 2013
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False,Position=1)]
    [string]$environment="Default"
)

# Load Common Functions.
$commonScript = Join-Path $PSScriptRoot "Common.ps1"
. $commonScript

StartLogging($MyInvocation.MyCommand.Definition)

# Get xml file for this script.
$xmlDoc = GetXmlFile(GetXmlFilename $MyInvocation.MyCommand.Definition)

# Settings 
$IndexLocation = GetXMLValue $xmlDoc "SearchProperties" $environment "/IndexLocation" # Location must be empty, will be deleted during the process! 
$SearchAppPoolName = $xmlDoc.SearchProperties.SearchAppPoolName
$SearchAppPoolAccountName = GetXMLValue $xmlDoc "SearchProperties" $environment "/SearchAppPoolAccountName"
$SearchServerName = (Get-ChildItem env:computername).value 
$SearchServiceName = $xmlDoc.SearchProperties.SearchServiceName
$SearchServiceProxyName = $xmlDoc.SearchProperties.SearchServiceProxyName
$DatabaseName = $xmlDoc.SearchProperties.DatabaseName

LogWarning "Checking if Search Application Pool exists" 
$SPAppPool = Get-SPServiceApplicationPool -Identity $SearchAppPoolName -ErrorAction SilentlyContinue

if (!$SPAppPool) 
{ 
    Log "Creating Search Application Pool" 
    $spAppPool = New-SPServiceApplicationPool -Name $SearchAppPoolName -Account $SearchAppPoolAccountName -Verbose 
}

# Start Services search service instance 
Log "Start Search Service instances...." 
Start-SPEnterpriseSearchServiceInstance $SearchServerName -ErrorAction SilentlyContinue 
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $SearchServerName -ErrorAction SilentlyContinue

LogWarning "Checking if Search Service Application exists" 
$ServiceApplication = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceName -ErrorAction SilentlyContinue

if (!$ServiceApplication) 
{ 
    Log "Creating Search Service Application" 
    $ServiceApplication = New-SPEnterpriseSearchServiceApplication -Partitioned -Name $SearchServiceName -ApplicationPool $spAppPool.Name -DatabaseName $DatabaseName 
}

LogWarning "Checking if Search Service Application Proxy exists" 
$Proxy = Get-SPEnterpriseSearchServiceApplicationProxy -Identity $SearchServiceProxyName -ErrorAction SilentlyContinue

if (!$Proxy) 
{ 
    Log "Creating Search Service Application Proxy" 
    New-SPEnterpriseSearchServiceApplicationProxy -Partitioned -Name $SearchServiceProxyName -SearchApplication $ServiceApplication 
}


$ServiceApplication.ActiveTopology 
Log $ServiceApplication.ActiveTopology

# Clone the default Topology (which is empty) and create a new one and then activate it 
Log "Configuring Search Component Topology...." 
$clone = $ServiceApplication.ActiveTopology.Clone() 
$SSI = Get-SPEnterpriseSearchServiceInstance -local 
New-SPEnterpriseSearchAdminComponent –SearchTopology $clone -SearchServiceInstance $SSI 
New-SPEnterpriseSearchContentProcessingComponent –SearchTopology $clone -SearchServiceInstance $SSI 
New-SPEnterpriseSearchAnalyticsProcessingComponent –SearchTopology $clone -SearchServiceInstance $SSI 
New-SPEnterpriseSearchCrawlComponent –SearchTopology $clone -SearchServiceInstance $SSI

Remove-Item -Recurse -Force -LiteralPath $IndexLocation -ErrorAction SilentlyContinue 
mkdir -Path $IndexLocation -Force

New-SPEnterpriseSearchIndexComponent –SearchTopology $clone -SearchServiceInstance $SSI -RootDirectory $IndexLocation 
New-SPEnterpriseSearchQueryProcessingComponent –SearchTopology $clone -SearchServiceInstance $SSI 
$clone.Activate()

Log "Your search service application $SearchServiceName is now ready"

StopLogging