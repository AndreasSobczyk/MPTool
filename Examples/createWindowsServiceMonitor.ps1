<#PSScriptInfo

.VERSION 1.0

.GUID 4c5ef58e-f8f9-4dc3-8c9a-3b6133e65fb4

.AUTHOR Andreas Sobczyk, CloudMechanic.net

.COMPANYNAME CloudMechanic.net

.COPYRIGHT 

.TAGS MPTool

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

 .DESCRIPTION 
  This script will create everything needed to monitor a Windows Service with SCOM using MPTool.

 .Parameter -ManagementServerFQDN
  Specify the Management server to connect to.

 .Parameter -ManagementPackName
  Specify the Management pack for all the components to be be placed in.

 .Parameter -CreateMP
  Specify if the script should create the Management Pack.

 .Parameter -ServiceDisplayName
  Specify the Display name you would like on the class

 .Parameter -ServiceName
  Specify the Windows service name to monitor (Servicename NOT Displayname)

 .Parameter -UnhealthyState
  Specify the state of the monitor if triggered, Error or Warning.

 .Example
  # Create a new management pack CM.MyService.ServiceMonitoring for the class discovery and monitor to monitor the service "MyService"
  .\WindowsServiceMonitor.ps1 -ManagementServerFQDN "SCOM01.cloudmechanic.net" `    -ManagementPackName "CM.MyService.ServiceMonitoring" `    -CreateMP $true `	
    -ServiceDisplayName "My Precious Service" `
    -ServiceName "MyService" `
    -UnhealthyState Error

#> 
Param(
    [string]$ManagementServerFQDN,
    [string]$ManagementPackName,
    [boolean]$CreateMP = $true,
    [string]$ServiceDisplayName,
    [string]$ServiceName,
    [string]$UnhealthyState = "Error"
    
)

$ErrorActionPreference = "Stop"

$ManagementPackDisplayName  = $ManagementPackName.Replace("."," ")
$ManagementPackDescription = "$ManagementPackDisplayName  - Created with SCOMMPTools"

$ClassName = "CM.$ServiceName.Windows.Service"
$ClassDisplayName = "CM $ServiceDisplayName Windows Service"
$ClassDescription = "CM $ServiceDisplayName Windows Service  - Created with SCOMMPTools"

$DiscoveryName = "$ClassName.Discovery"
$RegistryPath = "SYSTEM\CurrentControlSet\Services\$ServiceName\"

if($CreateMP -eq $true){
    New-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackDisplayName $ManagementPackDisplayName -ManagementPackDescription $ManagementPackDescription
}

New-MPToolLocalApplicationClass -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ClassName $ClassName -ClassDisplayName $ClassDisplayName -ClassDescription $ClassDescription

New-MPToolFilteredRegistryDiscovery -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -DiscoveryName $DiscoveryName -TargetClassName "Microsoft.Windows.Computer" -RegistryPath $RegistryPath -DiscoveryClassName $ClassName  -IntervalSeconds 300

New-MPToolWindowsServiceMonitor -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -TargetClassName $ClassName -UnhealthyState $UnhealthyState -ServiceName $ServiceName