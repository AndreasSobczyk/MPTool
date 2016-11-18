#
# Create a management pack with rules to collect if a PowerShell discovery or monitor script created with MPTool fails

#Management Server
$ManagementServerFQDN = "SCOMMS01tst.contoso.com"

#Management Pack
$ManagementpackName = "MPTool.ScriptFault.Monitoring"
$ManagementPackDescription = "Contains event rules to monitor for script faults from MPTool"

$MP = New-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementpackName -ManagementPackDescription $ManagementPackDescription

#Rule to check for discovery script faults
#Variables
$DisRuleName = "MPTool.DiscoveryScript.Fault.Event"
$DisRuleDescription = "Detects MPTool Discovery script fault events."
$DisEventLogName = "Operations Manager"
$DisEventID = 101
$DisEventDescriptionText = "MPTool Custom Script"
$DisTargetClassName = "Microsoft.Windows.Computer"
$DisTargetClassMPName = "Microsoft.Windows.Library"
$DisTargetClassMPAlias = "Windows"

#CmdLet
$DisRule = New-MPToolWindowsEventAlertRule -ManagementServerFQDN $ManagementServerFQDN `-ManagementPackName $ManagementpackName `-RuleName $DisRuleName `-RuleDescription $DisRuleDescription `-EventLogName $DisEventLogName `-EventId $DisEventID `-EventLevel Error `-EventDescriptionText $DisEventDescriptionText `-TargetClassName $DisTargetClassName `-TargetClassMPName $DisTargetClassMPName `-TargetClassMPAlias $DisTargetClassMPAlias `-Enabled $true
    
#Rule to check for monitor script faults
#Variables
$MonRuleName = "MPTool.MonitorScript.Fault.Event"
$MonRuleDescription = "Detects MPTool Monitor script fault events."
$MonEventLogName = "Operations Manager"
$MonEventID = 103
$MonEventDescriptionText = "MPTool Custom Script"
$MonTargetClassName = "Microsoft.Windows.Computer"
$MonTargetClassMPName = "Microsoft.Windows.Library"
$MonTargetClassMPAlias = "Windows"
#CmdLet$MonRule = New-MPToolWindowsEventAlertRule -ManagementServerFQDN $ManagementServerFQDN `-ManagementPackName $ManagementpackName `-RuleName $MonRuleName `-RuleDescription $MonRuleDescription `-EventLogName $MonEventLogName `-EventId $MonEventID `-EventLevel Error `-EventDescriptionText $MonEventDescriptionText `-TargetClassName $MonTargetClassName `-TargetClassMPName $MonTargetClassMPName `-TargetClassMPAlias $MonTargetClassMPAlias `-Enabled $true