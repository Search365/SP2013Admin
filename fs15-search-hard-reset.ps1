# Stop Timer Service.
Get-service sptimerv4 | Stop-Service

# Delete all xml files.
$systemCache = "c:\ProgramData\Microsoft\SharePoint\Config"
Get-ChildItem $systemCache -include *.xml -recurse | foreach ($_) {remove-item $_.fullname} 

# Replace contents of c:\ProgramData\Microsoft\SharePoint\Config\guid\cache.ini with the number "1"
Get-ChildItem $systemCache -include "cache.ini" -recurse | foreach ($_) { Set-Content $_.FullName "1" }

# restart sptimerv4
Get-service sptimerv4 | Start-Service

# other options
# $ssa.ForceResume($ssa.IsPaused())
# Delete data directory, by default install it will look like this:
# C:\Program Files\Microsoft Office Servers\15.0\Data\Office Server\Applications\Search\Nodes\[Hex ID\IndexComponentN\storage\data\*
# Start “SharePoint Timer Service”
# Start “SharePoint Search Host Controller”