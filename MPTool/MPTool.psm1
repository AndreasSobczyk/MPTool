#region Base Management Pack#####
#################################

Function New-MPToolManagementPackAlias
{
<# 
 .Synopsis
  Generates Management Pack alias and returns the string by removing “.” (DOTs) in Management Pack Name

 .Description
  Generates Management Pack alias and returns the string by removing “.” (DOTs) in Management Pack Name

 .Parameter -ManagementPackName 
  The name of the Management Pack to generate the alias for. Example - Contoso.Monitoring
 
 .Example
  # Generate MP Alias for Contoso.Monitoring, returns "ContosoMonitoring"
  New-MPToolManagementPackAlias -ManagementPackName Contoso.Monitoring
#>
[CmdletBinding()]
    PARAM (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name (fx: Contoso.MyManagementPack)')][String]$ManagementPackName
    )

    Switch ($ManagementPackName)
    {
        default {$alias = $ManagementPackName.Replace('.','');break};
    }
    return $alias;
}

Function Get-MPToolManagementPackReferenceAlias
{
<# 
 .Synopsis
  Gets the alias of a reference management pack in a specific management pack

 .Description
  Gets the alias of a reference management pack in a specific management pack

 .Parameter -ManagementServerFQDN 
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName 
  Name of the management pack to find alias in. Example - Contoso.Monitoring

 .Parameter -ManagementPackReferenceName 
  Name of the management pack to get the alias for. Example - Contoso.Library
 
 .Example
  # Gets the management pack alias for Contoso.Library in the Contoso.Monitoring Management Pack
  Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN "scom01.contoso.com" -ManagementPackName "Contoso.Monitoring" -ManagementPackReferenceName "Contoso.Library"
#>
[CmdletBinding()]
    PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name (fx: Contoso.MyManagementPack)')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the name of reference the management pack (fx: Contoso.Library)')][String]$ManagementPackReferenceName
    )

    try
    {
        $ErrorActionPreference = "Stop"
    
        $mp = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        $References = $mp.References


        foreach ($Reference in $References)
        {
            if ($Reference.Value.name -eq $ManagementPackReferenceName)
            {
            
                return $Reference.Key;
                
            }
        }
        Write-Error "Management pack reference $ManagementPackReferenceName not found";
    }
    Catch
    {
        Write-Error "Error searching for management pack reference aliase for $ManagementPackReferenceName";
    }
}

Function New-MPToolManagementPack
{
<# 
 .Synopsis
  Creates a new empty management pack in SCOM

 .Description
  Creates a new empty management pack in SCOM

 .Parameter -ManagementServerFQDN 
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName 
  Name of the new management pack. Example - Contoso.Monitoring

 .Parameter -ManagementPackDescription
  Description of the new management pack. Example - "This is a Contoso Monitoring MP"

 .Parameter -ManagementPackDisplayName 
  (Optional) Display Name of the new management pack. Example - "Contoso Monitoring"
 
 .Example
  # Creates a new management pack with the name Contoso.Monitoring, Description and Displayname 
  New-MPToolManagementPack -ManagementServerFQDN "scom01.contoso.com" -ManagementPackName  "Contoso.Monitoring" -ManagementPackDisplayName "Contoso Monitoring" -ManagementPackDescription "This is a Contoso Monitoring MP"
#>
[CmdletBinding()] 
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name (fx: Contoso.MyManagementPack)')][String]$ManagementPackName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack display name (fx: Contoso MyManagementPack)')][String]$ManagementPackDisplayName=$null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack description')][String]$ManagementPackDescription
        )
  
    try
    {
    Write-Verbose "Creating new management pack with paramaters:";
    Write-Verbose "Management server: $ManagementServerFQDN";
    Write-Verbose "Management pack name: $ManagementPackName";
    Write-Verbose "Management pack display name $ManagementPackDisplayName";
    Write-Verbose "Management pack desciption: $ManagementPackDescription"
    Write-Verbose "Generating management pack display name if not specified"
    
    if ($ManagementPackDisplayName -eq "")
    {
        $ManagementPackDisplayName = $ManagementPackName.Replace('.',' ');
    }
    Write-Verbose "Management pack display name: $ManagementPackDisplayName";

    Write-Verbose "Connecting to $ManagementServerFQDN"
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;
    
    Write-Verbose "Checking if management pack exists"
    $mpExists = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
    if ($mpExists -ne $null)
    {
        Write-Error "Management pack $ManagementPackName already exists";
        return $false;
    }

    Write-Verbose "Creating and saving management pack"
    $MPStore = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackFileStore
    $mp = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPack($ManagementPackName, $ManagementPackDisplayName, (New-Object Version(1, 0, 0)), $MPStore)
    $mp.Description = $ManagementPackDescription;
    $mp.DefaultLanguageCode = "ENU";
    $mp.DisplayName = $ManagementPackDisplayName;
    $mp.FriendlyName = $ManagementPackDisplayName;
    $mp.AcceptChanges();
    $ManagementGroup.ImportManagementPack($mp)

    $GetMP = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
    return $GetMP;
    }
    Catch
    {
        
        Write-Error $_.Exception.Message;
        return $false;
    }
    
}

Function New-MPToolOverrideManagementPack
{
<# 
 .Synopsis
  Creates a management pack for overrides of another management pack

 .Description
  Creates a management pack for overrides of another management pack. Can add prefix and will automatically add .Overrides as postfix.

 .Parameter -ManagementServerFQDN 
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName 
  Name of the new management pack. Example - Contoso.Monitoring

 .Parameter -ManagementPackDescription
  (Optional) Description of the new override management pack.. Example - "This is a Contoso Monitoring MP for overrides"

 .Parameter -ManagementPackPrefix 
  (Optional) Prefix for the override management pack. Example - "FabrikAm"
 
 .Example
  # Creates an override management pack for Contoso.Monitoring with Prefix FabrikAm. Override MP Name will be FabrikAm.Contoso.Monitoring.Overrides
  New-MPToolOverrideManagementPack -ManagementServerFQDN scom01.contoso.com -ManagementPackName Contoso.Monitoring -ManagementPackDescription "This is a Contoso Monitoring MP for overrides" -ManagementPackPrefix FabrikAm
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name for which you want to create an override mp (fx: Contoso.MyManagementPack)')][String]$ManagementPackName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the override management pack description')][String]$ManagementPackDescription=$null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack prefix')][String]$ManagementPackPrefix=$null
        )
    try
    {
    Write-Verbose "Connecting to $ManagementServerFQDN"
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;

    Write-Verbose "Getting Source Managemnet pack $ManagementPackName"
    $sourceMP = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    
    #If prefix is set
    if ($ManagementPackPrefix -ne "")
    {
        $overrideMPName = $ManagementPackPrefix + "." + $sourceMP.name + ".Overrides";
        if ($sourceMP.DisplayName -eq "")
        {
            $overrideMPDisplayName = $ManagementPackPrefix + " " + $sourceMP.FriendlyName + " Overrides";
        }
        else
        {
            $overrideMPDisplayName = $ManagementPackPrefix + " " + $sourceMP.DisplayName + " Overrides";
        }
    }
    #Else no prefix
    else
    {
        $overrideMPName = $ManagementPackName + ".Overrides";
        if ($sourceMP.DisplayName -eq "")
        {
            $overrideMPDisplayName = $sourceMP.FriendlyName + " Overrides";
        }
        else
        {
            $overrideMPDisplayName = $sourceMP.DisplayName + " Overrides";
        }
    }
    if ($ManagementPackDescription -eq "")
    {
        $ManagementPackDescription = "This management pack contains overrides for management pack $ManagementPackName";
    }

    Write-Verbose "Checking if management pack exists"
    $mpExists = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $overrideMPName
    if ($mpExists -ne $null)
    {
        Write-Error "Management pack $overrideMPName already exists";
        return $false;
    }

    Write-Verbose "Creating and import Management pack"
    Write-Verbose "MP Name: $overrideMPName"
    Write-Verbose "MP Displayname: $overrideMPDisplayName"
    Write-Verbose "MP Description: $ManagementPackDescription"

    $MPStore = New-Object Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackFileStore
    $mp = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPack($overrideMPName, $overrideMPDisplayName, (New-Object Version(1, 0, 0)), $MPStore)
    $mp.Description = $ManagementPackDescription;
    $mp.DefaultLanguageCode = "ENU";
    $mp.DisplayName = $overrideMPDisplayName;
    $mp.FriendlyName = $overrideMPDisplayName;
    $mp.AcceptChanges();
    $ManagementGroup.ImportManagementPack($mp)
    
    $GetMP = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $overrideMPName
    return $GetMP;
    }
    Catch
    {
        Write-Error $_.Exception.Message;
        return $false;
    }
}

Function Get-MPToolActiveManagementGroupConnection
{
<# 
 .Synopsis
  Get a Management Group Connection

 .Description
  Get a Management Group Connection if not already connected to it then a new connection is established.
  Return object of type [Microsoft.EnterpriseManagement.ManagementGroup]
 
 .Parameter -ManagementServerFQDN 
  FQDN of the management server. Example - scom01.contoso.com

 .Example
  # Returns a active management group connection to scom01.contoso.com
  Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN scom01.contoso.com
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN
        )

    Write-Verbose "Calling Get-MPToolActiveManagementGroupConnection with parameters:";
    Write-Verbose "Management server: $ManagementServerFQDN"; 
    $ManagementGroup = Get-SCOMManagementGroup -ComputerName $ManagementServerFQDN;

    Write-Verbose "Checking if management group connection is active";
    if (($ManagementGroup.IsConnected -ne $true) -or ($ManagementGroup.Name -eq $null))
    { 
        $ManagementGroup = Connect-MPToolManagementGroup -ManagementServerFQDN $ManagementServerFQDN;
    }
    
    return $ManagementGroup;
}

Function Connect-MPToolManagementGroup
{
<# 
 .Synopsis
  Connects to SCOM management group.

 .Description
  Connects to SCOM management group.
  Return object of type [Microsoft.EnterpriseManagement.ManagementGroup]

 .Parameter -ManagementServerFQDN 
  FQDN of the management server. Example - scom01.contoso.com

 .Example
  # Connect to scom01.contoso.com management group
  Connect-MPToolManagementGroup -ManagementServerFQDN scom01.contoso.com
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN
        )
    $ErrorActionPreference = "STOP";
    try
    {
        Write-Verbose -Message "Calling Connect-MPToolManagementGroup with parameters:";
        Write-Verbose -Message "Management server: $ManagementServerFQDN";
        try
        {
            Add-PSSnapin Microsoft.EnterpriseManagement.OperationsManager.Client
        }
        catch
        {
            Write-Verbose $_.Exception.Message
        }

        Write-Verbose -Message "Loading management group";
        $ManagementGroup = $null;
        [Microsoft.EnterpriseManagement.ManagementGroup]$ManagementGroup = New-Object Microsoft.EnterpriseManagement.ManagementGroup($ManagementServerFQDN)

        return $ManagementGroup;
    }
    catch
    {
        Return $false;
        Write-Error $_.Exception.Message;
    }
    
}

Function Get-MPToolManagementPack
{
<# 
 .Synopsis
  Gets SCOM Management pack from management server.

 .Description
  Gets SCOM Management pack from management server.
  Return object of type [Microsoft.EnterpriseManagement.ManagementPackStore]

 .Parameter -ManagementServerFQDN 
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName 
  Name of the management pack. Example - Contoso.Library

 .Example
  # Gets the management pack "Contoso.Library" from management server scom01.contoso.com.
  Get-MPToolManagementPack -ManagementServerFQDN "scom01.contoso.com" -ManagementPackName "Contoso.Library"
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName     
        )

    $ErrorActionPreference = "Stop";
    try
    {
        Write-Verbose -Message "Calling Get-MPToolManagementPack with parameters:";
        Write-Verbose -Message "Management server: $ManagementServerFQDN";
        Write-Verbose -Message "Management pack name: $ManagementPackName";
        Write-Verbose -Message "Checking connection to SCOM";
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;

        Write-Verbose "Defining search critieria";
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name='$ManagementPackName'");

        $mp = $null;
        Write-Verbose "Searching for management pack $ManagementPackName";
        $mp = $ManagementGroup.ManagementPacks.GetManagementPacks($criteria);
        return $mp;
    }
    Catch
    {
        Write-Error $("Error loading management pack $ManagementPackName - " + $_.Exception);
    }
}

Function Add-MPToolManagementPackReference
{
<# 
 .Synopsis
  Add a management pack reference to a management pack.

 .Description
  Add a management pack reference to a management pack.

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName
  Name of the management pack. Example - Contoso.Monitoring
 
 .Parameter -ReferenceManagementPackName
  Name of the reference management pack to add. Example - Contoso.Library

 .Parameter -ReferenceManagementPackAlias
  Alias name for the reference. Example - ContosoLibrary

 .Example
  # Adds the management pack Contoso.Library as a reference in Contoso.Monitoring with the alias ContosoLibrary
  Add-MPToolManagementPackReference -ManagementServerFQDN scom01.contoso.com -ManagementPackName "Contoso.Monitoring" -ReferenceManagementPackName "Contoso.Monitoring" -ReferenceManagementPackAlias "ContosoLibrary"
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the reference management pack name')][String]$ReferenceManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter a alias for the reference management pack')][String]$ReferenceManagementPackAlias 
        )
    $ErrorActionPreference = "Stop";
    try
    {
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        if ($ManagementPack -eq $null)
        {
            Write-Error "Management pack $ManagementPackName not found";
            return $false;
        }

        $ReferenceManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ReferenceManagementPackName;
        if ($ReferenceManagementPack -eq $null)
        {
            Write-Error "Reference Management pack $ReferenceManagementPackName not found";
            return $false;
        }

        Write-Verbose -Message "Checking if Reference MP is Sealed"
        if ($ReferenceManagementPack.Sealed -eq $false)
        {
            Write-Error "Reference Management pack $ReferenceManagementPackName is Unsealed";
            return $false;
        }

        $KeyToken = $ReferenceManagementPack.KeyToken;
        $Version = $ReferenceManagementPack.Version;
        write-Verbose -Message "Adding Reference $ReferenceManagementPackName to $ManagementPackName"
        $ManagementPackRef = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackReference($ManagementPack, $ReferenceManagementPackName, $KeyToken, $Version)
		Try {
			$ManagementPack.References.Add($ReferenceManagementPackAlias, $ManagementPackRef)
            $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
            $ManagementPack.verify()
            $ManagementPack.AcceptChanges()
            
            $GetMP = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
            return $true;

        } 
        Catch {
            $ManagementPack.RejectChanges();
            Write-Error $_.Exception.Message;
            return $false;
        }
    }
    Catch
    {
        Write-Error $_.Exception.Message;
        return $false;
    }
}
#endregion

#region Classes ##########
##########################

Function New-MPToolApplicationComponentClass
{
<# 
 .Synopsis
  Creates a new class with from the base class Microsoft.Windows.ApplicationComponent.

 .Description
  Creates a new class with from the base class Microsoft.Windows.ApplicationComponent.

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.Monitoring"
 
 .Parameter -ClassName
  Name of the new class. Example - "Contoso.NewClass"

 .Parameter -ClassDisplayName
  Display name of the new class. Example - "Contoso NewClass"

 .Parameter -ClassDescription
  Description of the new class. Example - "Class to Contoso.NewClass"
 
 .Parameter -ClassKeyProperties
  Array of key properties for the new class. Usually only one key property. Example - @("KeyProp")

 .Parameter -ClassNonKeyProperties
  Array of non-key properties for the new class. Example - @("Prop1","Prop2")

 .Parameter -IsAbstract
  Abstract setting for the class $true / $false. Default is $false
 
 .Parameter -IsHosted
  Hosted setting for the class $true / $false. Default is $false

 .Parameter -IsSingleton
  Singleton setting for the class $true / $false. Default is $false

 .Example
  # Creates a new abstract class named "Contoso.NewClass", with one key property "KeyProp" and two non-key properties "Prop1" and "Prop2", in the management pack "Contoso.NewClass"
      New-MPToolApplicationComponentClass -ManagementServerFQDN scom01.contoso.com ´                                        -ManagementPackName "Contoso.Monitoring" ´                                        -ClassName "Contoso.NewClass" ´                                        -ClassDisplayName "Contoso NewClass" ´                                        -ClassDescription "Class to Contoso.NewClass" ´                                        -ClassKeyProperties @("KeyProp") ´                                        -ClassNonKeyProperties @("Prop1","Prop2") ´                                        -IsAbstract $true -IsHosted $false -IsSingleton $false
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Class Name')][String]$ClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Class Display name')][String]$ClassDisplayName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Class Description')][String]$ClassDescription,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class key property names')][array]$ClassKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class -non-key property names')][array]$ClassNonKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Is Abstract: true/false. Default false')][Boolean]$IsAbstract = $false,
        [Parameter(Mandatory=$false,HelpMessage='Is Hosted: true/false. Default false')][Boolean]$IsHosted = $false,
        [Parameter(Mandatory=$false,HelpMessage='Is Singleton: true/false. Default false')][Boolean]$IsSingleton = $false
    )
    try
    {
        $BaseClassName = "Microsoft.Windows.ApplicationComponent";
        $BaseClassManagemntPackName = "Microsoft.Windows.Library";
        $BaseClassManagemntPackAlias = "Windows";

        if ($ClassDisplayName -eq "")
        {
            $ClassDisplayName = $ClassName.Replace('.',' ');
        }

        # loading connection
        $ManagementGroup = $null;
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;
    
        # loading mp
        $ManagementPack = $null;
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
        if ($ManagementPack -eq $null)
        {
            Write-Error "Management pack $ManagementPackName not found";
            return $false
        }

        Write-Verbose -Message "Checking if management pack is unsealed"
        if ($ManagementPack.Sealed -eq $true)
        {
            Write-Error "Management pack $ManagementPackName is sealed";
            return $false;
        }

        $ClassExists = $ManagementPack.GetClasses() | ? {$_.Name -eq $ClassName}
        if($ClassExists -ne $null){
            Write-Error -Message "Class $ClassName already exists";
            return $false;
        }
        
        #Adding Base Class Reference
        Write-Verbose -Message "Adding Base class Reference"
        if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($BaseClassManagemntPackName) -eq $false)){
            $RefStatus = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $BaseClassManagemntPackName -ReferenceManagementPackAlias $BaseClassManagemntPackAlias;
            if ($RefStatus -ne $true)
            {
                Write-Error "Error adding reference mp $defaultReferenceName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $BaseClassManagemntPackAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $BaseClassManagemntPackName;
        }

        # creating class
        Write-verbose -Message "Creating Class $ClassName"
        $class = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($ManagementPack, $ClassName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public);
    
        # target class
        $targetManagementPack = $null;
        $targetClass = $null;
        $targetManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $BaseClassManagemntPackName;
        $targetClass = $targetManagementPack.GetClass($BaseClassName);

        # configure class
        $class.DisplayName = $ClassDisplayName;
        $class.Description = $ClassDescription;
        $class.Base = $targetClass;
        $class.Singleton = $IsSingleton;
        $class.Abstract = $IsAbstract;
        $class.Hosted = $IsHosted;

        foreach ($classPropertyName in $ClassKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $true;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }
        foreach ($classPropertyName in $ClassNonKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $false;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }

        $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
        $ManagementPack.AcceptChanges();

        $GetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ClassName $ClassName
        return $GetClass
    }
    Catch
    {
        $ManagementPack.RejectChanges();
        Write-Error $_.Exception.Message;
        return $false;
    }
}

Function New-MPToolComputerRoleClass
{
<# 
 .Synopsis
  Creates a new class with from the base class Microsoft.Windows.ComputerRole

 .Description
  Creates a new class with from the base class Microsoft.Windows.ComputerRole

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.Monitoring"
 
 .Parameter -ClassName
  Name of the new class. Example - "Contoso.ComputerRole"

 .Parameter -ClassDisplayName
  Display name of the new class. Example - "Contoso ComputerRole"

 .Parameter -ClassDescription
  Description of the new class. Example - "Class to Contoso.ComputerRole"
 
 .Parameter -ClassKeyProperties
  Array of key properties for the new class. Usually only one key property. Example - @("KeyProp")

 .Parameter -ClassNonKeyProperties
  Array of non-key properties for the new class. Example - @("Prop1","Prop2")

 .Parameter -IsAbstract
  Abstract setting for the class $true / $false. Default is $false
 
 .Parameter -IsSingleton
  Singleton setting for the class $true / $false. Default is $false

 .Example
  # Creates a new abstract class named "Contoso.ComputerRole", with one key property "KeyProp" and two non-key properties "Prop1" and "Prop2", in the management pack "Contoso.NewClass"
  New-MPToolComputerRoleClass -ManagementServerFQDN scom01.contoso.com ´                                    -ManagementPackName "Contoso.Monitoring" ´                                    -ClassName "Contoso.ComputerRole" ´                                    -ClassDisplayName "Contoso ComputerRole" ´                                    -ClassDescription "Class to Contoso.ComputerRole" ´                                    -ClassKeyProperties @("KeyProp") ´                                    -ClassNonKeyProperties @("Prop1","Prop2") '
                                    -IsAbstract $true -IsSingleton $false
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Class Name')][String]$ClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Class Display name')][String]$ClassDisplayName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the Class Description')][String]$ClassDescription,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class key property names')][array]$ClassKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class -non-key property names')][array]$ClassNonKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Is Abstract: true/false. Default false')][Boolean]$IsAbstract = $false,
        [Parameter(Mandatory=$false,HelpMessage='Is Singleton: true/false. Default false')][Boolean]$IsSingleton = $false
    )

    try
    {
        $BaseClassName = "Microsoft.Windows.ComputerRole";
        $BaseClassManagemntPackName = "Microsoft.Windows.Library";
        $BaseClassManagemntPackAlias = "Windows";
    
        if ($ClassDisplayName -eq "")
        {
            $ClassDisplayName = $ClassName.Replace('.',' ');
        }
    
        # connecting
        $ManagementGroup = $null;
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;
        if ($ManagementGroup -eq $null)
        {
            Write-Output "Error connecting to SCOM management server $ManagementServerFQDN";
            return $false;
        }

       # loading mp
        $ManagementPack = $null;
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
        if ($ManagementPack -eq $null)
        {
            Write-Error "Management pack $ManagementPackName not found";
            return $false
        }

        Write-Verbose -Message "Checking if management pack is unsealed"
        if ($ManagementPack.Sealed -eq $true)
        {
            Write-Error -Message "Management pack $ManagementPackName is sealed";
            return $false;
        }
        
        Write-Verbose -Message "Checking Class Exists in MP"
        $ClassExists = $ManagementPack.GetClasses() | ? {$_.Name -eq $ClassName}
        if($ClassExists -ne $null){
            Write-Error -Message "Class $ClassName already exists";
            return $false;
        }
        
        #Adding Base Class Reference
        if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($BaseClassManagemntPackName) -eq $false)){
            $RefStatus = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $BaseClassManagemntPackName -ReferenceManagementPackAlias $BaseClassManagemntPackAlias;
            if ($RefStatus -ne $true)
            {
                Write-Error "Error adding reference mp $defaultReferenceName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $BaseClassManagemntPackAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $BaseClassManagemntPackName;
        }

        # target class
        $targetManagementPack = $null;
        $targetClass = $null;
        $targetManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $BaseClassManagemntPackName;
        $targetClass = $targetManagementPack.GetClass($BaseClassName);
    
        # creating class
        $class = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($ManagementPack, $ClassName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public);
        $class.DisplayName = $ClassDisplayName;
        $class.Description = $ClassDescription;
        $class.Base = $targetClass;
        $class.Singleton = $IsSingleton;
        $class.Abstract = $IsAbstract;
        $class.Hosted = $true;
        $class.Extension = $false;

        foreach ($classPropertyName in $ClassKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $true;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }
        foreach ($classPropertyName in $ClassNonKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $false;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }

        $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
        $ManagementPack.AcceptChanges();

        $GetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ClassName $ClassName
        return $GetClass
    }
    Catch
    {
        $ManagementPack.RejectChanges();
        Write-Error $_.Exception.Message;
        return $false;
    }
}

Function New-MPToolLocalApplicationClass
{
<# 
 .Synopsis
  Creates a new class with from the base class Microsoft.Windows.LocalApplication

 .Description
  Creates a new class with from the base class Microsoft.Windows.LocalApplication

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.Monitoring"
 
 .Parameter -ClassName
  Name of the new class. Example - "Contoso.LocalApp"

 .Parameter -ClassDisplayName
  Display name of the new class. Example - "Contoso LocalApp"

 .Parameter -ClassDescription
  Description of the new class. Example - "Class to Contoso.LocalApp"
 
 .Parameter -ClassKeyProperties
  Array of key properties for the new class. Usually only one key property. Example - @("KeyProp")

 .Parameter -ClassNonKeyProperties
  Array of non-key properties for the new class. Example - @("Prop1","Prop2")

 .Parameter -IsAbstract
  Abstract setting for the class $true / $false. Default is $false
 
 .Parameter -IsSingleton
  Singleton setting for the class $true / $false. Default is $false

 .Example
  # Creates a new abstract class named "Contoso.LocalApp", with one key property "KeyProp" and two non-key properties "Prop1" and "Prop2", in the management pack "Contoso.Monitoring"
  New-MPToolLocalApplicationClass -ManagementServerFQDN scom01.contoso.com ´                                    -ManagementPackName "Contoso.Monitoring" ´                                    -ClassName "Contoso.LocalApp" ´                                    -ClassDisplayName "Contoso LocalApp" ´                                    -ClassDescription "Class to Contoso.LocalApp" ´                                    -ClassKeyProperties @("KeyProp") ´                                    -ClassNonKeyProperties @("Prop1","Prop2") '
                                    -IsAbstract $true -IsSingleton $false
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the class name')][String]$ClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class display name')][String]$ClassDisplayName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class description')][String]$ClassDescription,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class key property names')][array]$ClassKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the non key property names')][array]$ClassNonKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Is Abstract: true/false. Default false')][Boolean]$IsAbstract = $false,
        [Parameter(Mandatory=$false,HelpMessage='Is Singleton: true/false. Default false')][Boolean]$IsSingleton = $false
    )

    try
    {
        Write-Verbose -Message "Running New-MPToolLocalApplicationClass";
        Write-Verbose -Message "Management server: $ManagementServerFQDN";
        Write-Verbose -Message "Management pack: $ManagementPackName";

        $BaseClassName = "Microsoft.Windows.LocalApplication";
        $BaseClassManagemntPackName = "Microsoft.Windows.Library";
        $BaseClassManagemntPackAlias = "Windows";

    
        if($ClassDisplayName -eq "")
        {
            Write-Verbose -Message "Generating class display name";
            $ClassDisplayName = $ClassName.Replace('.',' ');
        }
    
        # connecting
        Write-Verbose -Message "Connecting to $ManagementServerFQDN";
        $ManagementGroup = $null;
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;
        if ($ManagementGroup -eq $null)
        {
            Write-Output $("Error connecting to SCOM management server $ManagementServerFQDN - " + $_.Exception);
            return $false;
        }

        # loading mp
        Write-Verbose -Message "Loading management pack $ManagementPackName";
        $ManagementPack = $null;
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
        if (!($ManagementPack))
        {
            Write-Error "Management pack $ManagementPackName not found";
            return $false
        }

        Write-Verbose -Message "Checking if management pack is unsealed"
            if ($ManagementPack.Sealed -eq $true)
            {
                Write-Error -Message "Management pack $ManagementPackName is sealed";
                return $false;
            }

        Write-Verbose -Message "Checking Class Exists in MP"
        try{
            $ClassExists = $ManagementPack.GetClasses() | ? {$_.Name -eq $ClassName}
        }
        catch{}

        if($ClassExists -ne $null){
            Write-Error -Message "Class $ClassName already exists";
            return $false;
        }    
        
        #Adding Base Class Reference
        Write-Verbose -Message "Adding management pack references";
        if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($BaseClassManagemntPackName) -eq $false)){
            $RefStatus = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $BaseClassManagemntPackName -ReferenceManagementPackAlias $BaseClassManagemntPackAlias;
            if ($RefStatus -ne $true)
            {
                Write-Error "Error adding reference mp $ManagementPackName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
            }
            else
            {
                $BaseClassManagemntPackAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $BaseClassManagemntPackName;
            }

        # Base class
        Write-Verbose -Message "Loading base class";
        $baseClassManagementPack = $null;
        $baseClass = $null;
        $baseClassManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $BaseClassManagemntPackName;
        $baseClass = $baseClassManagementPack.GetClass($BaseClassName);
    
        Write-Verbose -Message "Class name: $ClassName";
        Write-Verbose -Message "Class display name $ClassDisplayName";
        Write-Verbose -Message "Class description: $ClassDescription";
        Write-Verbose -Message "Class key properties: $ClassKeyProperties";
        Write-Verbose -Message "Class non key properties: $ClassNonKeyProperties";

        # creating class
        Write-Verbose -Message "Creating class";
        $class = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($ManagementPack, $ClassName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public);
        $class.DisplayName = $ClassDisplayName;
        $class.Description = $ClassDescription;
        $class.Base = $baseClass;
        $class.Singleton = $IsSingleton;;
        $class.Abstract = $IsAbstract;
        $class.Hosted = $true;
        $class.Extension = $false;

        Write-Verbose -Message "Adding properties to class";
        foreach ($classPropertyName in $ClassKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $true;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }
        foreach ($classPropertyName in $ClassNonKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $false;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }

        Write-Verbose -Message "Saving management pack";
        $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
        $ManagementPack.AcceptChanges();
        
        $GetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ClassName $ClassName
        return $GetClass
    }
    Catch
    {
        
        Write-Error $_.Exception;
        return $false;
    }
}

Function New-MPToolClass
{
<# 
 .Synopsis
  Creates a new class

 .Description
  Creates a new class from a specified base class

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.Monitoring"
 
 .Parameter -ClassName
  Name of the new class. Example - "Contoso.CustomClasss"

 .Parameter -ClassDisplayName
  Display name of the new class. Example - "Contoso CustomClasss"

 .Parameter -ClassDescription
  Description of the new class. Example - "Class to Contoso.CustomClasss"

 .Parameter -BaseClassName
  Name of the base class. Example - "Contoso.Base.Class"

 .Parameter -BaseClassMPName
  Management pack name of the base class. Example - "Contoso.Library"

 .Parameter -BaseClassMPAlias
  Management Pack alias fo the base class. Example - "ContosoLibrary"
 
 .Parameter -ClassKeyProperties
  Array of key properties for the new class. Usually only one key property. Example - @("KeyProp")

 .Parameter -ClassNonKeyProperties
  Array of non-key properties for the new class. Example - @("Prop1","Prop2")

 .Parameter -IsAbstract
  Abstract setting for the class $true / $false. Default is $false
 
 .Parameter -IsSingleton
  Singleton setting for the class $true / $false. Default is $false

 .Example
  # Creates a  class named "Contoso.CustomClasss", with one key property "URL" and two non-key properties "Prop1" and "Prop2", in the management pack "Contoso.Monitoring"
  New-MPToolClass -ManagementServerFQDN scom01.contoso.com ´                                    -ManagementPackName "Contoso.Monitoring" ´                                    -ClassName "Contoso.LocalApp" ´                                    -ClassDisplayName "Contoso LocalApp" ´                                    -ClassDescription "Class to Contoso.LocalApp" ´                                    -BaseClassName "Contoso.Instance.Base"                                    -ClassKeyProperties @("Url") ´                                    -ClassNonKeyProperties @("Prop1","Prop2") '
                                    -IsAbstract $true -IsHosted $true -IsSingleton $false
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the class name')][String]$ClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class display name')][String]$ClassDisplayName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class description')][String]$ClassDescription,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the base class name')][String]$BaseClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the base class name')][String]$BaseClassMPName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the base class name')][String]$BaseClassMPAlias,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the class key property names')][array]$ClassKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the non key property names')][array]$ClassNonKeyProperties,
        [Parameter(Mandatory=$false,HelpMessage='Is Abstract: true/false. Default false')][Boolean]$IsAbstract = $false,
        [Parameter(Mandatory=$false,HelpMessage='Is Hosted: true/false. Default true')][Boolean]$IsHosted = $true,
        [Parameter(Mandatory=$false,HelpMessage='Is Singleton: true/false. Default false')][Boolean]$IsSingleton = $false
    )

    try
    {
        Write-Verbose -Message "Running New-MPToolClass";
        Write-Verbose -Message "Management server: $ManagementServerFQDN";
        Write-Verbose -Message "Management pack: $ManagementPackName";
         
        if($ClassDisplayName -eq "")
        {
            Write-Verbose -Message "Generating class display name";
            $ClassDisplayName = $ClassName.Replace('.',' ');
        }
    
        # connecting
        Write-Verbose -Message "Connecting to $ManagementServerFQDN";
        $ManagementGroup = $null;
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;
        if ($ManagementGroup -eq $null)
        {
            Write-Output $("Error connecting to SCOM management server $ManagementServerFQDN - " + $_.Exception);
            return $false;
        }

        # loading mp
        Write-Verbose -Message "Loading management pack $ManagementPackName";
        $ManagementPack = $null;
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
        if (!($ManagementPack))
        {
            Write-Error "Management pack $ManagementPackName not found";
            return $false
        }

        Write-Verbose -Message "Checking if management pack is unsealed"
            if ($ManagementPack.Sealed -eq $true)
            {
                Write-Error -Message "Management pack $ManagementPackName is sealed";
                return $false;
            }

        Write-Verbose -Message "Checking Class Exists in MP"
        $ClassExists = $ManagementPack.GetClasses() | ? {$_.Name -eq $ClassName}
        if($ClassExists -ne $null){
            Write-Error -Message "Class $ClassName already exists";
            return $false;
        }    
        

        # Get base class class
        Write-verbose -Message "Getting base class: $BaseClassName"
        $baseClass = $null
        try
        {
            $baseClass = $ManagementPack.GetClass($BaseClassName);
        }
        catch {}

        if($baseClass -eq $null)
        {
            if($BaseClassMPName -ne "")
            {
                $baseClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $BaseClassName -ManagementPackName $BaseClassMPName -SealedOnly $true;
            }
            else
            {
                $baseClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $BaseClassName -SealedOnly $true;
            }

            # get base class mp name from class if not piped
            if($BaseClassMPName -eq "")
            {
                $BaseClassMPName = $baseClass.ManagementPackName
                $BaseClassMPAlias = New-MPToolManagementPackAlias $BaseClassMPName
            }

            # add base class mp as reference
            if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($BaseClassMPName) -eq $false)){
            Write-verbose -message "Adding reference for MP: $BaseClassMPName for base class: $baseclass.name"
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $BaseClassMPName -ReferenceManagementPackAlias $BaseClassMPAlias;
                if ($status -ne $true)
                {
                    Write-Error "Error adding reference mp $BaseClassMPName";
                    return $false;
                }
                $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
            }
            else
            {
                $BaseClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $BaseClassMPName;
            }
        }

        if($baseClass -eq $null)
        {
            Write-Error "Base class $BaseClassName not found"
            return $false;
        }
        
          
        Write-Verbose -Message "Class name: $ClassName";
        Write-Verbose -Message "Class display name $ClassDisplayName";
        Write-Verbose -Message "Class description: $ClassDescription";
        Write-Verbose -Message "Class key properties: $ClassKeyProperties";
        Write-Verbose -Message "Class non key properties: $ClassNonKeyProperties";

        # creating class
        Write-Verbose -Message "Creating class";
        $class = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClass($ManagementPack, $ClassName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public);
        $class.DisplayName = $ClassDisplayName;
        $class.Description = $ClassDescription;
        $class.Base = $baseClass;
        $class.Singleton = $IsSingleton;;
        $class.Abstract = $IsAbstract;
        $class.Hosted = $IsHosted;
        $class.Extension = $false;

        Write-Verbose -Message "Adding properties to class";
        foreach ($classPropertyName in $ClassKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $true;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }
        foreach ($classPropertyName in $ClassNonKeyProperties)
        {
            $classProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackClassProperty($class, $classPropertyName);
            $classProperty.DisplayName = $classPropertyName;
            $classProperty.Key = $false;
            $classProperty.Type = "string";
            $class.PropertyCollection.Add($classProperty);
        }

        Write-Verbose -Message "Saving management pack";
        $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
        $ManagementPack.AcceptChanges();
        
        $GetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ClassName $ClassName
        return $GetClass
    }
    Catch
    {
        
        Write-Error $_.Exception;
        return $false;
    }
}

Function Get-MPToolClass
{
<# 
 .Synopsis
  Gets SCOM Class from management server through the SDK

 .Description
  Gets SCOM Class from management server through the SDK.
  Returns object of type [Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -ClassName
  Name of the class. Example - "Contoso.LocalApp"

 .Parameter -ManagementPackName
  (Optional) Name of the management pack to search in. - "Contoso.Monitoring"
  
 .Parameter -SealedOnly
  (Optional) Search only sealed management packs $true / $false. Default is $false

 .Example
  # Searches for the class "Contoso.LocalApp" in management pack "Contoso.Monitoring" and only sealed management packs.
  Get-MPToolClass -ManagementServerFQDN "scom01.contoso.com" -ClassName "Contoso.LocalApp" -ManagementPackName "Contoso.Monitoring" -SealedOnly $true
#>
[CmdletBinding()]
    PARAM
    (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the class name')][String]$ClassName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack name to limit search')][String]$ManagementPackName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter if only sealed management pack are to be searched')][bool]$SealedOnly=$false
    )
    
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;

    if ($ManagementPackName -eq "")
    {
        $ManagementPackName = "%";
    }

    if ($SealedOnly)
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName' AND Sealed='true'");
    }
    else
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName'");
    }

    $sourceMPs = $ManagementGroup.ManagementPacks.GetManagementPacks($criteria);
    
    $class = $null
    foreach ($sourceMP in $sourceMPs)
    {
        try
        {
            [Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]$class = [Microsoft.EnterpriseManagement.Configuration.ManagementPackClass]$sourceMP.GetClass($ClassName);
            return $class;
        }
        catch
        {
        
        }
    }

    return $class;
}
#endregion

#region Module Types #####
##########################

Function Get-MPToolDataSourceModuleType
{
<# 
 .Synopsis
  Gets Data Source Module Type from management server through the SDK

 .Description
  Gets Data Source Module Type from management server through the SDK
  Returns object of type [Microsoft.EnterpriseManagement.Configuration.ManagementPackModuleType]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -DataSourceModuleTypeName
  Name of the Data Source Module Type. Example - "Microsoft.Windows.TimedPowerShell.DiscoveryProvider"

 .Parameter -ManagementPackName
  (Optional) Name of the management pack to search in. Example - "Contoso.library"
  
 .Parameter -SealedOnly
  (Optional) Search only sealed management packs $true / $false. Default is $false

 .Example
  # Searches for the Data Source Module Type "Contoso.LocalApp" and only sealed management packs.
  Get-MPToolDataSourceModuleType -ManagementServerFQDN scom01.contoso.com -DataSourceModuleTypeName "Microsoft.Windows.TimedPowerShell.DiscoveryProvider" -SealedOnly $true
#>
[CmdletBinding()]
    PARAM
    (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the data source module name')][String]$DataSourceModuleTypeName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack name to limit search')][String]$ManagementPackName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter if only sealed management pack are to be searched')][bool]$SealedOnly=$false
    )

    try
    {
    Write-Verbose "Starting Get-MPToolDataSourceModuleType";

    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;

    if ($ManagementPackName -eq "")
    {
        $ManagementPackName = "%";
    }

    if ($SealedOnly)
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName' AND Sealed='true'");
    }
    else
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName'");
    }

    $sourceManagementPack = $null;
    $sourceManagementPacks = $null;
    $sourceManagementPacks = $ManagementGroup.ManagementPacks.GetManagementPacks($criteria);

    foreach ($sourceManagementPack in $sourceManagementPacks)
    {
        try
        {
            [Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModuleType]$dataSourceModuleType = [Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModuleType]$sourceManagementPack.GetModuleType($DataSourceModuleTypeName);
        }
        catch
        {
        }
    }

    return $dataSourceModuleType;
    }
    Catch
    {
        
        Write-Error $_.Exception;
        return $false;
    }
}
     
Function Get-MPToolWriteActionModuleType
{
<# 
 .Synopsis
  Gets Write Action Module Type from management server through the SDK

 .Description
  Gets Write Action Module Type from management server through the SDK
  Returns object of type [Microsoft.EnterpriseManagement.Configuration. ManagementPackWriteActionModuleType]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -ModuleTypeName
  Name of the Write Action Module Type. Example - "System.Health.GenerateAlert"

 .Parameter -ManagementPackName
  (Optional) Name of the management pack to search in. Example - "System.Health.Library"
  
 .Parameter -SealedOnly
  (Optional) Search only sealed management packs $true / $false. Default is $false

 .Example
  # Searches for the Write Action Module Type "System.Health.GenerateAlert" in management pack "System.Health.Library" and only sealed management packs.
  Get-MPToolWriteActionModuleType -ManagementServerFQDN scom01.contoso.com -ManagementPack "System.Health.Library" -ModuleTypeName "System.Health.GenerateAlert" -SealedOnly $SealedOnly
#>
[CmdletBinding()]
    PARAM
    (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the write action module name')][String]$ModuleTypeName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack name to limit search')][String]$ManagementPackName=$null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter if only sealed management pack are to be searched')][bool]$SealedOnly=$false
    )
    
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;
    
    if($ManagementPackName -eq "")
    {
        $ManagementPackName = "%";
    }

    if($SealedOnly)
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName' AND Sealed='true'");
    }
    else
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName'");
    }

    $sourceManagementPack = $null;
    $sourceManagementPacks = $null;
    $sourceManagementPacks = $ManagementGroup.ManagementPacks.GetManagementPacks($criteria);

    foreach ($sourceManagementPack in $sourceManagementPacks)
    {
        try
        {
            [Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModuleType]$writeActionModuleType = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModuleType]$sourceManagementPack.GetModuleType($ModuleTypeName);
        }
        catch
        {
        }
    }
    
    return $writeActionModuleType;
}
#endregion

#region Discoveries #####
##########################

Function New-MPToolPSDiscovery
{
<# 
 .Synopsis
  Create a new PowerShell Discovery

 .Description
  This function will create a new Powershell discovery from a few simple input parameters and script with a array object that contains the discovery class properties. 
  Will also verify or add all need management pack references.

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -ManagementPackName
  Name of the Write Action Module Type. Example - "Contoso.VMSwitch.Discovery"

 .Parameter -DiscoveryName
  Name of the discovery. Example - "Contoso.SCVMM.VMSwitch.Discovery"

 .Parameter -DiscoveryDisplayName
  (Optional) Display name of the discovery. Example - "Contoso SCVMM VMSwitch Discovery"

 .Parameter -DiscoveryClassName
  Name of the class to discover. This is the class to discover. Example - "Contoso.SCVMM.VMSwitch"

 .Parameter -TargetClassName
  (Optional) Target class for the discovery to run on. Example - "Microsoft.SystemCenter.VirtualMachineManager.VMMManagementServer"

 .Parameter -TargetClassMPName
  (Optional) Name of the target class management pack.. Example - "Microsoft.SystemCenter.VirtualMachineManager.Library"

 .Parameter -TargetClassMPAlias
  (Optional) Alias of the target class management pack.. Example - "VMMLibrary"

 .Parameter -IntervalSeconds
  Interval in seconds for the discovery to run. Example - 86000

 .Parameter -TimeoutSeconds
  TimeoutSeconds – Timeout in seconds for the script to timeout. Example - 45

 .Parameter -Script
  PowerShell script for the discovery. This script must create a array object called $DiscoveryObjects with properties matching the properties of the discovery class. 
  Example - @'
            $DiscoveryObjects = @()

            Get-SCVMMServer $env:COMPUTERNAME | Out-Null
            $VMSwitches = Get-SCVirtualNetwork | select Name,VMHost

            foreach($VMSwitch in $VMSwitches){
                $ClassProperties = @{} | select DeviceID,Switchname,VMHost
                $ClassProperties.DeviceID = $VMSwitch.VMHost.ToString()+","+$VMSwitch.Name.ToString()
                $ClassProperties.Switchname = $VMSwitch.Name.ToString()
                $ClassProperties.VMHost = $VMSwitch.VMHost.ToString()

                $DiscoveryObjects += $ClassProperties
            }
            '@

 .Parameter -ScriptParameters
  (Optional) Data Source Parameters??..
  
 .Parameter -Enabled
  (Optional) If the discovery should be enabled - $true/$false – Default: $false

 .Example
  # Creates a new Powershell Discovery called Contoso.SCVMM.VMSwitch.Discovery for the class Contoso.SCVMM.VMSwitch, this class contains properties DeviceID Switchname and VMHost.
  The discovery will run on all instances of the class "Microsoft.SystemCenter.VirtualMachineManager.VMMManagementServer" and discovery all the instances of the Contoso.SCVMM.VMSwitch on the VMM server.
  New-MPToolPSDiscovery -ManagementServerFQDN scom01.contoso.com ´                                            -ManagementPackName "Contoso.VMSwitch.Discovery" ´                                            -DiscoveryName "Contoso.SCVMM.VMSwitch.Discovery" ´                                            -DiscoveryDisplayName "Contoso SCVMM VMSwitch Discovery" ´                                            -DiscoveryClassName "Contoso.SCVMM.VMSwitch" ´                                            -TargetClassName "Microsoft.SystemCenter.VirtualMachineManager.VMMManagementServer" ´                                            -IntervalSeconds "300" ´                                            -TimeoutSeconds "45" ´                                            -Script @'
                                                        $DiscoveryObjects = @()

                                                        Get-SCVMMServer $env:COMPUTERNAME | Out-Null
                                                        $VMSwitches = Get-SCVirtualNetwork | select Name,VMHost

                                                        foreach($VMSwitch in $VMSwitches){
                                                            $ClassProperties = @{} | select DeviceID,Switchname,VMHost
                                                            $ClassProperties.DeviceID = $VMSwitch.VMHost.ToString()+","+$VMSwitch.Name.ToString()
                                                            $ClassProperties.Switchname = $VMSwitch.Name.ToString()
                                                            $ClassProperties.VMHost = $VMSwitch.VMHost.ToString()

                                                            $DiscoveryObjects += $ClassProperties
                                                        }
                                            '@ ´                                            -Enabled $true
#>
[CmdletBinding()]

    PARAM (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the discovery name')][String]$DiscoveryName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the discovery Display Name')][String]$DiscoveryDisplayName=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the discovery class name')][String]$DiscoveryClassName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter target class management pack name')][String]$TargetClassMPName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter target class management pack alias')][String]$TargetClassMPAlias=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the discovery interval')][int]$IntervalSeconds,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the script timeout')][int]$TimeoutSeconds,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the PowerShell script')][String]$Script,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the PowerShell script parameters')][array]$ScriptParameters=$null,
    [Parameter(Mandatory=$false,HelpMessage='Enabled discovery? $true/$false -  Defaut:$false')][boolean]$Enabled=$false
    );

    try{
    $DiscoveryDatasourceTypeIDName = "Microsoft.Windows.TimedPowerShell.DiscoveryProvider"
    $DiscoveryDatasourceTypeIDMPName = "Microsoft.Windows.Library";
    $DiscoveryDatasourceTypeIDMPAlias = "Windows"

$scriptTemplate = @'
param($sourceId, $managedEntityId[PARAMETERS])
    function Write-MOMlog($text)
    {
        $api.LogScriptEvent($Errorprefix + $text,101,1,"")
    }

    $ErrorActionPreference = "Stop"
    try
    {
    $api = New-Object -comObject "MOM.ScriptAPI"

    $Errorprefix = "MPTool Custom Script - [SCRIPTNAME] script error: ";
    $prefix = "MPTool Custom Script - [SCRIPTNAME] script: ";

    $api.LogScriptEvent($prefix + "Started",101,0,"")
    #### Script below his line

    [CUSTOMSCRIPT]

    # $DiscoveryObjects
    #### Script above this line

    $DiscoveryData = $api.CreateDiscoveryData(0, $sourceId, $managedEntityId);
  
    foreach($ObjectInstance in $DiscoveryObjects)
    { 
        $instance = $DiscoveryData.CreateClassInstance("$MPElement[Name='[DISCOVERYCLASSNAME]']$");
        [SCRIPTPROPERTYINSTANCES]
        [HOSTKEYPROPERTY]
    
        $DiscoveryData.AddInstance($instance);
    }

    $api.LogScriptEvent($prefix + "Ended",101,0,"")

    $DiscoveryData
    }
    Catch
    {
        $ErrorMessage = $_.Exception.Message
        Write-MOMlog $ErrorMessage
    }

'@;


    Write-verbose -Message "Adding Input script to script template" 
    $script = $scriptTemplate.Replace("[CUSTOMSCRIPT]",$Script);

Write-verbose -Message "Getting base Configuration" 
[xml]$psDiscoveryConfigXML = '<Configuration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<IntervalSeconds></IntervalSeconds>
          <SyncTime />
          <ScriptName></ScriptName>
          <ScriptBody></ScriptBody>
          <Parameters>
            <Parameter>
              <Name>sourceId</Name>
              <Value>$MPElement$</Value>
            </Parameter>
            <Parameter>
              <Name>managedEntityId</Name>
              <Value>$Target/Id$</Value>
            </Parameter>
          </Parameters>
          <TimeoutSeconds></TimeoutSeconds>
          <StrictErrorHandling>false</StrictErrorHandling>
          </Configuration>';

     [xml]$parameterXmlTemplate = @'
<Config>
<Parameters></Parameters>
</Config>
'@;


    if ($DiscoveryDisplayName -eq "")
    {
        $DiscoveryDisplayName = $DiscoveryName.Replace('.',' ');
    }

    $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    if($ManagementPack -eq $null)
    {
        Write-Error "Management pack $ManagementPackName not found";
        return $false;
    }

    # add Management pack references
    # Verify or add DiscoveryDatasourceTypeIDMPName
    if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($DiscoveryDatasourceTypeIDMPName) -eq $false)){
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $DiscoveryDatasourceTypeIDMPName -ReferenceManagementPackAlias $DiscoveryDatasourceTypeIDMPAlias;
        if ($status -ne $true)
        {
            Write-Error "Error adding reference mp $DiscoveryDatasourceTypeIDMPName";
            return $false;
        }
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    }
    else
    {
        $DiscoveryDatasourceTypeIDMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $DiscoveryDatasourceTypeIDMPName;
    }

    # Verify or add System.Library
    $SystemReferenceMPName = "System.Library";
    $SystemReferenceMPAlias = "System";
    if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($SystemReferenceMPName) -eq $false)){
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $SystemReferenceMPName -ReferenceManagementPackAlias $SystemReferenceMPAlias;
        if ($status -ne $true)
        {
            Write-Error "Error adding reference mp $SystemReferenceMPName";
            return $false;
        }
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    }
    else
    {
        $SystemReferenceMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $SystemReferenceMPName;
    }

    # Get target class
    Write-verbose -Message "Getting target class: $TargetClassName"
    $targetClass = $null
    try
    {
        $targetClass = $ManagementPack.GetClass($TargetClassName);
    }
    catch {}

    if($targetClass -eq $null)
    {
        if($TargetClassMPName -ne "")
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -ManagementPackName $TargetClassMPName -SealedOnly $true;
        }
        else
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -SealedOnly $true;
        }

        # get target mp name from class if not piped
        if($TargetClassMPName -eq "")
        {
            $TargetClassMPName = $targetClass.ManagementPackName;
            $TargetClassMPAlias = New-MPToolManagementPackAlias $TargetClassMPName
        }

        # add target mp as reference
        if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($TargetClassMPName) -eq $false)){
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $TargetClassMPName -ReferenceManagementPackAlias $TargetClassMPAlias;
            if ($status -ne $true)
            {
                Write-Error "Error adding reference mp $TargetClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $TargetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $TargetClassMPName;
        }
    }

    if($targetClass -eq $null)
    {
        Write-Error "Target class $TargetClassName not found"
        return $false;
    }

    #Check if discovery should be enabled.
    if($Enabled -eq $true){
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true;
    }
    else{
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false;
    }

    # Create discovery
    $discovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery($ManagementPack,$DiscoveryName);
    $discovery.Description = $DiscoveryDescription;
    $discovery.DisplayName = $DiscoveryDisplayName;
    $discovery.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal;
    $discovery.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Discovery;
    $discovery.Remotable = $true;
    $discovery.ConfirmDelivery = $false;
    $discovery.Enabled = $SCOMEnabled
    $discovery.Target = $targetClass;
    
    # Adds discovery class
    $DiscoveryClass = $null
    $DiscoveryClassMPName = $null
    $DiscoveryClassMPAlias = $null
    try
    {
        $DiscoveryClass = $ManagementPack.GetClass($DiscoveryClassName);
    }
    catch {}

    if($DiscoveryClass -eq $null)
    {
        $DiscoveryClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $DiscoveryClassName -SealedOnly $true;
        $DiscoveryClassMPName = $DiscoveryClass.ManagementPackName;
        $DiscoveryClassMPAlias = New-MPToolManagementPackAlias $DiscoveryClassMPName

        # add Discovery class mp as reference
        if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($DiscoveryClassMPName) -eq $false)){
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $DiscoveryClassMPName -ReferenceManagementPackAlias $DiscoveryClassMPAlias;
            if ($status -ne $true)
            {
                Write-Error "Error adding reference mp $DiscoveryClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $DiscoveryClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $DiscoveryClassMPName;
        }
    }

    # create discovery class
    $dc = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass;
    $dc.TypeID = $DiscoveryClass;
    foreach ($property in $DiscoveryClass.GetProperties())
    {
        $dcProperty = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClassProperty
        $dcProperty.PropertyID = $property.Name
        $dcProperty.TypeID = $DiscoveryClass;
        $dc.PropertyCollection.Add($dcProperty);
                    
    }
    $discovery.DiscoveryClassCollection.Add($dc)
   
    #Set Script Name
    $ScriptName = $DiscoveryName + "_Script.ps1";

    # Create Add Class Properties section [SCRIPTPROPERTYINSTANCES] for script.
    $scriptClassProperties = $null
    $scriptClassPropertiesTemp = @'
        $instance.AddProperty("$MPElement[Name='[DISCOVERYCLASSNAME]']/[PROPERTYNAME]$",$ObjectInstance.[PROPERTYNAME]);
'@;

    $Property = $null
    foreach($Property in $DiscoveryClass.GetProperties())
    { 
        if ($scriptClassProperties.count -eq 0)
        {
            $scriptClassProperties = $scriptClassPropertiesTemp.Replace("[PROPERTYNAME]",$Property.Name);
        }
        else
        {
            $scriptClassPropertiesNew = $scriptClassPropertiesTemp.Replace("[PROPERTYNAME]",$Property.Name);
            $scriptClassProperties = $scriptClassProperties + ([environment]::NewLine) + $scriptClassPropertiesNew
        }
    }

    $script = $script.Replace("[SCRIPTPROPERTYINSTANCES]",$scriptClassProperties);
    
    
    # Create Host Key Property section [HOSTKEYPROPERTY] and add host key parameters to parameterXmlTemplate
    #Find Host class
    if($DiscoveryClass.Hosted -eq $true){
        Write-Verbose -Message "Searching for host class"
        $HostClass = $null
        $HostClass = $DiscoveryClass.FindHostClass()
        Write-Verbose "Host class is $HostClass"
        
        $HostClassMPName = $null
        $HostClassMPAlias = $null
        $HostClassInMP = $null
        try
        {
            $HostClassInMP = $ManagementPack.GetClass($HostClass.Name);
        }
        catch {}

        # add Host class mp as reference
        write-Verbose -message "Adding Host Class MP"
        if($HostClassInMP -eq $null)
        {
            $HostClassMPName = $HostClass.ManagementPackName;
            $HostClassMPAlias = New-MPToolManagementPackAlias $HostClassMPName

        
            if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($HostClassMPName) -eq $false)){
                $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $HostClassMPName -ReferenceManagementPackAlias $HostClassMPAlias;
                if ($status -ne $true)
                {
                    Write-Error "Error adding reference mp $HostClassMPName";
                    return $false;
                }
                $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
            }
            else
            {
                $HostClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $HostClassMPName;
            }
        }

        $scriptHostKeyProperties = $null
        $HostKeyProperty = $null
        $HostKeyProperty = ($HostClass.PropertyCollection | ? {$_.key -eq $true}).name | select -first 1
        $scriptHostKeyProperties = @'

        #Adding Host ClassProperty
        $instance.AddProperty("$MPElement[Name='[HOSTCLASSMPALIAS][HOSTCLASS]']/[PROPERTYNAME]$",$[PROPERTYNAME])
'@;
        if($HostClassInMP -eq $null){
            $scriptHostKeyProperties = $scriptHostKeyProperties.Replace("[HOSTCLASSMPALIAS]",$HostClassMPAlias+"!")
        }else{
            $scriptHostKeyProperties = $scriptHostKeyProperties.Replace("[HOSTCLASSMPALIAS]","")
        }
            $scriptHostKeyProperties = $scriptHostKeyProperties.Replace("[HOSTCLASS]",$HostClass.Name)
            $scriptHostKeyProperties = $scriptHostKeyProperties.Replace("[PROPERTYNAME]",$HostKeyProperty);   

        $script = $script.Replace("[HOSTKEYPROPERTY]",$scriptHostKeyProperties);
        
        $scriptParamString = $null;
        ##Add Host parameters to script.
        $scriptParamString = ' ,$' + $HostKeyProperty

        ## add Host Parameter to Parameters Section in Configuration
        $classProperty = $null;
        $ElementsReference = $null
        $targetClass.TryGetProperty("$HostKeyProperty", ([ref]$classProperty));

        if ($classProperty -eq $null)
        {
            $ElementsReference = '$Target/Host/Property[Type="[HOSTCLASSMPALIAS][TARGETCLASSNAME]"]/[PROPERTYNAME]$';
        }
        else
        {
            $ElementsReference = '$Target/Property[Type="[HOSTCLASSMPALIAS][TARGETCLASSNAME]"]/[PROPERTYNAME]$';
        }
        $ElementsReference = $ElementsReference.Replace("[TARGETCLASSNAME]",$HostClass);
        $ElementsReference = $ElementsReference.Replace("[PROPERTYNAME]",$HostKeyProperty);
        if($HostClassInMP -eq $null){
        $ElementsReference = $ElementsReference.Replace("[HOSTCLASSMPALIAS]",$HostClassMPAlias+"!")
        }else{
        $ElementsReference = $ElementsReference.Replace("[HOSTCLASSMPALIAS]","")
        }

       
        $node = $parameterXmlTemplate.CreateElement("Parameter");
        $subnode = $parameterXmlTemplate.CreateElement("Name");
        $subnode.InnerText = $HostKeyProperty
        $node.AppendChild($subnode);
        $subnode = $parameterXmlTemplate.CreateElement("Value");
        $subnode.InnerText = $ElementsReference;
        $node.AppendChild($subnode);
        $parameterXmlTemplate.Config.LastChild.AppendChild($node);
    }
    else
    {
        $script = $script.Replace("[HOSTKEYPROPERTY]","");
    }
    
    
    $script = $script.Replace("[SCRIPTNAME]",$ScriptName);
    $script = $script.Replace("[DISCOVERYCLASSNAME]",$discoveryClassName);
      
    foreach ($parameterName in $ScriptParameters)
    {
        if ($scriptParamString -eq $null)
        {
            $scriptParamString = ' ,$' + $parameterName;
        }
        else
        {
            $scriptParamString = $scriptParamString + " ,$" + $parameterName;
        }
    }

    $script = $script.Replace("[PARAMETERS]",$scriptParamString);

    
    # generate parameters section for non host key parameters
    foreach ($parameterName in $ScriptParameters)
    {
        if($parameterName -ne $HostKeyProperty){
            $classProperty = $null;
            $ElementsReference = $null

            #check if target class contains the property
            $targetClass.TryGetProperty("$parameterName", ([ref]$classProperty));

            if ($classProperty -eq $null)
            {
                $ElementsReference = '$Target/Host/Property[Type="[TARGETCLASSNAME]"]/[PROPERTYNAME]$';
            }
            else
            {
                $ElementsReference = '$Target/Property[Type="[TARGETCLASSNAME]"]/[PROPERTYNAME]$';
            }
            $ElementsReference = $ElementsReference.Replace("[TARGETCLASSNAME]",$TargetClassName);
            $ElementsReference = $ElementsReference.Replace("[PROPERTYNAME]",$parameterName);

       
            $node = $parameterXmlTemplate.CreateElement("Parameter");
            $subnode = $parameterXmlTemplate.CreateElement("Name");
            $subnode.InnerText = $parameterName
            $node.AppendChild($subnode);
            $subnode = $parameterXmlTemplate.CreateElement("Value");
            $subnode.InnerText = $ElementsReference;
            $node.AppendChild($subnode);
            $parameterXmlTemplate.Config.LastChild.AppendChild($node);
        }
        else
        {
            Write-Warning -Message "CANNOT ADD $parameterName to parameters section! $parameterName is already used for key property on host class."
        }
    }

    ##Add Parameters to config
    if ($parameterXmlTemplate.Config.Parameters.Length -ne 0)
    {
        foreach ($newNode in $($parameterXmlTemplate.SelectNodes("//Parameter")))
        {
            $psDiscoveryConfigXML.SelectSingleNode("//Parameters").AppendChild($psDiscoveryConfigXML.ImportNode($newNode, $true))
        }
    }
    
    #Finalize data source configuration.
    $psDiscoveryConfigXML.Configuration.IntervalSeconds = $IntervalSeconds.ToString();
    $psDiscoveryConfigXML.Configuration.ScriptName = $ScriptName;
    $psDiscoveryConfigXML.Configuration.ScriptBody = $script;
    $psDiscoveryConfigXML.Configuration.TimeoutSeconds = $TimeoutSeconds.ToString();

    

    # Create DataSource
    $DataSource = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($discovery,"DS");
    try
    {
        $DataSource.TypeID = $ManagementPack.GetModuleType($DiscoveryDatasourceTypeIDName);
    }                                                                    
    Catch {};
    if ($DataSource.TypeID -eq $null)
    {
        $DataSource.TypeID = Get-MPToolDataSourceModuleType -ManagementServerFQDN $ManagementServerFQDN -DataSourceModuleTypeName $DiscoveryDatasourceTypeIDName -ManagementPackName $DiscoveryDatasourceTypeIDMPName -SealedOnly $true;
    }
    if ($DataSource.TypeID -eq $null)
    {
        Write-Error "Type module $DiscoveryDatasourceTypeIDName not found";
        return $false;
    }

    $DataSource.Configuration = $psDiscoveryConfigXML.Configuration.InnerXml;
    $DataSource.Description = "PowerShell discovery data source";
    $DataSource.DisplayName = "DS";
    $discovery.DataSource = $DataSource;

    Write-Verbose -Message "Commiting Changes"
    $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
    $ManagementPack.AcceptChanges([Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackVerificationTypes]::XSDVerification);
 
    return $discovery
    }

    Catch
    {
        Write-Error $_.Exception;
        return $false;
    }
}

Function New-MPToolFilteredRegistryDiscovery
{
<# 
 .Synopsis
  This function will create a new registry discovery

 .Description
  This function will create a new registry discovery. Will also verify or add all need management pack references.
  Returns a object of [Microsoft.EnterpriseManagement.Configuration.ManagementPackElement]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.Discovery"

 .Parameter -DiscoveryName
  Name of the discovery. Example - "Contoso.TimeService.Discovery"

 .Parameter -DiscoveryDisplayName
  (Optional) Display name of the discovery. Example - "Contoso TimeService Discovery"

 .Parameter -DiscoveryClassName
  Name of the class to discover. This is the class to discover. Example - "Contoso.TimeService"

 .Parameter -TargetClassName
  (Optional) Target class for the discovery to run on. Example - "Microsoft.Windows.Computer"

 .Parameter -TargetClassMPName
  (Optional) Name of the target class management pack.. Example - "Microsoft.Windows.Library"

 .Parameter -TargetClassMPAlias
  (Optional) Alias of the target class management pack.. Example - "Windows"

 .Parameter -RegistryPath
  The registry path to discover for. This is the class to discover. Example - "Contoso.TimeService"

 .Parameter -IntervalSeconds
  Interval in seconds for the discovery to run. Example - “SYSTEM\CurrentControlSet\Services\W32Time\”
  
 .Parameter -Enabled
  (Optional) If the discovery should be enabled - $true/$false – Default: $false

 .Example
  # Creates a new registry Discovery called Contoso.Discovery for the class Contoso.TimeService.
  The discovery will run on all instances of the class "Microsoft.Windows.Computer" and discovery all the instances of the Contoso.TimeService on the Windows Computer server.
  New-MPToolFilteredRegistryDiscovery -ManagementServerFQDN scom01.contoso.com ´                                            -ManagementPackName "Contoso.Discovery" ´                                            -DiscoveryName "Contoso.TimeService.Discovery" ´                                            -DiscoveryDisplayName "Contoso TimeService Discovery" ´                                            -DiscoveryClassName "Contoso.TimeService" ´                                            -RegistryPath “SYSTEM\CurrentControlSet\Services\W32Time\” ´                                            -TargetClassName "Microsoft.Windows.Computer" ´                                            -IntervalSeconds 86000 ´                                                                                       -Enabled $true
#>
[CmdletBinding()]
PARAM (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the discovery name')][String]$DiscoveryName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the discovery Display Name')][String]$DiscoveryDisplayName=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the discovery class name')][String]$DiscoveryClassName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the registry path to discover')][string]$RegistryPath,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter target class management pack name')][String]$TargetClassMPName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter target class management pack alias')][String]$TargetClassMPAlias=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the discovery interval')][int]$IntervalSeconds,
    [Parameter(Mandatory=$false,HelpMessage='Enabled discovery? $true/$false -  Defaut:$false')][boolean]$Enabled=$false
    );

    try
    {

    Write-Verbose "New-MPToolFilteredRegistryDiscovery"
    Write-Verbose "Management server: $ManagementServerFQDN"
    Write-Verbose "Management pack name: $ManagementPackName"
    Write-Verbose "Disocvery name: $DiscoveryName"
    Write-Verbose "Discovery class name: $DiscoveryClassName"
    Write-Verbose "Registry path: $RegistryPath"
    Write-Verbose "Target class name: $TargetClassName"
    Write-Verbose "Interval: $IntervalSeconds"

    Write-Verbose "Loading xml config template";
    [xml]$configXML = '<Configuration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<ComputerName></ComputerName>
<RegistryAttributeDefinitions>
<RegistryAttributeDefinition>
<AttributeName></AttributeName>
<Path></Path>
<PathType></PathType>
<AttributeType></AttributeType>
</RegistryAttributeDefinition>
</RegistryAttributeDefinitions>
<Frequency></Frequency>
<ClassId></ClassId>
<InstanceSettings>
<Settings>
<Setting>
</Setting>
</Settings>
</InstanceSettings>
<Expression>
<SimpleExpression>
<ValueExpression>
<XPathQuery Type="String"></XPathQuery>
</ValueExpression>
<Operator></Operator>
<ValueExpression>
<Value Type="String"></Value>
</ValueExpression>
</SimpleExpression>
</Expression>
</Configuration>';

    $DiscoveryDatasourceTypeIDName = "Microsoft.Windows.FilteredRegistryDiscoveryProvider"


    if ($RegistryPath.Contains("HKEY_LOCAL_MACHINE"))
    {
        $RegistryPath = $RegistryPath.Replace("HKEY_LOCAL_MACHINE\","");
    }

 
    Write-Verbose "Creating discovery display name if not defined";
    if ($DiscoveryDisplayName -eq $null)
    {
        $DiscoveryDisplayName = $DiscoveryName.Replace('.',' ');
    }

    $ManagementPack = $null;
    $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    if (!($ManagementPack))
    {
        Write-Error "Management pack $ManagementPackName not found";
        return $false;
    }

    # add System.Library MP references
    Write-Verbose "Adding management pack references";
    $SystemReferenceMPName = "System.Library";
    $SystemReferenceMPAlias = "System";

    if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($SystemReferenceMPName) -eq $false)){
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $SystemReferenceMPName -ReferenceManagementPackAlias $SystemReferenceMPAlias;
        if ($status -ne $true)
        {
            Write-Error "Error adding reference mp $SystemReferenceMPName";
            return $false;
        }
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    }
    else
    {
        $SystemReferenceMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $SystemReferenceMPName;
    }
    
    # add Data source Type MP references 
    $DiscoveryDatasourceTypeIDMPName = "Microsoft.Windows.Library";
    $DiscoveryDatasourceTypeIDMPAlias = "Windows";

    if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($DiscoveryDatasourceTypeIDMPName) -eq $false)){
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $DiscoveryDatasourceTypeIDMPName -ReferenceManagementPackAlias $DiscoveryDatasourceTypeIDMPAlias;
        if ($status -ne $true)
        {
            Write-Error "Error adding reference mp $DiscoveryDatasourceTypeIDMPName";
            return $false;
        }
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    }
    else
    {
        $DiscoveryDatasourceTypeIDMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $DiscoveryDatasourceTypeIDMPName;
    }
    

    # Get target class
    $targetClass = $null
    Write-Verbose "Loading target class";
    try
    {
        $targetClass = $ManagementPack.GetClass($TargetClassName);
    }
    catch {}

    if ($targetClass -eq $null)
    {
        if($TargetClassMPName -eq "")
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -SealedOnly $true;
        }
        else
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -ManagementPackName $TargetClassMPName -SealedOnly $true;
        }
    
        # get target mp name from class if not piped
        Write-Verbose "Resolving target class management pack name";
        if($TargetClassMPName -eq "")
        {
            $TargetClassMPName = $targetClass.ManagementPackName;
            $TargetClassMPAlias = New-MPToolManagementPackAlias $TargetClassMPName
        }

        # add target mp as reference
        Write-Verbose "Adding target class management pack reference";
        if (($ManagementPack.References.Values.name.Contains($TargetClassMPName) -eq $false))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $TargetClassMPName -ReferenceManagementPackAlias $TargetClassMPAlias;
            if (!($status))
            {
                Write-Error "Error adding reference mp $TargetClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $TargetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $TargetClassMPName;
        }
    }

    if ($targetClass -eq $null)
    {
        Write-Error "Target class $TargetClassName not found"
        return $false;
    }


    


    # Get discovery class
    Write-Verbose "Loading discovery class";
    $DiscoveryClass = $null;
    try
    {
        $DiscoveryClass = $ManagementPack.GetClass($DiscoveryClassName);
    }
    catch {}
    if ($DiscoveryClass -eq $null)
    {
        $DiscoveryClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $DiscoveryClassName -SealedOnly $true;

        # add discovery Class mp as reference
        $DiscoveryClassMPName = $DiscoveryClass.ManagementPackName;
        $DiscoveryClassMPAlias = New-MPToolManagementPackAlias $DiscoveryClassMPName

        Write-Verbose "Adding target class management pack reference";
        if (($ManagementPack.References.Values.name.Contains($DiscoveryClassMPName) -eq $false))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $DiscoveryClassMPName -ReferenceManagementPackAlias $DiscoveryClassMPAlias;
            if (!($status))
            {
                Write-Error "Error adding reference mp $DiscoveryClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $DiscoveryClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $DiscoveryClassMPName;
        }
    }

    if ($DiscoveryClass -eq $null)
    {
        Write-Error "Discovery class $DiscoveryClassName not found"
        return $false;
    }
     

    # create discovery class
    Write-Verbose "Creating discovery class object";
    $dc = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscoveryClass;
    $dc.TypeID = $DiscoveryClass;


    # manipulate XML configuration
    Write-Verbose "Creating xml configuration";
    $settingName1 = '$MPElement[Name="Windows!Microsoft.Windows.Computer"]/PrincipalName$'
    if ($targetClass.Hosted)
    {
        $settingValue1 = '$Target/Host/Property[Type="Windows!Microsoft.Windows.Computer"]/PrincipalName$'
    }
    else
    {
        $settingValue1 = '$Target/Property[Type="Windows!Microsoft.Windows.Computer"]/PrincipalName$'
    }

    $settingName2 = '$MPElement[Name="System!System.Entity"]/DisplayName$'
    if ($targetClass.Hosted)
    {
        $settingValue2 = '$Target/Host/Property[Type="Windows!Microsoft.Windows.Computer"]/NetworkName$'
    }
    else
    {
        $settingValue2 = '$Target/Property[Type="Windows!Microsoft.Windows.Computer"]/NetworkName$'
    }

    [xml]$settingXML1 = @'
<SettingsNode>
<Setting>
<Name></Name>
<Value></Value>
</Setting>
</SettingsNode>
'@;
    $settingXML1.SettingsNode.Setting.Name = $settingName1;
    $settingXML1.SettingsNode.Setting.Value = $settingValue1;

    [xml]$settingXML2 = @'
<SettingsNode>
<Setting>
<Name></Name>
<Value></Value>
</Setting>
</SettingsNode>
'@;
    $settingXML2.SettingsNode.Setting.Name = $settingName2;
    $settingXML2.SettingsNode.Setting.Value = $settingValue2


    Foreach ($Node in $settingXML2.DocumentElement.ChildNodes) {
        $settingXML1.DocumentElement.AppendChild($settingXML1.ImportNode($Node, $true)) | Out-Null
    }

    [xml]$SimpleExpression = @'
<Node>
<ValueExpression>
  <XPathQuery Type="String">Values/KeyExist</XPathQuery> 
  </ValueExpression>
  <Operator>Equal</Operator> 
<ValueExpression>
  <Value Type="String">true</Value> 
  </ValueExpression>
</Node>
'@;



    if ($targetClass.Hosted)
    {
        $configXMLComputer = '$Target/Host/Property[Type="Windows!Microsoft.Windows.Computer"]/NetworkName$'
    }
    else
    {
        $configXMLComputer = '$Target/Property[Type="Windows!Microsoft.Windows.Computer"]/NetworkName$'
    }
    $ConfigXML.Configuration.ComputerName = $configXMLComputer
    $ConfigXML.Configuration.RegistryAttributeDefinitions.RegistryAttributeDefinition.AttributeName = "KeyExist";
    $ConfigXML.Configuration.RegistryAttributeDefinitions.RegistryAttributeDefinition.Path = $RegistryPath;
    $ConfigXML.Configuration.RegistryAttributeDefinitions.RegistryAttributeDefinition.PathType = "0";
    $ConfigXML.Configuration.RegistryAttributeDefinitions.RegistryAttributeDefinition.AttributeType = "0";
    $ConfigXML.Configuration.Frequency = $IntervalSeconds.ToString();
    $ConfigXML.Configuration.ClassId = '$MPElement[Name="' + $DiscoveryClassName + '"]$';
    $ConfigXML.Configuration.InstanceSettings.Settings.InnerXml = $settingXML1.SettingsNode.InnerXml;
    $ConfigXML.Configuration.Expression.SimpleExpression.InnerXml = $SimpleExpression.Node.InnerXml;


    # Create discovery
    Write-Verbose "Creating discovery";
    $discovery = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDiscovery($ManagementPack,$DiscoveryName);

    # create type module
    Write-Verbose "Creating datasource module type"
    $ds = $null;
    $ds = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule ($discovery,"DS");
    try
    {
        $ds.TypeID = $ManagementPack.GetModuleType($DiscoveryDatasourceTypeIDName);
    }                                                                    
    Catch {};
    if ($ds.TypeID -eq $null)
    {
        $ds.TypeID = Get-MPToolDataSourceModuleType -ManagementServerFQDN $ManagementServerFQDN -DataSourceModuleTypeName $DiscoveryDatasourceTypeIDName -ManagementPackName $DiscoveryDatasourceTypeIDMPName -SealedOnly $true;
    }
    if ($ds.TypeID -eq $null)
    {
        Write-Error "Type module $DiscoveryDatasourceTypeIDName not found";
        return $false;
    }

    $ds.Configuration = $ConfigXML.Configuration.InnerXml;
    $ds.Description = "Discovery data source";
    $ds.DisplayName = "DS";

    #Check if discovery should be enabled.
    if($Enabled -eq $true){
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true;
    }
    else{
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false;
    }


    # configure discovery
    Write-Verbose -Message "Configure discovery";
    $discovery.Description = $DiscoveryDescription;
    $discovery.DisplayName = $DiscoveryDisplayName;
    $discovery.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal;
    $discovery.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Discovery;
    $discovery.Remotable = $true;
    $discovery.ConfirmDelivery = $false;
    $discovery.Enabled = $SCOMEnabled
    $discovery.Target = $targetClass;
    $discovery.DiscoveryClassCollection.Add($dc);
    $discovery.DataSource = $ds;
         
    Write-Verbose -Message "Saving management pack";
    $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
    $ManagementPack.AcceptChanges();
    return $discovery;
}
Catch
{
   Write-Error $_.Exception;
   return $false; 
}
}
#endregion

#region Monitors #####
######################

Function Get-MPToolMonitor
{
[CmdletBinding()]
    PARAM
    (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor name')][String]$MonitorName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor type')][ValidateSet('ManagementPackAggregateMonitor', 'ManagementPackUnitMonitor')][String]$MonitorType,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack name to limit search')][String]$ManagementPackName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter if only sealed management pack are to be searched')][bool]$SealedOnly=$false
    )
    
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;
    
    if (!($ManagementPackName))
    {
        $ManagementPackName = "%";
    }

    if ($SealedOnly)
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName' AND Sealed='true'");
    }
    else
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName'");
    }

    $sourceMP = $null;
    $sourceMPs = $null;
    $sourceMPs = $ManagementGroup.ManagementPacks.GetManagementPacks($criteria);

    foreach ($sourceMP in $sourceMPs)
    {
        try
        {
            switch ($MonitorType)
            {
                "ManagementPackAggregateMonitor" {
                [Microsoft.EnterpriseManagement.Configuration.ManagementPackAggregateMonitor]$monitor = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAggregateMonitor]$sourceMP.GetMonitor($MonitorName); break;
                }
                "ManagementPackUnitMonitor" {
                [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor]$monitor = [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor]$sourceMP.GetMonitor($MonitorName); break;
                }
            }
        }
        catch
        {
        }
    }

    return $monitor;
}

Function Get-MPToolUnitMonitorType
{
<# 
 .Synopsis
  Gets SCOM Unit Monitor Type from management server through the SDK

 .Description
  Gets SCOM Unit Monitor Type from management server through the SDK.
  Returns object of type [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorType]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -UnitMonitorTypeName
  Name of the unit monitor type. Example - "Microsoft.Windows.CheckNTServiceStateMonitorType"

 .Parameter -ManagementPackName
  (Optional) Name of the management pack to search in. - "Contoso.Library"
  
 .Parameter -SealedOnly
  (Optional) Search only sealed management packs $true / $false. Default is $false

 .Example
  # Searches for the Unit Monitor Type "Microsoft.Windows.CheckNTServiceStateMonitorType" and only sealed management packs.
  Get-MPToolUnitMonitorType -ManagementServerFQDN "scom01.contoso.com" -UnitMonitorTypeName "Microsoft.Windows.CheckNTServiceStateMonitorType" -SealedOnly $true
#>
    [CmdletBinding()]
    PARAM
    (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the data source module name')][String]$UnitMonitorTypeName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the management pack name to limit search')][String]$ManagementPackName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter if only sealed management pack are to be searched')][Boolean]$SealedOnly=$false
    )

    $mg = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN;

    if (!($ManagementPackName))
    {
        $ManagementPackName = "%";
    }
    if ($SealedOnly)
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName' AND Sealed='true'");
    }
    else
    {
        $criteria = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackCriteria("Name like '$ManagementPackName'");
    }
    $sourceMP = $null;
    $sourceMPs = $null;
    $sourceMPs = $mg.ManagementPacks.GetManagementPacks($criteria);

    foreach ($sourceMP in $sourceMPs)
    {
    
        try
        {
            [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorType]$unitMonitorType = [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorType]$sourceMP.GetUnitMonitorType($UnitMonitorTypeName);
            break;
        }
        catch
        {
        
        }
    }
    return $unitMonitorType;
}

Function New-MPToolPSStateMonitor
{
<# 
 .Synopsis
  Creates SCOM PowerShell three state monitor for availability State

 .Description
  Creates SCOM PowerShell three state monitor for availability State. 
  The monitor will get create auto resolving alerts that match monitor health. 
  The alert message can be definded in the script using $scomMessage variable.
  Returns object of type [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorType]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.VMSwitch.Monitoring”

 .Parameter -MonitorName 
  Name of the monitor. Example - "Contoso.VMSwitch.Monitor”
  
 .Parameter -MonitorDisplayName 
  (Optional) Display name of the monitor. Example - "Contoso VMSwitch Monitor”

 .Parameter -MonitorDescription 
  (Optional) Description of the monitor. Example - "Monitor for VM compliance in vmm logical switches”

 .Parameter -TargetClassName 
  Name of the target class. Example - "Contoso.SCVMM.VMSwitch”

 .Parameter -TargetClassMPName 
  (Optional) Name of the management pack for the target class. Example – “Contoso.SCVMM.Discovery”

 .Parameter -TargetClassMPAlias 
  (Optional) Alias for the management pack for the target class. Example – “ContosoVMMDiscovery”

 .Parameter -IntervalSeconds 
  Monitor interval. Example - 86000

 .Parameter -TimeoutSeconds 
  Script Timeout. Example - 45

 .Parameter -Script 
  PowerShell script for the monitor.Example - @'
                                                Get-SCVMMServer $env:COMPUTERNAME | Out-Null 

                                                $Status = get-scvirtualnetwork | ? {($_.Name -eq $Switchname) -and ($_.VMhost.ToString() -eq $VMHost)}
                                                if ($Status.LogicalSwitchComplianceStatus -eq "Compliant")
                                                {
                                                    $scomState = "OK";
                                                }
                                                else
                                                {
                                                    $scomState = "ERROR";
                                                }
                                                $scomMessage = $SwitchName + " Status: " + $Status.LogicalSwitchComplianceStatus;
                                                '@

 .Parameter -ScriptParameters 
  (Optional) Script input parameters is used to get property values from the target class or the target class’s host. Example - @("Switchname","VMHost")

 .Parameter -Enabled 
  (Optional) Enabled setting for the monitor $true / $false. Default is $false

 .Example
  # Creates a powershell state monitor for the target class "Contoso.SCVMM.VMSwitch” in the management pack "Contoso.VMSwitch.Monitoring”.
  # The Monitor will check the Logical Switch Compliance Status for the instance of the target class. If not compliant and alert is created with critical severity
  New-MPToolPSStateMonitor -ManagementServerFQDN scom01.contoso.com ´    -ManagementPackName "Contoso.VMSwitch.Monitoring” ´    -MonitorName "Contoso.VMSwitch.Monitor” ´    -TargetClassName "Contoso.SCVMM.VMSwitch” ´    -IntervalSeconds 86000 ´    -TimeoutSeconds 45 ´    -Script @'
            Get-SCVMMServer $env:COMPUTERNAME | Out-Null 
    
            $Status = get-scvirtualnetwork | ? {($_.Name -eq $Switchname) -and ($_.VMhost.ToString() -eq $VMHost)}
            if ($Status.LogicalSwitchComplianceStatus -eq "Compliant")
            {
                $scomState = "OK";
            }
            else
            {
                $scomState = "ERROR";
            }
            $scomMessage = $SwitchName + " Status: " + $Status.LogicalSwitchComplianceStatus;
'@´    -ScriptParameters @("Switchname","VMHost") ´    -Enabled $true
#>
[CmdletBinding()]
PARAM (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the mangementpack name')][String]$ManagementPackName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor name')][String]$MonitorName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor display name')][String]$MonitorDisplayName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor description name')][String]$MonitorDescription=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP name')][String]$TargetClassMPName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP alias')][String]$TargetClassMPAlias=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor interval')][int]$IntervalSeconds,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor timeout')][int]$TimeoutSeconds,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitoring script')][String]$Script,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the script parameters')][array]$ScriptParameters=$null,
    [Parameter(Mandatory=$false,HelpMessage='Enabled Monitor? $true/$false -  Defaut:$false')][boolean]$Enabled=$false
    );

    $PowershellMonitorMPName = "MPTool.Powershell.Modules";
    $PowershellMonitorMPAlias = "MPToolPowerShell"
    $unitMonitorTypeName = "MPTool.Powershell.Modules.ScheduledScript.ModuleType";

    # config template
    [xml]$configXml = @'
<Configuration>
  <IntervalSeconds></IntervalSeconds>
  <SyncTime></SyncTime>
  <ScriptName></ScriptName>
  <ScriptBody></ScriptBody>
  <Parameters></Parameters>
  <TimeoutSeconds></TimeoutSeconds>
</Configuration>
'@;

    # script template
    $scriptTemplate = @'
Param([PARAMETERS])
function Write-MOMlog($text)
{
    $api.LogScriptEvent($Errorprefix + $text,103,1,"")
}
$Errorprefix = "MPTool Custom Script - [SCRIPTNAME] script error: ";
$prefix = "MPTool Custom Script - [SCRIPTNAME] script: ";

$ErrorActionPreference = "Stop"
try
{
    $api = New-Object -comObject "MOM.ScriptAPI";
    $api.LogScriptEvent($prefix + "Started",103,0,"")
    ###Script HERE###

    [CUSTOMSCRIPT]

    ###Script HERE###
    $api.LogScriptEvent($prefix + "Ended",103,0,"")
}
catch
{
    $ErrorMessage = $_.Exception.Message
    Write-MOMlog $ErrorMessage
    $scomState = "Error";
    $scomMessage = "Monitor failed to execute with the following error `n" + $_.Exception.Message.ToString(); "`n `n This error could be and error in the monitoring script."
}
Finally
{
    $bag = $api.CreatePropertyBag();
    $bag.AddValue("State",$scomState);
    $bag.AddValue("Message",$scomMessage);
    $bag;
}
'@;

$ErrorActionPreference = "Stop";
try
   {
    
    # set display name
    if($MonitorDisplayName -eq "")
    {
        $MonitorDisplayName = $MonitorName.Replace('.',' ');
    }

    # connect to management group
    $ManagementGroup = $null;
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN
    
    # loading management pack
    $ManagementPack = $null;
    $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    if ($ManagementPack -eq $null)
    {
        Write-Error "Management pack $ManagementPackName not found"
        return $false;
    }

    #Check if monitor name exists
    $MonitorExists = $null
    try{
        $MonitorExists = $ManagementPack.GetMonitor($MonitorName)
    }
    catch{}
    if($MonitorExists -ne $null){
        Write-error -Message  "Monitor $MonitorName Already Exsist!"
    }

    # adding references
    Write-Verbose -Message "Checking or addding references for $PowershellMonitorMPName MP"
    if (($ManagementPack.References.Count -eq 0) -or (!($ManagementPack.References.Values.name.Contains($PowershellMonitorMPName))))
    {
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $PowershellMonitorMPName -ReferenceManagementPackAlias $PowershellMonitorMPAlias;
        if ($status -eq $null)
        {
            Write-Error "Error adding reference mp $PowershellMonitorMPName";
            return $false;
        }
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    }
    else
    {
        $PowershellMonitorMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $PowershellMonitorMPName;
    }
     

    # create monitor
    Write-Verbose -Message "Building Monitor $MonitorName"
    [Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor]$monitor = $null
    $monitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($ManagementPack,$MonitorName,[Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Internal);
    
    # target class
    # Get target class
    $targetClass = $null
    Write-Verbose "Loading target class";
    try
    {
        $targetClass = $ManagementPack.GetClass($TargetClassName);
    }
    catch {}
    if ($targetClass -eq $null)
    {
        if($TargetClassMPName -eq "")
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -SealedOnly $true;
        }
        else
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -ManagementPackName $TargetClassMPName -SealedOnly $true;
        }
    
        # get target mp name from class if not piped
        Write-Verbose "Resolving target class management pack name";
        if($TargetClassMPName -eq "")
        {
            $TargetClassMPName = $targetClass.ManagementPackName;
            $TargetClassMPAlias = New-MPToolManagementPackAlias $TargetClassMPName
        }

        # add target mp as reference
        Write-Verbose "Adding target class management pack reference";
        if (($ManagementPack.References.Values.name.Contains($TargetClassMPName) -eq $false))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $TargetClassMPName -ReferenceManagementPackAlias $TargetClassMPAlias;
            if (!($status))
            {
                Write-Error "Error adding reference mp $TargetClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $TargetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $TargetClassMPName;
        }
    }

    if ($targetClass -eq $null)
    {
        Write-Error "Target class $TargetClassName not found"
        return $false;
    }


    # create Script block in configuration [CUSTOMSCRIPT]
    $Monitorscript = $scriptTemplate.Replace("[CUSTOMSCRIPT]",$Script);
    $Monitorscript = $Monitorscript.Replace("[SCRIPTNAME]",$($MonitorName.Replace('.','_') + ".ps1"));


    #create PARAMETERS in Script block in configuration [CUSTOMSCRIPT]
    $scriptParamString = $null;;
    foreach ($parameterName in $ScriptParameters)
    {
        if ($scriptParamString -eq $null)
        {
            $scriptParamString = '$' + $parameterName;
        }
        else
        {
            $scriptParamString = $scriptParamString + ",$" + $parameterName;
        }
    }
    $Monitorscript = $Monitorscript.Replace("[PARAMETERS]",$scriptParamString);
    
     [xml]$parameterXml = @'
<Config>
<Parameters></Parameters>
</Config>
'@;

    #create PARAMETERS in configuration
    foreach ($parameterName in $ScriptParameters)
    {
        $classProperty = $null;
        $PropertyClass = $null
        $targetClass.TryGetProperty("$parameterName", ([ref]$classProperty));
       
        # value syntax
        if ($classProperty -eq $null)
        {
            $ElementsReference = '$Target/Host/Property[Type="[CLASSNAME]"]/[PROPERTYNAME]$';
            $PropertyClass = $targetClass.FindHostClass()
        }
        else
        {
            $ElementsReference = '$Target/Property[Type="[CLASSNAME]"]/[PROPERTYNAME]$';
            $PropertyClass = $TargetClass
        }
        $ElementsReference = $ElementsReference.Replace("[CLASSNAME]",$PropertyClass.Name);
        $ElementsReference = $ElementsReference.Replace("[PROPERTYNAME]",$parameterName);

        $node = $parameterXml.CreateElement("Parameter");
        $subnode = $parameterXml.CreateElement("Name");
        $subnode.InnerText = $parameterName
        $node.AppendChild($subnode);
        $subnode = $parameterXml.CreateElement("Value");
        $subnode.InnerText = $ElementsReference;
        $node.AppendChild($subnode);
        $parameterXml.Config.LastChild.AppendChild($node);        
    }
    
    if ($ScriptParameters -ne $null)
    {
        foreach ($newNode in $($parameterXml.SelectNodes("//Parameter")))
        {
            $configXml.SelectSingleNode("//Parameters").AppendChild($configXml.ImportNode($newNode, $true))
        }
    }
    

    #Combine XML Configuration block
    $configXml.Configuration.TimeoutSeconds = $TimeoutSeconds.ToString();
    $configXml.Configuration.ScriptBody = $Monitorscript;
    $configXml.Configuration.ScriptName = $($MonitorName.Replace('.','_') + ".ps1");
    $configXml.Configuration.IntervalSeconds = $IntervalSeconds.ToString();


    # parent monitor
    $parentMonitor = $null;
    try
    {
        [Microsoft.EnterpriseManagement.Configuration.ManagementPackAggregateMonitor]$parentMonitor = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAggregateMonitor]$ManagementPack.GetMonitor("System.Health.AvailabilityState");
    }
    Catch{};

    if ($parentMonitor -eq $null)
    {
        $parentMonitor = Get-MPToolMonitor -ManagementServerFQDN $ManagementServerFQDN -MonitorName "System.Health.AvailabilityState" -MonitorType "ManagementPackAggregateMonitor";
    }

    # monitor type id
    $monitorType = $null;
    try
    {
        $monitorType = $ManagementPack.GetUnitMonitorType($unitMonitorTypeName);
    }
    Catch {};
    if ($monitorType -eq $null)
    {
        $monitorType = Get-MPToolUnitMonitorType -ManagementServerFQDN $ManagementServerFQDN -UnitMonitorTypeName $unitMonitorTypeName;
    }

    if ($monitorType -eq $null)
    {
        Write-Error "Unable to find unit monitor type $unitMonitorTypeName";
        return $false;
    }

    # configure health states
    $healthyState = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($monitor, "Success");
    $warningState = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($monitor, "Warning");
    $errorState = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($monitor, "Error");
    $healthyState.HealthState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Success;
    $warningState.HealthState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Warning;
    $errorState.HealthState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Error;
    $healthyState.MonitorTypeStateID = "OKState";
    $warningState.MonitorTypeStateID = "WarningState";
    $errorState.MonitorTypeStateID = "ErrorState";

    # configure alert settings
    $alertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings;
    $alertSettings.AlertOnState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Error;
    $alertSettings.AutoResolve = $true;
    $alertSettings.AlertSeverity = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAlertSeverity]::MatchMonitorHealth;
    $alertSettings.AlertPriority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal;
    $alertSettings.AlertParameter1 = '$Data/Context/Property[@Name=''Message'']$'

    $alertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($ManagementPack, $($MonitorName + ".Alert"));
    $alertMessage.DisplayName = "$MonitorDisplayName Alert";
    $alertMessage.Description = "Alert Message: {0}"
    
    $alertSettings.AlertMessage = $alertMessage;


    $SCOMEnabled = $null
    if($Enabled -eq $true)
    {
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true;
    }
    else{
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false;
    }

    # configure monitor   
    $monitor.DisplayName = $MonitorDisplayName;
    $monitor.Description = $MonitorDescription;
    $monitor.Target = $targetClass;
    $monitor.Enabled = $SCOMEnabled
    $monitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::AvailabilityHealth;
    $monitor.ParentMonitorID = $parentMonitor;
    $monitor.TypeID = $monitorType;
    $Monitor.AlertSettings = $alertSettings;
    $monitor.Configuration = $configXml.Configuration.InnerXml;
    $monitor.OperationalStateCollection.Add($healthyState);
    $monitor.OperationalStateCollection.Add($warningState);
    $monitor.OperationalStateCollection.Add($errorState);



    # saving mp
    $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
    $ManagementPack.AcceptChanges([Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackVerificationTypes]::XSDVerification);

    $GetMonitor = Get-MPToolMonitor -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -MonitorName $MonitorName -MonitorType ManagementPackUnitMonitor
    return $GetMonitor;
 }
    Catch
    {
       Write-Error $_.Exception
       return $false;
   }
}

Function New-MPToolWindowsServiceMonitor
{
<# 
 .Synopsis
  Creates a new Windows service monitor.
 
 .Description
  Creates a new Windows service monitor.

 .Parameter -ManagementServerFQDN
  Management Server FQDN - Example: SCOM01.contoso.com

 .Parameter -ManagementPackName
  Management Pack Name for the Monitor - Example: Contoso.Service.MP

 .Parameter -MonitorName
  Monitor Name - Example: W32time.WindowsService.Monitor

 .Parameter -MonitorDisplayName
  (Optional) Monitor display name - Example: "W32time WindowsService Monitor"
 
 .Parameter -MonitorDescription
  (Optional) Monitor description - Example: "Windows Service Monitor for the class W32time.WindowsService"

 .Parameter -TargetClassName
  Monitor Target Class Name - Example: W32time.WindowsService

 .Parameter -TargetClassMPName
  (Optional) Target Class Management Pack Name - Example: Contoso.Service.Discovery

 .Parameter -TargetClassMPAlias
  (Optional) Target Class Management Pack Alias - Example: ContosoSvcDiscovery

 .Parameter -UnhealthyState
  The unhealthy state of the monitor. Possible Values: Warning, Error.

 .Parameter -ServiceName
  The name of the service that needs to be monitored. Please specify the service name, not the display name. Example: W32time

 .Example
  # Creates a new windows service monitor for the target class W32time.Windowsservice, will monitor if service W32Time is running or not and create a critical error if not.
  New-MPToolWindowsServiceMonitor -ManagementServerFQDN SCOMMS01.contoso.com ´                -ManagementPackName Contoso.Service.MP ´                -MonitorName W32time.WindowsService.Monitor ´                -TargetClassName W32time.WindowsService ´                -UnhealthyState Error -ServiceName W32Time
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor name')][String]$MonitorName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor display name')][String]$MonitorDisplayName=$null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor description name')][String]$MonitorDescription=$null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP name')][String]$TargetClassMPName=$null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP alias')][String]$TargetClassMPAlias=$null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter Monitor Unhealthy State')][ValidateSet('Warning', 'Error')][String]$UnhealthyState,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the Service Name')][String]$ServiceName
      )


    try
    {
    Write-Verbose -Message "New-MPToolWindowsServiceMonitor";
    Write-Verbose -Message "Management server: $ManagementServerFQDN";
    Write-Verbose -Message "Management pack name: $ManagementPackName";
    Write-Verbose -Message "Monitor name: $MonitorName";
    Write-Verbose -Message "Target class: $TargetClassName";
    Write-Verbose -Message "Unhealthy state: $UnhealthyState";
    Write-Verbose -Message "Service name: $ServiceName";

    # set display name
    if($MonitorDisplayName -eq "")
    {
        $MonitorDisplayName = $MonitorName.Replace('.',' ');
    }
    
    [xml]$ConfigurationTemp = '<Configuration>
                                    <ComputerName>$Target/Host/Property[Type="Windows!Microsoft.Windows.Computer"]/NetworkName$</ComputerName>
                                    <ServiceName></ServiceName>
                                    <CheckStartupType />
                               </Configuration>'
    $ConfigurationTemp.Configuration.ServiceName = $ServiceName


    # connecting
    Write-Verbose -Message "Getting SCOM management Server Connection"
    $ManagementGroup = $null;
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;
    if ($ManagementGroup -eq $null)
    {
        Write-Output "Error connecting to SCOM management server $ManagementServerFQDN";
        return $false;
    }

    # loading mp
    Write-Verbose -Message "Getting management pack"
    $ManagementPack = $null;
    $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
    if (!($ManagementPack))
    {
        Write-Error "Management pack $ManagementPackName not found";
        return $false
    }

    #Add References
    Write-Verbose -Message "Checking and adding references"
    if ($ManagementPack.References.Count -eq 0)
    {
        Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName "Microsoft.Windows.Library" -ReferenceManagementPackAlias "Windows";
        Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName "System.Health.Library" -ReferenceManagementPackAlias "SystemHealth";
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName

    }
    if (!($ManagementPack.References.Values.name.Contains("Microsoft.Windows.Library")))
    {
        Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName "Microsoft.Windows.Library" -ReferenceManagementPackAlias "Windows";
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName

    }
    if (!($ManagementPack.References.Values.name.Contains("System.Health.Library")))
    {
        Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName "System.Health.Library" -ReferenceManagementPackAlias "SystemHealth";
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName

    }


    # target class
    # Get target class
    $targetClass = $null
    Write-Verbose "Loading target class";
    try
    {
        $targetClass = $ManagementPack.GetClass($TargetClassName);
    }
    catch {}
    if ($targetClass -eq $null)
    {
        if($TargetClassMPName -eq "")
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -SealedOnly $true;
        }
        else
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -ManagementPackName $TargetClassMPName -SealedOnly $true;
        }
    
        # get target mp name from class if not piped
        Write-Verbose "Resolving target class management pack name";
        if($TargetClassMPName -eq "")
        {
            $TargetClassMPName = $targetClass.ManagementPackName;
            $TargetClassMPAlias = New-MPToolManagementPackAlias $TargetClassMPName
        }

        # add target mp as reference
        Write-Verbose "Adding target class management pack reference";
        if (($ManagementPack.References.Values.name.Contains($TargetClassMPName) -eq $false))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $TargetClassMPName -ReferenceManagementPackAlias $TargetClassMPAlias;
            if (!($status))
            {
                Write-Error "Error adding reference mp $TargetClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $TargetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $TargetClassMPName;
        }
    }

    if ($targetClass -eq $null)
    {
        Write-Error "Target class $TargetClassName not found"
        return $false;
    }

    #Get UnitMonitorType
    $UnitMonitorType = $null
    $UnitMonitorType = Get-MPToolUnitMonitorType -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName "Microsoft.Windows.Library" -UnitMonitorTypeName Microsoft.Windows.CheckNTServiceStateMonitorType

    #Get Parent Monitor
    $parentMonitor = $null;
    $parentMonitor = Get-MPToolMonitor -ManagementServerFQDN $ManagementServerFQDN -MonitorName "System.Health.AvailabilityState" -MonitorType "ManagementPackAggregateMonitor";

    ##Create UnitMonitor
    Write-Verbose -Message "Creating UnitMonitor"
    $UnitMonitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitor($ManagementPack, $MonitorName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public);
    $UnitMonitor.DisplayName = $MonitorDisplayName
    $UnitMonitor.Description = $MonitorDescription
    $UnitMonitor.Target = $targetClass
    $UnitMonitor.ParentMonitorID = $parentMonitor
    $UnitMonitor.TypeID = $UnitMonitorType
    $UnitMonitor.Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::AvailabilityHealth;
    

    ##Create AlertSettings
    Write-Verbose -Message "Creating AlertSettings and adding to UnitMonitor"
    $alertSettings = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorAlertSettings;
    $alertSettings.AlertOnState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::$UnhealthyState;
    $alertSettings.AutoResolve = $true;
    $alertSettings.AlertPriority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal;
    $alertSettings.AlertSeverity = [Microsoft.EnterpriseManagement.Configuration.ManagementPackAlertSeverity]::MatchMonitorHealth;
    $alertSettings.AlertParameter1 = '$Data/Context/Property[@Name=''Name'']$'
    $alertSettings.AlertParameter2 = '$Target/Host/Property[Type="Windows!Microsoft.Windows.Computer"]/PrincipalName$'

    $alertMessage = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($ManagementPack, $($MonitorName + ".Alert.Message"));
    $alertMessage.DisplayName = $MonitorDisplayName+" - Failure";
    $alertMessage.Description = "Windows Service {0} failure on {1}. Please see the alert context for details."
    $alertSettings.AlertMessage = $alertMessage;

    $UnitMonitor.AlertSettings = $alertSettings

    #Create OperationalStates
    Write-Verbose -Message "Creating Operational States and adding to UnitMonitor"
    $healthyState = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($UnitMonitor, "Success");
    $errorState = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackUnitMonitorOperationalState($UnitMonitor, "Error");
    $healthyState.HealthState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Success;
    $errorState.HealthState = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Error;
    $healthyState.MonitorTypeStateID = "Running";
    $errorState.MonitorTypeStateID = "NotRunning";

    $UnitMonitor.OperationalStateCollection.Add($healthyState);
    $UnitMonitor.OperationalStateCollection.Add($errorState);

    #Set Configuration
    Write-Verbose -Message "Adding Configuration to UnitMonitor"
    $UnitMonitor.Configuration = $ConfigurationTemp.Configuration.InnerXml;

    Write-Verbose -Message "Saving management pack"
    $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
    $ManagementPack.AcceptChanges();
    
    $GetMonitor = Get-MPToolMonitor -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -MonitorName $MonitorName -MonitorType ManagementPackUnitMonitor
    return $GetMonitor;
    }
    Catch
    {
        $ManagementPack.RejectChanges();
        Write-Error $_.Exception.Message;
        return $false;
    }
}

Function New-MPToolDependencyMonitor
{
<# 
 .Synopsis
  Creates dependency monitor from a relationship.

 .Description
  Creates dependency monitor from a relationship.
  Returns object of type [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor]

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com
 
 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.VMSwitch.Monitoring”

 .Parameter -MonitorName 
  Name of the monitor. Example - "Contoso.VMSwitch.Monitor”

 .Parameter -MonitorDisplayName
  (Optional) Display name of the monitor. Example - "Contoso.VMSwitch.Monitor”

 .Parameter -MonitorDescription
  (Optional) Description of the monitor. Example - "Contoso.VMSwitch.Monitor”

 .Parameter -TargetClassName
  Name of the target class. Example - "Contoso.VMSwitch.Monitor”

 .Parameter -TargetClassMPName 
  Name of the management pack for the target class. Example - "Contoso.VMSwitch.Monitor”

 .Parameter -TargetClassMPAlias 
  Alias for the management pack for the target class. Example - "Contoso.VMSwitch.Monitor”

 .Parameter -RelationshipTypeName 
  Name of the relationship to roll-up health from. This can be a relationship created with New-MPToolHostingRelationship. Example - "Contoso.SCVMM.VMSwitchesHostsVMSwitch”

 .Parameter -ParentMonitorType 
  (Optional) Parent monitor type. Options: AvailabilityState, ConfigurationState, PerformanceState, or SecurityState. Default is AvailabilityState.

 .Parameter -Algorithm 
  Algorithm for the health roll-up. Options: WorstOf or BestOf

 .Parameter -Enabled 
  (Optional) Enabled setting for the monitor $true / $false. Default is $true

 .Example
  # Creates a dependency monitor for the target class "Contoso.SCVMM.VMSwitches” in the management pack "Contoso.VMSwitch.Monitoring”.
  # The monitor will roll-up Availability health from the worst health state from the relationship Contoso.SCVMM.VMSwitchesHostsVMSwitch
    New-MPToolDependencyMonitor -ManagementServerFQDN "scom01.contoso.com" `                        -ManagementPackName "Contoso.VMSwitch.Monitoring” `                        -MonitorName "Contoso.VMSwitches.AvailabilityRollup” `                        -MonitorDescription "Monitor for VM switch health roll-up from vm switch” `                        -TargetClassName "Contoso.SCVMM.VMSwitches” `                        -RelationshipTypeName "Contoso.SCVMM.VMSwitchesHostsVMSwitch” `                        -ParentMonitorType AvailabilityState `                        -Algorithm Worstof -Enabled $true
#>
[CmdletBinding()]
PARAM (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the mangementpack name')][String]$ManagementPackName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor name')][String]$MonitorName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor display name')][String]$MonitorDisplayName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor description name')][String]$MonitorDescription=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP name')][String]$TargetClassMPName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP alias')][String]$TargetClassMPAlias=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitor interval')][String]$RelationshipTypeName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the monitor timeout')][ValidateSet('AvailabilityState','ConfigurationState','PerformanceState','SecurityState')][String]$ParentMonitorType="AvailabilityState",
    [Parameter(Mandatory=$true,HelpMessage='Please enter the monitoring script')][ValidateSet('WorstOf', 'BestOf')][String]$Algorithm,
    [Parameter(Mandatory=$false,HelpMessage='Enabled Monitor? $true/$false -  Defaut:$false')][boolean]$Enabled=$true
    );


$ErrorActionPreference = "Stop";
try
   {
    
    # set display name
    if($MonitorDisplayName -eq "")
    {
        $MonitorDisplayName = $MonitorName.Replace('.',' ');
    }

    # connect to management group
    $ManagementGroup = $null;
    $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN
    New-SCOMManagementGroupConnection $ManagementServerFQDN
    
    # loading management pack
    $ManagementPack = $null;
    $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
    if ($ManagementPack -eq $null)
    {
        Write-Error "Management pack $ManagementPackName not found"
        return $false;
    }

    # create monitor
    Write-Verbose -Message "Building Dependency Monitor $MonitorName"
    [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor]$monitor = $null
    $monitor = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitor($ManagementPack,$MonitorName,[Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public);
    $monitor.DisplayName = $MonitorDisplayName
    $monitor.Description = $MonitorDescription
    
    # target class
    # Get target class
    $targetClass = $null
    Write-Verbose "Loading target class";
    try
    {
        $targetClass = $ManagementPack.GetClass($TargetClassName);
    }
    catch {}
    if ($targetClass -eq $null)
    {
        if($TargetClassMPName -eq "")
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -SealedOnly $true;
        }
        else
        {
            $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -ManagementPackName $TargetClassMPName -SealedOnly $true;
        }
    
        # get target mp name from class if not piped
        Write-Verbose "Resolving target class management pack name";
        if($TargetClassMPName -eq "")
        {
            $TargetClassMPName = $targetClass.ManagementPackName;
            $TargetClassMPAlias = New-MPToolManagementPackAlias $TargetClassMPName
        }

        # add target mp as reference
        Write-Verbose "Adding target class management pack reference";
        if (($ManagementPack.References.Values.name.Contains($TargetClassMPName) -eq $false))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $TargetClassMPName -ReferenceManagementPackAlias $TargetClassMPAlias;
            if (!($status))
            {
                Write-Error "Error adding reference mp $TargetClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $TargetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $TargetClassMPName;
        }
    }

    if ($targetClass -eq $null)
    {
        Write-Error "Target class $TargetClassName not found"
        return $false;
    }

    $monitor.Target = $targetClass
    
    
    # parent monitor
    Write-Verbose -Message "Setting Parent Monitor"
    $parentMonitor = $null;
    if ($parentMonitor -eq $null)
    {
        $parentMonitor = Get-MPToolMonitor -ManagementServerFQDN $ManagementServerFQDN -MonitorName "System.Health.$ParentMonitorType" -MonitorType "ManagementPackAggregateMonitor" ;
    }
    $monitor.ParentMonitorID = $parentMonitor
    $monitor.MemberMonitor = $parentMonitor

    #Relationship
    Write-Verbose -Message "Setting Relationship Type"
    $Relationship = Get-SCOMRelationship -Name $RelationshipTypeName
    $monitor.RelationshipType = $Relationship


    $SCOMEnabled = $null
    if($Enabled -eq $true)
    {
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true;
    }
    else{
        $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false;
    }
    
    #Setting Category
    switch($ParentMonitorType){
        "AvailabilityState"{
                $Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::AvailabilityHealth
                }
        "ConfigurationState"{
                $Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::ConfigurationHealth
                }
        "PerformanceState"{
                $Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::PerformanceHealth
                }
        "SecurityState"{
                $Category = [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::SecurityHealth
                }
    }


    # configure monitor   
    $monitor.Enabled = $SCOMEnabled
    $monitor.Category = $Category
    $monitor.Algorithm = [Microsoft.EnterpriseManagement.Configuration.ManagementPackDependencyMonitorAlgorithm]::$Algorithm
    $monitor.MemberUnAvailable = [Microsoft.EnterpriseManagement.Configuration.HealthState]::Error


    # saving mp
    $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
    $ManagementPack.AcceptChanges([Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackVerificationTypes]::XSDVerification);
    return $monitor;
 }
    Catch
    {
       Write-Error $_.Exception
       return $false;
   }
}

#endregion

#region Rules #####
######################

Function New-MPToolWindowsEventAlertRule
{
<# 
 .Synopsis
  Creates new Windows event alert rule.
 
 .Description
  Creates new Windows event alert rule based on event ID with option for sorting on description text and/or event level. Repeat count based on description text is default enabled but can be disabled.
  Target class must be hosted by Windows Computer.
  Returns object of type [Microsoft.EnterpriseManagement.Configuration. ManagementPackRule]

 .Parameter -ManagementServerFQDN
  Management Server FQDN - Example: SCOM01.contoso.com

 .Parameter -ManagementPackName
  Management Pack Name for the rule - Example: "Contoso.SCVMM.Monitoring"

 .Parameter -RuleName 
  Rule Name - Example: “VMSwitch.Script.Warning”

 .Parameter -RuleDisplayName 
  (Optional) Rule display name - Example: “VMSwitch Script Warning”
 
 .Parameter -RuleDescription 
  (Optional) Rule description - Example: “Rule for Script errors in VMSwitch Discovery Warning”

 .Parameter -EventLogName 
  Event Log Name Name - Example: "Operations Manager"

 .Parameter -EventId 
  Event ID for the rule to look for - Example: 101

 .Parameter -EventDescriptionText 
  (Optional) String to search for in event description - Example: "VMSwitch"

 .Parameter -EventLevel 
  Event level to filter on. Options: Error, Warning, Information.

 .Parameter -AlertSeverity 
  (Optional) Severity of the alert. Options: Error, Warning, Information. Default is Error.

 .Parameter -RepeatCount  
  (Optional) Repeat Count option $true / $false. Default is $true.

 .Parameter -TargetClassName 
  Name of the target class. Example - "Contoso.SCVMM.VMSwitch”

 .Parameter -TargetClassMPName 
  (Optional) Name of the management pack for the target class. Example – “Contoso.SCVMM.Discovery”

 .Parameter -TargetClassMPAlias 
  (Optional) Alias for the management pack for the target class. Example – “ContosoVMMDiscovery”
  
 .Parameter -Enabled   
  Enabled setting for the rule $true / $false. Default is $false.

 .Example
  # Creates a Windows event alert rule in the management pack "Contoso.SCVMM.Monitoring with the name VMSwitch.Script.Warning to target Contoso.SCVMM.VMSwitch.
  # The rule will look for event in the Operations manager event log with the ID 101, VMSwitch in the description field and only Error Event and create a critical alert if conditions are met.
  New-MPToolWindowsEventAlertRule -ManagementServerFQDN scom01.contoso.com `                                -ManagementPackName "Contoso.SCVMM.Monitoring" `                                -RuleName “VMSwitch.Script.Warning” `                                -RuleDescription “Rule for Script errors in VMSwitch Discovery Warning” `                                -EventLogName "Operations Manager" `                                -EventId 101 `                                -EventDescriptionText "VMSwitch" `                                -EventLevel Error `                                -TargetClassName "Contoso.SCVMM.VMSwitch” `                                -Enabled $true
#>
[CmdletBinding()]

PARAM (
    [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the name of the managementpack')][String]$ManagementPackName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the rule name')][String]$RuleName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the rule display name')][String]$RuleDisplayName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the rule description')][String]$RuleDescription=$null,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the event log name')][String]$EventLogName,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the event ID')][int]$EventId,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the event description text')][string]$EventDescriptionText=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the event level')][ValidateSet('Error','Warning','Information')][String]$EventLevel=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the alert serverity')][ValidateSet('Error','Warning','Information')][String]$AlertSeverity='Error',
    [Parameter(Mandatory=$false,HelpMessage='Repeat count on rule? $true/$false -  Defaut:$true')][boolean]$RepeatCount=$true,
    [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP name')][String]$TargetClassMPName=$null,
    [Parameter(Mandatory=$false,HelpMessage='Please enter the target class MP alias')][String]$TargetClassMPAlias=$null,
    [Parameter(Mandatory=$false,HelpMessage='Enabled Rule? $true/$false -  Defaut:$false')][boolean]$Enabled=$false
    );

    [xml]$DataSourceConfigXML = @'
<Configuration>
<ComputerName></ComputerName>
<LogName></LogName>
<Expression>
  <And>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="UnsignedInteger">EventDisplayNumber</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="UnsignedInteger">EVENTID</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
    <Expression>
        <RegExExpression>
        <ValueExpression>
            <XPathQuery Type="String">EventDescription</XPathQuery>
        </ValueExpression>
        <Operator>ContainsSubstring</Operator>
        <Pattern>EventDescription</Pattern>
        </RegExExpression>
    </Expression>
    <Expression>
        <SimpleExpression>
        <ValueExpression>
            <XPathQuery Type="Integer">EventLevel</XPathQuery>
        </ValueExpression>
        <Operator>Equal</Operator>
        <ValueExpression>
            <Value Type="Integer">EventLevel</Value>
        </ValueExpression>
        </SimpleExpression>
    </Expression>
  </And>
</Expression>
</Configuration>
'@;
    [xml]$WriteActionConfigXML = @'
<Configuration>
  <Priority>1</Priority>
  <Severity>0</Severity>
  <AlertOwner/>
  <AlertMessageId></AlertMessageId>
  <AlertParameters>
    <AlertParameter1>$Data/EventDescription$</AlertParameter1>
  </AlertParameters>
  <Suppression>
    <SuppressionValue>$Data/EventDescription$</SuppressionValue>
  </Suppression>
  <Custom1/>
  <Custom2/>
  <Custom3/>
  <Custom4/>
  <Custom5/>
  <Custom6/>
  <Custom7/>
  <Custom8/>
  <Custom9/>
  <Custom10/>
</Configuration>
'@;

    $DatasourceModuleTypeName = "Microsoft.Windows.EventProvider";
    $DatasourceModuleTypeMPName = "Microsoft.Windows.Library";
    $DatasourceModuleTypeMPNameAlias = "Windows"
    $WriteActionModuleTypeName = "System.Health.GenerateAlert";
    $WriteActionModuleTypeMPName = "System.Health.Library";
    $WriteActionModuleTypeMPNameAlias = "SystemHealthLibrary"

    $ErrorActionPreference = "Stop";
    try
    {        
        if (!($RuleDisplayName))
        {
            $RuleDisplayName = $RuleName.Replace('.',' ');
        }
        # connect
        $ManagementGroup = $null;
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection -ManagementServerFQDN $ManagementServerFQDN
    
        # loading management pack
        $ManagementPack = $null;
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        if ($ManagementPack -eq $null)
        {
            Write-Error "Management pack $ManagementPackName not found"
            return $false;
        }

        # adding references
        if (($ManagementPack.References.Count -eq 0) -or (!($ManagementPack.References.Values.name.Contains($DatasourceModuleTypeMPName))))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $DatasourceModuleTypeMPName -ReferenceManagementPackAlias $DatasourceModuleTypeMPNameAlias;
            if ($status -eq $null)
            {
                Write-Error "Error adding reference mp $DatasourceModuleTypeMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $DatasourceModuleTypeMPNameAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $DatasourceModuleTypeMPName;
        }

        if (!($ManagementPack.References.Values.name.Contains($WriteActionModuleTypeMPName)))
        {
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $WriteActionModuleTypeMPName -ReferenceManagementPackAlias $WriteActionModuleTypeMPNameAlias;
            if ($status -eq $null)
            {
                Write-Error "Error adding reference mp $WriteActionModuleTypeMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $WriteActionModuleTypeMPNameAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $WriteActionModuleTypeMPName;
        }


        # create rule
        $rule = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRule($ManagementPack, $RuleName);

        # Get target class
        $targetClass = $null
        Write-Verbose "Loading target class";
        try
        {
            $targetClass = $ManagementPack.GetClass($TargetClassName);
        }
        catch {}
        if ($targetClass -eq $null)
        {
            if($TargetClassMPName -eq "")
            {
                $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -SealedOnly $true;
            }
            else
            {
                $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $TargetClassName -ManagementPackName $TargetClassMPName -SealedOnly $true;
            }
    
            # get target mp name from class if not piped
            Write-Verbose "Resolving target class management pack name";
            if($TargetClassMPName -eq "")
            {
                $TargetClassMPName = $targetClass.ManagementPackName;
                $TargetClassMPAlias = New-MPToolManagementPackAlias $TargetClassMPName
            }

            # add target mp as reference
            Write-Verbose "Adding target class management pack reference";
            if (($ManagementPack.References.Values.name.Contains($TargetClassMPName) -eq $false))
            {
                $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $TargetClassMPName -ReferenceManagementPackAlias $TargetClassMPAlias;
                if (!($status))
                {
                    Write-Error "Error adding reference mp $TargetClassMPName";
                    return $false;
                }
                $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
            }
            else
            {
                $TargetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $TargetClassMPName;
            }
        }

        if ($targetClass -eq $null)
        {
            Write-Error "Target class $TargetClassName not found"
            return $false;
        }

        # create datasource
        $dataSource = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackDataSourceModule($rule,"DS");

        #Get data source provider
        try
        {
            $dataSource.TypeID = $ManagementPack.GetModuleType($DatasourceModuleTypeName);
        }                                                                    
        Catch {};
        if ($dataSource.TypeID -eq $null)
        {
            $dataSource.TypeID = Get-MPToolDataSourceModuleType -ManagementServerFQDN $ManagementServerFQDN -DataSourceModuleTypeName $DatasourceModuleTypeName -ManagementPackName $DatasourceModuleTypeMPName -SealedOnly $true;
        }
        if ($dataSource.TypeID -eq $null)
        {
            Write-Error "Type module $DatasourceModuleTypeName not found";
            return $false;
        }

        $dataSource.Description = "Data source created by MPTools";
        $dataSource.DisplayName = "DS";


        # manipulate configs
        if ($targetClass.Hosted)
        {
            $computerNode = '$Target/Host/Property[Type="' + $DatasourceModuleTypeMPNameAlias + '!Microsoft.Windows.Computer"]/NetworkName$';
        }
        else
        {
            $computerNode = '$Target/Property[Type="' + $DatasourceModuleTypeMPNameAlias + '!Microsoft.Windows.Computer"]/NetworkName$';
        }

        $DataSourceConfigXML.Configuration.ComputerName = $computerNode;
        $DataSourceConfigXML.Configuration.LogName = $EventLogName;
        
        #EventID
        $DataSourceConfigXML.SelectSingleNode("//ValueExpression[contains(Value, 'EVENTID')]").Value.InnerText = $EventId.ToString()

        #EventDescription
        if($EventDescriptionText -ne ""){
            $DataSourceConfigXML.SelectSingleNode("//RegExExpression[contains(Pattern, 'EventDescription')]").Pattern = $EventDescriptionText
        }
        else{
            $EventDescriptionNode =  $DataSourceConfigXML.Configuration.Expression.and.Expression | ? {$_.InnerXml -like "*EventDescription*"}
            $DataSourceConfigXML.Configuration.Expression.and.RemoveChild($EventDescriptionNode)
        }


        #EventLevel
        if($EventLevel -ne ""){
            $SCOMEventLevel = $null
            Switch($EventLevel){
               'Error'{
                    $SCOMEventLevel = "1"
               }
               'Warning'{
                    $SCOMEventLevel = "2"
               }
               'Information'{
                    $SCOMEventLevel = "0"
               }

            }
            $DataSourceConfigXML.SelectSingleNode("//ValueExpression[contains(Value, 'EventLevel')]").Value.InnerText = $SCOMEventLevel
        }
        else{
            $EventLevelNode =  $DataSourceConfigXML.Configuration.Expression.and.Expression | ? {$_.InnerXml -like "*EventLevel*"}
            $DataSourceConfigXML.Configuration.Expression.and.RemoveChild($EventLevelNode)
        }

        
        #Set Data Source Configuration
        $dataSource.Configuration = $DataSourceConfigXML.Configuration.InnerXml;


        # create write action
        $WriteAction = New-Object  Microsoft.EnterpriseManagement.Configuration.ManagementPackWriteActionModule($rule,"WA");

        #Get write action provider
        try
        {
            $WriteAction.TypeID = $ManagementPack.GetModuleType($WriteActionModuleTypeName);
        }                                                                    
        Catch {};
        if ($WriteAction.TypeID -eq $null)

        {
            $WriteAction.TypeID = Get-MPToolWriteActionModuleType -ManagementServerFQDN $ManagementServerFQDN -ModuleTypeName $WriteActionModuleTypeName -ManagementPackName $WriteActionModuleTypeMPName -SealedOnly $true;
        }
        if ($WriteAction.TypeID -eq $null)
        {
            Write-Error "Type module $WriteActionModuleTypeName not found";
            return $false;
        }

        
        $WriteAction.Description = "Write action";
        $WriteAction.DisplayName = "WA";

        $alertMessageId = '$MPElement[Name="' + $RuleName + '.AlertMessage"]$';
        $WriteActionConfigXML.Configuration.AlertMessageId = $alertMessageId;
        $SCOMSeverity = $null
        Switch($AlertSeverity){
           'Error'{
                $SCOMSeverity = "2"
           }
           'Warning'{
                $SCOMSeverity = "1"
           }
           'Information'{
                $SCOMSeverity = "0"
           }

        }

        $WriteActionConfigXML.Configuration.Severity = $SCOMSeverity
        
        #Alert suppression / Repeat count
        if($RepeatCount -eq $false){
            $WriteActionConfigXML.Configuration.Suppression.RemoveAll()
        }
        
        $WriteAction.Configuration = $WriteActionConfigXML.Configuration.InnerXml;

        # create string resource
        $stringRes = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackStringResource($ManagementPack,$($RuleName + '.AlertMessage'));
        $displayString = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackDisplayString($stringRes,$ManagementPack,$ManagementPack.DefaultLanguageCode);
        $displayString.Name = $RuleDisplayName + " Alert";
        $displayString.Description = "{0}"  


        $SCOMEnabled = $null
        if($Enabled -eq $true)
        {
            $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::true;
        }
        else{
            $SCOMEnabled = [Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitoringLevel]::false;
        }
    
    
        # configure rule
        $rule.DisplayName = $RuleDisplayName;
        $rule.Description = $RuleDescription;
        $rule.Category =  [Microsoft.EnterpriseManagement.Configuration.ManagementPackCategoryType]::Alert;
        $rule.Enabled = $SCOMEnabled
        $rule.Priority = [Microsoft.EnterpriseManagement.Configuration.ManagementPackWorkflowPriority]::Normal;
        $rule.ConfirmDelivery = $true;
        $rule.Remotable = $true;
        $rule.DataSourceCollection.Add($dataSource);
        $rule.WriteActionCollection.Add($WriteAction);
        $rule.Target = $targetClass;
            
   
        # saving mp
        $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
        $ManagementPack.AcceptChanges([Microsoft.EnterpriseManagement.Configuration.IO.ManagementPackVerificationTypes]::XSDVerification);
        return $rule;
    }
    Catch
    {
        Write-Error $_.Exception
        return $false;
    }
}

#endregion

#region Relationships #####
###########################
Function New-MPToolHostingRelationship
{
<# 
 .Synopsis
  Creates a new hosting relationship and sets the target class to be hosted

 .Description
  Creates a new hosting relationship and sets the target class to be hosted

 .Parameter -ManagementServerFQDN
  FQDN of the management server. Example - scom01.contoso.com

 .Parameter -ManagementPackName
  Name of the management pack. Example - "Contoso.Application.Discovery"
 
 .Parameter -RelationshipName
  Name of the new relationship. Example - "Contoso.Application.WebsiteHostsComponent"

 .Parameter -SourceClassName
  Name of the source class. Example - “Contoso.Application.Website”

 .Parameter -SourceEndpointName
  (Optional) Name of the source endpoint on relationship. Default: “Source” Example – “WebSite”

 .Parameter -sourceClassMPName
  (Optional) Name of the source class management pack. Example – “Contoso.Application.Discovery”

 .Parameter -sourceClassMPAlias
  (Optional) Alias for the source class management pack. Example – ContosoAppDiscovery
 
 .Parameter -TargetClassName
  Name of the target class. Example – “Contoso.Application.Website.Component”

 .Parameter -TargetEndpointName
  (Optional) Name of the target endpoint on relationship. Default: “Target”. Example – “Component”

 .Parameter -targetClassMPName
  (Optional) Name of the source class management pack. Example – “Contoso.Application.Discovery”
 
 .Parameter -targetClassMPAlias
  (Optional) Alias for the source class management pack. Example – ContosoAppDiscovery

 .Parameter -IsAbstract
  (Optional) Abstract setting for relationship $true/$false. Default: $false

 .Example
  Creates a hosting relationship between source class Contoso.Application.Website and target class Contoso.Application.Website.Component   called Contoso.Application.WebsiteHostsComponent in the management pack Contoso.Application.Discovery.  New-MPToolHostingRelationship -ManagementServerFQDN "scom01.contoso.com" `                 -ManagementPackName "Contoso.Application.Discovery" `                 -RelationshipName "Contoso.Application.WebsiteHostsComponent" `                 -SourceClassName "Contoso.Application.Website" `                 -TargetClassName "Contoso.Application.Website.Component"
#>
[CmdletBinding()]
PARAM (
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management server name')][String]$ManagementServerFQDN,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the management pack name')][String]$ManagementPackName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the relationship name')][String]$RelationshipName,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the source class name')][String]$SourceClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the source class endpoint name')][String]$SourceEndpointName="Source",
        [Parameter(Mandatory=$false,HelpMessage='Please enter the source class MP name')][String]$sourceClassMPName = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the source class MP alias')][String]$sourceClassMPAlias = $null,
        [Parameter(Mandatory=$true,HelpMessage='Please enter the target class name')][String]$TargetClassName,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the target class endpoint name')][String]$TargetEndpointName="Target",
        [Parameter(Mandatory=$false,HelpMessage='Please enter the source class MP name')][String]$targetClassMPName = $null,
        [Parameter(Mandatory=$false,HelpMessage='Please enter the source class MP name')][String]$targetClassMPAlias = $null,
        [Parameter(Mandatory=$false,HelpMessage='Is Abstract: true/false. Default true')][Boolean]$IsAbstract = $false
    )

    $ErrorActionPreference = "Stop"
    try{
        # loading connection
        $ManagementGroup = $null;
        $ManagementGroup = Get-MPToolActiveManagementGroupConnection $ManagementServerFQDN;
        $MGConnection = $null
        $MGConnection = Get-SCOMManagementGroupConnection -ManagementGroupName $ManagementGroup.Name
        if($MGConnection -eq $null){
            New-SCOMManagementGroupConnection -ComputerName $ManagementServerFQDN
        }


        # loading mp
        $ManagementPack = $null;
        $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName
        if ($ManagementPack -eq $null)
        {
            Write-Error "Management pack $ManagementPackName not found";
            return $false
        }

        Write-Verbose -Message "Checking if management pack is unsealed"
        if ($ManagementPack.Sealed -eq $true)
        {
            Write-Error "Management pack $ManagementPackName is sealed";
            return $false;
        }

        #Get Base class System.Hosting
        $RelationshipBaseClassName = "System.Hosting"
        $RelationshipBaseClassMPName = "System.Library"
        $RelationshipBaseClassMPAlias = "System"
        $RelationshipbaseClass = $null
        Write-verbose -Message "Getting  relationship base class: $RelationshipBaseClassName"
        $RelationshipbaseClass = Get-SCOMRelationship -Name $RelationshipBaseClassName

      
        # add base class mp as reference
        if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($RelationshipBaseClassMPName) -eq $false)){
        Write-verbose -message "Adding reference for MP: $RelationshipBaseClassMPName for base class: $RelationshipBaseClassName"
        $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $RelationshipBaseClassMPName -ReferenceManagementPackAlias $RelationshipBaseClassMPAlias;
            if ($status -ne $true)
            {
                Write-Error "Error adding reference mp $RelationshipBaseClassMPName";
                return $false;
            }
            $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        }
        else
        {
            $RelationshipBaseClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $RelationshipBaseClassMPName;
        }

        if($RelationshipbaseClass -eq $null)
        {
            Write-Error "Base class $BaseClassName not found"
            return $false;
        }


        # Get Source class
        Write-verbose -Message "Getting Source class: $sourceClassName"
        $sourceClass = $null
        try
        {
            $sourceClass = $ManagementPack.GetClass($sourceClassName);
        }
        catch {}

        if($sourceClass -eq $null)
        {
            if($sourceClassMPName -ne "")
            {
                $sourceClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $sourceClassName -ManagementPackName $sourceClassMPName -SealedOnly $true;
            }
            else
            {
                $sourceClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $sourceClassName -SealedOnly $true;
            }

            if($sourceClass -eq $null)
            {
                Write-Error "source class $sourceClassName not found or source MP not sealed"
                return $false;
            }

            # get source class mp name from class if not piped
            if($sourceClassMPName -eq "")
            {
                $sourceClassMPName = $sourceClass.ManagementPackName
                $sourceClassMPAlias = New-MPToolManagementPackAlias $sourceClassMPName
            }

            # add source class mp as reference
            if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($sourceClassMPName) -eq $false)){
            Write-verbose -message "Adding reference for MP: $sourceClassMPName for source class: $sourceClassName"
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $sourceClassMPName -ReferenceManagementPackAlias $sourceClassMPAlias;
                if ($status -ne $true)
                {
                    Write-Error "Error adding reference mp $sourceClassMPName";
                    return $false;
                }
                $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
            }
            else
            {
                $sourceClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $sourceClassMPName;
            }
        }

    

        # Get target class
        Write-verbose -Message "Getting target class: $targetClassName"
        $targetClass = $null
        try
        {
            $targetClass = $ManagementPack.GetClass($targetClassName);
        }
        catch {}

        if($targetClass -eq $null)
        {
            if($targetClassMPName -ne "")
            {
                $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $targetClassName -ManagementPackName $targetClassMPName -SealedOnly $true;
            }
            else
            {
                $targetClass = Get-MPToolClass -ManagementServerFQDN $ManagementServerFQDN -ClassName $targetClassName -SealedOnly $true;
            }

            if($targetClass -eq $null)
            {
                Write-Error "target class $targetClassName not found or target MP not sealed"
                return $false;
            }

            # get target class mp name from class if not piped
            if($targetClassMPName -eq "")
            {
                $targetClassMPName = $targetClass.ManagementPackName
                $targetClassMPAlias = New-MPToolManagementPackAlias $targetClassMPName
            }

            # add target class mp as reference
            if (($ManagementPack.References.Count -eq 0) -or ($ManagementPack.References.Values.name.Contains($targetClassMPName) -eq $false)){
            Write-verbose -message "Adding reference for MP: $targetClassMPName for target class: $targetclass.name"
            $status = Add-MPToolManagementPackReference -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ReferenceManagementPackName $targetClassMPName -ReferenceManagementPackAlias $targetClassMPAlias;
                if ($status -ne $true)
                {
                    Write-Error "Error adding reference mp $targetClassMPName";
                    return $false;
                }
                $ManagementPack = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
            }
            else
            {
                $targetClassMPAlias = Get-MPToolManagementPackReferenceAlias -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName -ManagementPackReferenceName $targetClassMPName;
            }
        }

        Write-Verbose -Message "Checking if management pack is unsealed"
        $targetClassMP = Get-MPToolManagementPack -ManagementServerFQDN $ManagementServerFQDN -ManagementPackName $ManagementPackName;
        if ($targetClassMP.Sealed -eq $true)
        {
            Write-Error "Target Class Management pack $targetClassMPName is sealed";
            return $false;
        }

        #Creating relationship
        Write-verbose -Message "Creating relationship $RelationshipID"
        $Relationship = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationship($ManagementPack, $RelationshipName, [Microsoft.EnterpriseManagement.Configuration.ManagementPackAccessibility]::Public)
        $Relationship.Abstract = $IsAbstract
        $Relationship.Base = $RelationshipbaseClass
        $Relationship.DisplayName = $RelationshipName

         #Create relationshipEndPoints
        Write-verbose -Message "Creating Endpoints"
        $sourceClassEndpoint = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationshipEndpoint($Relationship, $SourceEndpointName)
        $sourceClassEndpoint.Type = $sourceClass
        $targetClassEndpoint = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackRelationshipEndpoint($Relationship, $TargetEndpointName)
        $targetClassEndpoint.Type = $targetClass

        $Relationship.Source = $sourceClassEndpoint
        $Relationship.Target = $targetClassEndpoint

        $targetClass.Hosted = $true
        $targetClass.Status = "PendingUpdate"

        Write-Verbose -Message "Saving management pack";
        $ManagementPack.Version = New-Object Version($ManagementPack.Version.Major, $ManagementPack.Version.Minor, $($ManagementPack.Version.Build + 1), $ManagementPack.Version.Revision);
        $ManagementPack.AcceptChanges();
        return $Relationship;
    }
    Catch
    {
        Write-Error $_.Exception;
        return $false;
    }
}

#endregion



#region ######  EXPORT-MODULEMEMBER  #########
#region Export-ModuleMember base Management pack #####
Export-ModuleMember -Function New-MPToolManagementPackAlias
Export-ModuleMember -Function Get-MPToolManagementPackReferenceAlias
Export-ModuleMember -Function New-MPToolManagementPack
Export-ModuleMember -Function New-MPToolOverrideManagementPack
#Export-ModuleMember -Function Get-MPToolActiveManagementGroupConnection
#Export-ModuleMember -Function Connect-MPToolManagementGroup
#Export-ModuleMember -Function Get-MPToolManagementPack
Export-ModuleMember -Function Add-MPToolManagementPackReference
#endregion

#region Export-ModuleMember Classes #####
Export-ModuleMember -Function New-MPToolApplicationComponentClass
Export-ModuleMember -Function New-MPToolComputerRoleClass
Export-ModuleMember -Function New-MPToolLocalApplicationClass
Export-ModuleMember -Function New-MPToolClass
#Export-ModuleMember -Function Get-MPToolClass
#endregion

#region Export-ModuleMember Module Types #####
#Export-ModuleMember -Function Get-MPToolDataSourceModuleType
#Export-ModuleMember -Function Get-MPToolWriteActionModuleType
#endregion

#region Export-ModuleMember Rules #####
Export-ModuleMember -Function New-MPToolWindowsEventAlertRule
#endregion

#region Export-ModuleMember Discoveries #####
Export-ModuleMember -Function New-MPToolFilteredRegistryDiscovery
Export-ModuleMember -Function New-MPToolPSDiscovery
#endregion

#region Export-ModuleMember Monitors #####
#Export-ModuleMember -Function Get-MPToolMonitor
#Export-ModuleMember -Function Get-MPToolUnitMonitorType
Export-ModuleMember -Function New-MPToolPSStateMonitor
Export-ModuleMember -Function New-MPToolWindowsServiceMonitor
Export-ModuleMember -Function New-MPToolDependencyMonitor

#endregion

#region Export-ModuleMember Relationships #####
Export-ModuleMember -Function New-MPToolHostingRelationship
#endregion
#endregion ######  EXPORT-MODULEMEMBER  #########