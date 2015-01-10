#$sourceName = "Enquiry"
$ssa = Get-SPEnterpriseSearchServiceApplication
#$contentSource = Get-SPEnterpriseSearchCrawlContentSource -Identity $sourceName -SearchApplication $ssa
#$contentSource.StopCrawl()
#Write-Host "Found countentSource $contentSource"

Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $ssa | ForEach-Object {
    if ($_.CrawlStatus -ne "Idle")
    {
        Write-Host "Stopping currently running crawl for content source $($_.Name)..."
        $_.StopCrawl()
        
        do 
        { 
            Start-Sleep -Seconds 1 
            Write-Host "Waiting for crawl for content source $($_.Name) to stop..."
        }
        while ($_.CrawlStatus -ne "Idle")
    }
}