$defs = Get-SPUsageDefinition
Write-host $defs

Foreach($def in $defs)
{
  Set-SPUsageDefinition –Identity $def.Name –DaysRetained 1
} 