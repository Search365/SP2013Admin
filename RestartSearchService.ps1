#####################################
### Restart the osearch15 service ###
#####################################
log "Restarting SharePoint 15 Search Service (osearch15)"
get-service osearch15 | restart-service
log "SharePoint 15 Search Service (osearch15) successfully restarted"