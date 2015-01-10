# Load Common Functions.
$commonScript = Join-Path $PSScriptRoot "Common.ps1"
. $commonScript

StartLogging($MyInvocation.MyCommand.Definition)

# Get xml file for this script.
$xmlDoc = GetXmlFile("CreateCrawlerManagedProperties.xml")

#Search Service Application
$sa = $xmlDoc.SearchProperties.ServiceName
$searchapp = GetServiceApplication $sa

$crawledPropNodeList = $xmlDoc.SearchProperties.CrawledProperties
foreach ($crawledPropNode in $crawledPropNodeList.CrawledProperty)
{
    RemoveCrawledProperty $crawledPropNode.Name $crawledPropNode.Category
}

StopLogging