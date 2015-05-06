# SP2013Admin
# This script provides a way to retrieve search crawl log, and export it to a csv file
# Note: to get search content source ID, do following:
#   1. Open the Search Service Application, click on the Content Sources from the left navigation menu, then on this page, all the Content Sources are shown. 
#   2. Click on your required Content Source and check the URL in the address bar. The value of the query string parameter cid is the content source id.
#      http://<server-url>/_admin/search/editcontentsource.aspx?cid=2&appid={GUID}
#
# Example to run the script .\ExportCrawlLog.ps1 -ssaName "New Search Service Application" -exportFile "D:\crawlLog.csv" -getCountOnly $false -maxRows 10000 -urlQueryString "" -isLike $false -contentSourceID 11 -errorLevel -1 -errorID -1

param
(
    [string]$ssaName = $(throw '- Need parameter search service name (e.g. "Search Service Application")'),
    [string]$exportFile = $(throw '- Need parameter file path of exported crawl log (e.g. "D:\crawlLog.csv")'),
    [bool]$getCountOnly = $(throw '- Need parameter to indicate if only get count (e.g. $false)'),
    [int]$maxRows = $(throw '- Need parameter to specifies the number of rows to be retrieved (e.g. 20000)'),
    [string]$urlQueryString = $(throw '- Need parameter to specifies the prefix value to be used for matching the URLs (e.g. "https://contoso.com")'),
    [bool]$isLike = $(throw '- Need parameter to return all URLs starting with $urlQueryString if set to $true (e.g. $false)'),
    [int]$contentSourceID = $(throw '- Need parameter the ID of the content source for which crawl logs should be retrieved, If -1 is specified, URLs will not be filtered by content source. (e.g. "12")'),
    [int]$errorLevel = $(throw '- Need parameter to specify error level of URLs which will be returned. Possible Values -
                         -1 : Do not filter by error level. 
                         0 : Return only successfully crawled URLs.
                         1 : Return URLs that generated a warning when crawled.
                         2 : Return URLs that generated an error when crawled.
                         3 : Return URLs that have been deleted.
                         4 : Return URLs that generated a top level error. (e.g. -1)'),
    [int]$errorID = $(throw '- Need parameter to specifiy error ID of URLs which will be returned. If -1 is supplied, URLs will not be filtered by error ID. (e.g. -1)'),
    [System.DateTime]$startDateTime, # Optional parameter start Date Time. Logs after this date are retrieved. (e.g. "3/20/2015 7:00 AM")
    [System.DateTime]$endDateTime # Optional parameter end Date Time. Logs till this date are retrieved. (e.g. "4/29/2015 6:00 PM")
)

# Add SharePoint PowerShell Snapin
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

if(!$startDateTime){
  $startDateTime = [System.DateTime]::MinValue
}

if (!$endDateTime){
  $endDateTime = [System.DateTime]::MaxValue
}

$ssa = Get-SPEnterpriseSearchServiceApplication -Identity $ssaName
$logs = New-Object Microsoft.Office.Server.Search.Administration.CrawlLog $ssa
$logs.GetCrawledUrls($getCountOnly, $maxRows, $urlQueryString, $isLike, $contentSourceID, $errorLevel, $errorID, $startDateTime, $endDateTime) | export-csv -notype $exportFile