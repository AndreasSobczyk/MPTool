

$Path = $PSScriptRoot

$ErrorActionPreference = "Stop"
$ModuleVersion = (Invoke-Expression (Get-content -path (get-childitem "$Path\MPTool.psd1") -raw)).ModuleVersion
$DestinationFolder = ${env:ProgramFiles}+"\WindowsPowerShell\Modules\MPTool"

if(!(Test-Path -Path $DestinationFolder)){
    mkdir $DestinationFolder
}

#Check for existing versions
$ExistingVersions = Get-ChildItem -Path $DestinationFolder

if($ExistingVersions.count -eq 1){
    Write-Host "Following versions of MPTool installed" -ForegroundColor Green
    $ExistingVersions.Name
    
    do{
        $DeleteOld = Read-host "Do you want to delete older versions? y/n"
    }
    until($DeleteOld -eq "y" -or $DeleteOld -eq "n")
    if($DeleteOld -eq "y"){
        Write-Host "Deleting Older versions" -ForegroundColor Yellow
        $ExistingVersions | Remove-Item -Recurse
    }
}

#Copy Files
$CurrentVersionFolder = $DestinationFolder+"\"+$ModuleVersion
if(!(Test-Path -Path $CurrentVersionFolder)){
    mkdir $CurrentVersionFolder
}

Get-ChildItem -Path $Path | Copy-Item -Destination $CurrentVersionFolder -Force
write-host "Module Installed!" -ForegroundColor Green