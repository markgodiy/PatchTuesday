# https://gist.github.com/mwallner/9bb87e460dec1e4eec2c70217b1ec6ae
# All credit to: Manfred Wallner, mwallner, https://mwallner.net/about

<#
  .SYNOPSIS
    Install all updates available via SCCM and WAIT for the installation to finish.

  .PARAMETER Computer
    the computer to install updates on

  .OUTPUTS
    a object containing information about the installed updates and the reboot state (if a reboot is required or not)

    Name                           Value
    ----                           -----
    result                         System.Management.ManagementBaseObject
    updateInfo                     {ApprovedUpdates, PendingPatches, RebootPending}
    rebootPending                  Boolean

  .EXAMPLE
  . .\Install-SCCMUpdates.ps1; Install-SCCMUpdates
  dot-source the script to load the function "Install-SCCMUpdates", directly call the function afterwards

  .NOTES
    the target computer needs to have SCCM enabled
    (this is implicitly checked by accessing the root\CCM\ClientSDK WMI namespace)

  .LINK
    CCM_SoftwareUpdate: https://docs.microsoft.com/en-us/sccm/develop/reference/core/clients/sdk/ccm_softwareupdate-client-wmi-class
    CCM_SoftwareUpdatesManager: https://docs.microsoft.com/en-us/sccm/develop/reference/core/clients/sdk/ccm_softwareupdatesmanager-client-wmi-class
    install all missing SCCM Updates (client side): https://gallery.technet.microsoft.com/scriptcenter/Install-All-Missing-8ffbd525
    check for pending reboots: https://github.com/bcwilhite/PendingReboot/blob/master/Public/Test-PendingReboot.ps1
#>
function Install-SCCMUpdates {
    [cmdletbinding()]
    param(
      $Computer = "localhost"
    )
  
    Set-StrictMode -Version 2
    $ErrorActionPreference = "Stop"
  
    $wmiCCMSDK = "root\CCM\ClientSDK"
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Verbose "$scriptName ..."

    $statustable = @"
      
+------------+-------------------+------------+---------------------------+
| Evaluation | Job               | Evaluation | Job State                 |
| State      | State             | State      |                           |
+------------+-------------------+------------+---------------------------+
| 0          | None              | 12         | InstallComplete           |
| 1          | Available         | 13         | Error                     |
| 2          | Submitted         | 14         | WaitServiceWindow         |
| 3          | Detecting         | 15         | WaitUserLogon             |
| 4          | PreDownload       | 16         | WaitUserLogoff            |
| 5          | Downloading       | 17         | WaitJobUserLogon          |
| 6          | WaitInstall       | 18         | WaitUserReconnect         |
| 7          | Installing        | 19         | PendingUserLogoff         |
| 8          | PendingSoftReboot | 20         | PendingUpdate             |
| 9          | PendingHardReboot | 21         | WaitingRetry              |
| 10         | WaitReboot        | 22         | WaitPresModeOff           |
| 11         | Verifying         | 23         | WaitForOrchestration      |
+------------+-----------------+--------------+---------------------------+
"@
  
    function Test-WMIAccess {
      $wmicheck = Get-WmiObject -ComputerName localhost -namespace root\cimv2 -Class Win32_BIOS -ErrorAction SilentlyContinue
      if ($wmicheck) {
        Write-Verbose "Test-WMIAccess - success"
        return $true
      }
      else {
        Write-Verbose "Test-WMIAccess - failure"
        return $false
      }
    }
  
    if (-Not (Test-WMIAccess)) {
      throw "unable to contact WMI provider"
    }
  
    function Get-CCMUpdates {
      [cmdletbinding()]
      param (
        $ComputerName
      )
      # Get list of all instances of CCM_SoftwareUpdate from root\CCM\ClientSDK for missing updates
      Get-WmiObject -ComputerName $ComputerName -Namespace $wmiCCMSDK -Class CCM_SoftwareUpdate -Filter ComplianceState=0 -ErrorAction Stop
    }
  
    function Install-CCMUpdates {
      [cmdletbinding()]
      param (
        $ComputerName,
        $UpdateElements
      )
      $UpdatesReformatted = @($UpdateElements | ForEach-Object {
          if ($_.ComplianceState -eq 0) {[WMI]$_.__PATH}
        })
      # The following is the invoke of the CCM_SoftwareUpdatesManager.InstallUpdates with our found updates 
      # NOTE: the command in the ArgumentList is intentional, as it flattens the Object into a System.Array for us 
      # The WMI method requires it in this format. (https://gallery.technet.microsoft.com/scriptcenter/Install-All-Missing-8ffbd525)
      Invoke-WmiMethod -ComputerName $ComputerName -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (, $UpdatesReformatted) -Namespace $wmiCCMSDK
    }
  
    function Wait-ForCCMUpdatesToFinish {
      [cmdletbinding()]
      param(
        $ComputerName
      )

      $finishStates = @(8, 9, 10, 12, 13, 19)
      do {
        
        $statustable
        $updates = Get-WmiObject -ComputerName $ComputerName -Class CCM_SoftwareUpdate -Namespace $wmiCCMSDK -Filter ComplianceState=0
        
        $updates | Foreach-Object {
          Write-Progress -Activity $_.Name -PercentComplete $_.PercentComplete
          Start-Sleep -Seconds 5
        }

        Start-Sleep -Seconds 5

        Write-Host "[$($updates.PercentComplete)]% - EvaluationState [$($updates.EvaluationState)]"

        $stateFinished = $true

        foreach ($state in $updates.EvaluationState) {
          if (-Not ($finishStates -contains $state)) {
            $stateFinished = $false
            break;
          }
        }

        # yup, $updates.PercentComplete is an array, but "-ne" will acts as a filter function

      } while (($updates.PercentComplete -ne 100) -And (-Not $stateFinished))

    }
  
    $updates = Get-CCMUpdates -ComputerName $Computer

    $updates | ForEach-Object {
      Write-Verbose $_
    }
    $updateProps = @{
      ApprovedUpdates = ($updates | Measure-Object).Count
      PendingPatches  = ($updates | Where-Object { $updates.EvaluationState -ne 8 } | Measure-Object).Count
      RebootPending   = ($updates | Where-Object { $updates.EvaluationState -eq 8 } | Measure-Object).Count
    }
    Write-Host " ApprovedUpdates: $($updateProps.ApprovedUpdates) "
    Write-Host "  PendingPatches: $($updateProps.PendingPatches) "
    Write-Host "   RebootPending: $($updateProps.RebootPending) "
  
    $res = @{
      updateInfo    = $updateProps
      result        = $null
      rebootPending = $false
    }
  
    if ($updateProps.PendingPatches -gt 0) {
      try {
        $res.result = Install-CCMUpdates -ComputerName $Computer -UpdateElements $updates
        Wait-ForCCMUpdatesToFinish -ComputerName $Computer
      }
      catch {
        throw "failed to install updates."
      }
    }
    else {
      Write-Host " > no updates pending < " -ForegroundColor Green
    }
    if ($res.result) {
      Write-Verbose $res.result
    }
  
    <#
    Test-PendingReboot https://github.com/bcwilhite/PendingReboot/blob/master/Public/Test-PendingReboot.ps1
  
      .SYNOPSIS
        Test the pending reboot status on a local and/or remote computer.
  
      .NOTES
        Author:  Brian Wilhite
        Email:   bcwilhite (at) live.com
    #>
    function Test-PendingReboot {
      [CmdletBinding()]
      param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("CN", "Computer")]
        [String[]]
        $ComputerName = $env:COMPUTERNAME,
  
        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,
  
        [Parameter()]
        [Switch]
        $Detailed,
  
        [Parameter()]
        [Switch]
        $SkipConfigurationManagerClientCheck,
  
        [Parameter()]
        [Switch]
        $SkipPendingFileRenameOperationsCheck
      )
  
      process {
        foreach ($computer in $ComputerName) {
          try {
            $invokeWmiMethodParameters = @{
              Namespace    = 'root/default'
              Class        = 'StdRegProv'
              Name         = 'EnumKey'
              ComputerName = $computer
              ErrorAction  = 'Stop'
            }
  
            $hklm = [UInt32] "0x80000002"
  
            if ($PSBoundParameters.ContainsKey('Credential')) {
              $invokeWmiMethodParameters.Credential = $Credential
            }
  
            ## Query the Component Based Servicing Reg Key
            $invokeWmiMethodParameters.ArgumentList = @($hklm, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\')
            $registryComponentBasedServicing = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootPending'
  
            ## Query WUAU from the registry
            $invokeWmiMethodParameters.ArgumentList = @($hklm, 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')
            $registryWindowsUpdateAutoUpdate = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootRequired'
  
            ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
            $invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Services\Netlogon')
            $registryNetlogon = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames
            $pendingDomainJoin = ($registryNetlogon -contains 'JoinDomain') -or ($registryNetlogon -contains 'AvoidSpnSet')
  
            ## Query ComputerName and ActiveComputerName from the registry and setting the MethodName to GetMultiStringValue
            $invokeWmiMethodParameters.Name = 'GetMultiStringValue'
            $invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\', 'ComputerName')
            $registryActiveComputerName = Invoke-WmiMethod @invokeWmiMethodParameters
  
            $invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\', 'ComputerName')
            $registryComputerName = Invoke-WmiMethod @invokeWmiMethodParameters
  
            $pendingComputerRename = $registryActiveComputerName -ne $registryComputerName -or $pendingDomainJoin
  
            ## Query PendingFileRenameOperations from the registry
            if (-not $PSBoundParameters.ContainsKey('SkipPendingFileRenameOperationsCheck')) {
              $invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\Session Manager\', 'PendingFileRenameOperations')
              $registryPendingFileRenameOperations = (Invoke-WmiMethod @invokeWmiMethodParameters).sValue
              $registryPendingFileRenameOperationsBool = [bool]$registryPendingFileRenameOperations
            }
  
            ## Query ClientSDK for pending reboot status, unless SkipConfigurationManagerClientCheck is present
            if (-not $PSBoundParameters.ContainsKey('SkipConfigurationManagerClientCheck')) {
              $invokeWmiMethodParameters.NameSpace = 'ROOT\ccm\ClientSDK'
              $invokeWmiMethodParameters.Class = 'CCM_ClientUtilities'
              $invokeWmiMethodParameters.Name = 'DetermineifRebootPending'
              $invokeWmiMethodParameters.Remove('ArgumentList')
  
              try {
                $sccmClientSDK = Invoke-WmiMethod @invokeWmiMethodParameters
                $systemCenterConfigManager = $sccmClientSDK.ReturnValue -eq 0 -and ($sccmClientSDK.IsHardRebootPending -or $sccmClientSDK.RebootPending)
              }
              catch {
                $systemCenterConfigManager = $null
                Write-Verbose -Message ($script:localizedData.invokeWmiClientSDKError -f $computer)
              }
            }
  
            $isRebootPending = $registryComponentBasedServicing -or `
              $pendingComputerRename -or `
              $pendingDomainJoin -or `
              $registryPendingFileRenameOperationsBool -or `
              $systemCenterConfigManager -or `
              $registryWindowsUpdateAutoUpdate
  
            if ($PSBoundParameters.ContainsKey('Detailed')) {
              [PSCustomObject]@{
                ComputerName                     = $computer
                ComponentBasedServicing          = $registryComponentBasedServicing
                PendingComputerRenameDomainJoin  = $pendingComputerRename
                PendingFileRenameOperations      = $registryPendingFileRenameOperationsBool
                PendingFileRenameOperationsValue = $registryPendingFileRenameOperations
                SystemCenterConfigManager        = $systemCenterConfigManager
                WindowsUpdateAutoUpdate          = $registryWindowsUpdateAutoUpdate
                IsRebootPending                  = $isRebootPending
              }
            }
            else {
              [PSCustomObject]@{
                ComputerName    = $computer
                IsRebootPending = $isRebootPending
              }
            }
          }
  
          catch {
            Write-Verbose "$Computer`: $_"
          }
        }
      }
    }
  
    $res.rebootPending = (Test-PendingReboot -ComputerName $Computer).IsRebootPending
    if ($res.rebootPending) {
      Write-Host " > REBOOT PENDING < " -ForegroundColor Yellow
    }
    Write-Output $res
  }

  Install-SCCMUpdates
