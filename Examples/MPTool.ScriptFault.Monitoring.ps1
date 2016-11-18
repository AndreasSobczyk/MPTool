﻿#
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
$DisRule = New-MPToolWindowsEventAlertRule -ManagementServerFQDN $ManagementServerFQDN `
    
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
