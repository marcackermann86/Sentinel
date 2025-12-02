# Set your path to the csv file
# Format = rule name, new severity
$csvPath = "<INSERT FILE PATH HERE>"

# Import the csv file
$rules = Import-Csv -Path $csvPath

# Set Azure scope
$sub = ""
$rg = ""
$ws = ""

# Not needed for Azure CLI
# Uncomment if running locally in Powershell
Connect-AzAccount

# Make sure we are working in the right subscription
Set-AzContext -Subscription $sub

# Get all the enabled NRT and Scheduled analytic rules in Sentinel
$enabledRules = Get-AzSentinelAlertRule -ResourceGroupName $rg -WorkspaceName $ws | where-object {$_.Enabled -eq "true" -and $_.Kind -in ("NRT", "Scheduled")}

foreach ($rule in $rules) {
	# Get current rule name and new severity
	$ruleName = $rule.RuleName
	$newSeverity = $rule.NewSeverity
	
	# No Critical severity in Sentinel, set to High instead
	if($newSeverity -eq "Critical") {
		$newSeverity = "High"
	}
	
	# Retrieve rule id and type for list of enabled rules
	$ruleId = ($enabledRules | where-object {$_.DisplayName -eq $ruleName}).Name
	$ruleType = ($enabledRules | where-object {$_.DisplayName -eq $ruleName}).Kind

	try {	
		# Disable rules marked to be disabled
		if ($newSeverity -eq "Disable") {
			if($ruleType -eq "NRT") {
				$results = Update-AzSentinelAlertRule -ResourceGroupName $rg -WorkspaceName $ws -ruleId $ruleId -Disabled -NRT
			}
			else {
				$results = Update-AzSentinelAlertRule -ResourceGroupName $rg -WorkspaceName $ws -ruleId $ruleId -Disabled -Scheduled
			}

			Write-Host "Analytics rule disabled successfully - " -ForegroundColor Yellow -NoNewLine
			Write-Host $ruleName
		}
		else {			
			# Update rule severity based on csv file
			if($ruleType -eq "NRT") {
				$results = Update-AzSentinelAlertRule -ResourceGroupName $rg -WorkspaceName $ws -ruleId $ruleId -Severity $newSeverity -NRT -CreateIncident
			}
			else {
				$results = Update-AzSentinelAlertRule -ResourceGroupName $rg -WorkspaceName $ws -ruleId $ruleId -Severity $newSeverity -Scheduled -CreateIncident
			}

			Write-Host "Analytic rule severity updated successfully - " -ForegroundColor Green -NoNewLine
			Write-Host $ruleName
		}
	}
	catch {
		# Catch errors
		Write-Host "Failed to update analytic rule - " -ForegroundColor Red -NoNewLine
		Write-Host $ruleName
	}
}
