$sub = ""
$rg = ""
$ws = ""
$threatTables = @("ThreatIntelExportOperation", "ThreatIntelIndicators", "ThreatIntelligenceIndicator", "ThreatIntelObjects")
 
Set-AzContext -Subscription $sub
 
$tables = (Get-AzOperationalInsightsTable -ResourceGroupName $rg -WorkspaceName $ws).Name | Where-Object { $_ -notin $threatTables } | Sort-Object
 
foreach( $table in $tables ){
  try {
    $results = Update-AzOperationalInsightsTable -ResourceGroupName $rg -WorkspaceName $ws -TableName $table -RetentionInDays -1 -TotalRetentionInDays 365 -ErrorAction SilentlyContinue
		
    if (-not $results) {
      throw "Access denied. Missing proper Azure role - Log Analytics Contributor"
    }
    else {
      Write-Host "Retention updated: " -NoNewLine
      Write-Host $results.TableName -ForegroundColor cyan -NoNewLine
      Write-Host " - Hot=" -NoNewLine
      Write-Host "$($results.RetentionInDays)d" -ForegroundColor green -NoNewLine
      Write-Host " / Cold=" -NoNewLine
      Write-Host "$($results.TotalRetentionInDays - $results.RetentionInDays)d" -ForegroundColor green -NoNewLine
      Write-Host " / Total=" -NoNewLine
      Write-Host "$($results.TotalRetentionInDays)d" -ForegroundColor green -NoNewLine
    }
  }
  catch {
      Write-Host "Error: $_" -ForegroundColor red
      break
  }
}
