# stop sptimerv4
get-childitem "c:\ProgramData\Microsoft\SharePoint\Config" -include *.xml -recurse | foreach ($_) {remove-item $_.fullname} 
# then replace contents of c:\ProgramData\Microsoft\SharePoint\Config\guid\cache.ini with the number "1"
# restart sptimerv4

# other options
# $ssa.ForceResume($ssa.IsPaused())
# Delete data directory, by default install it will look like this:
# C:\Program Files\Microsoft Office Servers\15.0\Data\Office Server\Applications\Search\Nodes\[Hex ID\IndexComponentN\storage\data\*
# Start “SharePoint Timer Service”
# Start “SharePoint Search Host Controller”