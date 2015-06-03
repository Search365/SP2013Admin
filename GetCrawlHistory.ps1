[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False,Position=1)]
    [string]$environment="Default"
)

# Load Common Functions.
$commonScript = Join-Path $PSScriptRoot "Common.ps1"
. $commonScript

try
{
    StartLogging($MyInvocation.MyCommand.Definition)

    # Get xml file for this script.
    $xmlDoc = GetXmlFile(GetXmlFilename $MyInvocation.MyCommand.Definition)

    # Variables.
    $siteUrl = GetSiteUrl($environment)

    $web = Get-SPWeb $siteUrl
    $searchAppName = $xmlDoc.ContentSources.SearchServiceApplicationName

    ##########################################
    ### Get the Search Service Application ###
    ##########################################
    $searchServiceApplication = GetServiceApplication $searchAppName
    $contentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchServiceApplication

    # Get the content sources from configuration that history is required.
    $requestedContentSources = $xmlDoc.ContentSources.ContentSource

    $results = $null

    foreach ($requestedContentSource in $requestedContentSources)
    {	
        $contentSourceName = $requestedContentSource.Name
	    Log "Get crawl log history for content source '$contentSourceName'"

        $numberOfResults = $requestedContentSource.NumberOfCrawls

        if (!$numberOfResults)
        {
            # Set the default.
            $numberOfResults = 1000
        }

        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search.Administration")
        $contentSource = $contentSources | ? { $_.Name -eq $contentSourceName }    

        $crawlLog = new-object Microsoft.Office.Server.Search.Administration.CrawlLog($searchServiceApplication)
        $crawlHistory = $crawlLog.GetCrawlHistory($numberOfResults, $contentSource.Id)
        $crawlHistory.Columns.Add("CrawlTypeName", [String]::Empty.GetType()) | Out-Null

        # Label the crawl type
        $labeledCrawlHistory = $crawlHistory | % {
            $_.CrawlTypeName = [Microsoft.Office.Server.Search.Administration.CrawlType]::Parse([Microsoft.Office.Server.Search.Administration.CrawlType], $_.CrawlType).ToString()
            return $_
        }

        # $labeledCrawlHistory | Out-GridView
        $results = $results + $labeledCrawlHistory
    }

    $filename = Join-Path $PSScriptRoot "CrawlLogHistory.csv"
    $results | Export-Csv $filename
}
catch [Exception] {
    LogError $_.Exception.Message
}
finally
{
    if ($web)
    {
        $web.Dispose()   
    }

    StopLogging
}