function Get-DotNetInstalledSDKVersion {
    [CmdletBinding()]
    param (
        $ComputerName,
        $Session
    )
        
    begin {

        if (!($Session)){
            $newsession = New-PSSession $ComputerName
            if ($newsession) {
                Write-Verbose "Success: PsRemote session established with $ComputerName"
                Write-Verbose "Getting Installed .NET SDK version from $computername"
                $output = Invoke-Command $newsession { dotnet sdk check } | Out-String
            }
            else {
                Write-Verbose "Failed: PsRemote session not established with $ComputerName"
            }   
        } elseif ($session) {
            $output = Invoke-Command $session { dotnet sdk check } | Out-String
        }
        
    }
        
    process {

       if ($output -match '(\d+\.\d+\.\d+)\s+Up to date\.') {
                $Matches[1]
        } else {
            if ($output -like "*dotnet :   It was not possible to find any installed .NET Core SDKs*") {
                "dotnet: It was not possible to find any installed .NET Core SDKs"
            }
            else {
                try {

                    $InstallRegistry = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

                    # Get list of install applications
                    Get-ItemProperty $InstallRegistry | ? DisplayName -like 

                } catch {

                }
        }
    }
    
    end {
        Remove-PSSession $newsession
    }
}

