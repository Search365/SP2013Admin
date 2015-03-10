$destination = 'Z:\sp2013\15\LOGS'

# Check directory exists - if not create it.
if(!(Test-Path -Path $destination )){
    New-Item -ItemType directory -Path $destination
    Write-Host "Directory Created: $destination"

    Write-Host "Restarting SharePoint Tracing Service..."
    Get-Service SPTraceV4 | Restart-Service
}
else
{
    Write-Host "Directory already exists: $destination"
}