#####################################
### Restart the osearch15 service ###
#####################################
Write-Host "Restarting SharePoint 15 Search Service (osearch15)"
get-service osearch15 | restart-service
Write-Host "SharePoint 15 Search Service (osearch15) successfully restarted"