<#

.DESCRIPTION
Author: Mark Go
PowerShell script designed to check for pending patches available via SCCM (System Center Configuration Manager). It provides the ability to retrieve pending patch information for specified remote computers and can be used to identify patches that need to be installed. The script also includes the option to automatically start the WinRM service on target hosts if necessary.

.EXAMPLE
Get-SCCMPendingPatches SERVER01 -Verbose
Get pending patches for a specific computer

.EXAMPLE
$computers = "PC01","SERVER01","192.168.1.101"
PS C:\>$sccmstatus = @(Get-SCCMPendingPatches -ComputerName $computers)

or 

PS C:\>[array]$sccmstatus = Get-SCCMPendingPatches -ComputerName $computers

Get pending patches for a list of computers and store the results in an array

.EXAMPLE
Get-Content "C:\path\to\computers.txt" | Get-SCCMPendingPatches

Get pending patches for a list of computers using a text file

.EXAMPLE
Get-SCCMPendingPatches SERVER01 | % {Get-KbUpdate -Name $_.Name -Latest}

Get more detailed information about the patch by pipelining into Get-KBUpdate cmdlet from the kbupdate module, https://github.com/potatoqualitee/kbupdate. 

To install kbupdate module: (Admin required) "Install-Module kbupdate;Import-Module kbupdate"

#> 

function Get-SCCMPendingPatches {

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)][String[]]$ComputerName = $env:COMPUTERNAME
    )
    
    function Start-WinRMService {
        param (
            [string]$Computer
        )
        
        try {
            Write-Verbose "Checking WinRM service status on $Computer"
            
            $serviceStatus = Get-Service -ComputerName $Computer -Name WinRM -ErrorAction Stop | Select-Object -ExpandProperty Status
            
            if ($serviceStatus -eq "Stopped") {
                Write-Verbose "Starting WinRM service on $Computer"
                Start-Service -Name WinRM -ComputerName $Computer -ErrorAction Stop
                Write-Verbose "WinRM service started successfully on $Computer"
            }
            else {
                Write-Verbose "WinRM service is already running on $Computer"
            }
        }
        catch {
            Write-Verbose "Failed to start WinRM service on $Computer - $_"
        }
    }

    foreach ($Computer in $ComputerName) {
        if ($Computer -as [System.Net.IPAddress]) {
            # Resolving IPv4 to hostname
            try {
                $resolvedComputer = (Resolve-DnsName -Name $Computer -ErrorAction Stop).NameHost.Split('.')[0]
                $resolvedComputer = $resolvedComputer.ToUpper()  # Convert computer name to uppercase
                Write-Verbose "Resolved $Computer --> Hostname: $resolvedComputer "
            } catch {
                $resolvedComputer = $Computer
            }
        } else {
            $resolvedComputer = $Computer
        }
        
        
        Write-Verbose "Getting pending patches for computer: $resolvedComputer"
            
        try {
            # Test if the host is reachable using Test-Connection
            if (Test-Connection -ComputerName $resolvedComputer -Count 1 -ErrorAction Stop) {
                $namespace = "root\ccm\clientsdk"
                $class = "CCM_SoftwareUpdate"
                    
                $patches = Get-CimInstance -ComputerName $resolvedComputer -Namespace $namespace -ClassName $class |
                Where-Object { $_.ComplianceState -eq "0" }
                    
                if ($patches) {
                    $patches | ForEach-Object {
                        $_ | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $resolvedComputer -PassThru
                    } | Select-Object ComputerName, @{Name = "Article"; Expression = { "KB$($_.ArticleID)" } }, Name, Description, URL
                }
                else {
                    Write-Verbose "No patches required for computer: $resolvedComputer"
                }
            }
            else {
                Write-Verbose "Unable to establish connection with remote host: $resolvedComputer"
                Start-WinRMService -Computer $resolvedComputer
            }
        }
        catch {
            Write-Verbose "Error connecting to remote host: $resolvedComputer - $_"
        }
    }
}
# SIG # Begin signature block
# MIIFoAYJKoZIhvcNAQcCoIIFkTCCBY0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUs9NOBNfxV2ggvP0FvdolYRx8
# 8+ugggMqMIIDJjCCAg6gAwIBAgIQaR4m7KJl/JhC323QKJ9O5jANBgkqhkiG9w0B
# AQsFADArMSkwJwYDVQQDDCBHTy5NQVJLIERBTklFTC5FTVBMRU8uMTI0NjA3MjI3
# OTAeFw0yMjEyMTIxNTA0NTJaFw0yMzEyMTIxNTI0NTJaMCsxKTAnBgNVBAMMIEdP
# Lk1BUksgREFOSUVMLkVNUExFTy4xMjQ2MDcyMjc5MIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEAxgfUL1Ww3KK70xHNx71Zf+W9wNW5KsfqRRPHFZn9rnIm
# zf02Gzp5Vu/C13HQRO/xWdTk7ryHV+9gUFybH33PkoXNWj3L4CPILulZmXzsgCLf
# WfSTEqZ02ejyAqw4VF/2fcHSKRfhrzW5nUui5VYN40+sMF28MYuhTc1bND3EU1zV
# WFtp0pOk05EzPIvSw4ug59lyFI0YOsvt7+UPeGi7j90MaG0K3hIAEk9ZOKga0TQl
# 5TzCZfXKp/H2oEqccsHYKWhOKPLVi0qDyTYAKryEOf2/DDsd58k81Wb17lLLPFxG
# I1fctaDibVolk8G5SSDICqlcalxvxuFSPzgcS5BTsQIDAQABo0YwRDAOBgNVHQ8B
# Af8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFP9kdv0PT+I/
# O86gwFsTePID10IQMA0GCSqGSIb3DQEBCwUAA4IBAQAKI5tnzr98rAyw+NlVGtdu
# T44UhIzWj5NoHVioQx0SU5U6hl3Sqza2s3rP+QwzLgwjMjg/dhhQek06nxwZ1vmY
# qs+2Cm3NeAf8yhFOVt9lpWmrKpgeM9i5EDK1wh4ch2X/Ji4s2WszGaMBNPBT0dx8
# Mf2MopHtG2L+OG8pdEgcVlsEEIuDdxconI65L1ce7ry3gIFh7JZlfBAgf12hGBWY
# qVf+ghqIkUPvmYY5rhs5MqCfKI0YcjgCUcuLzzsCLpD66qacsoc+ZidIg5PFYGtm
# XlE1mgvunnjj7TRreN7USFxg3XPHA/U7JV2NoAiFNb+01NFMeROxKInEGvaDG9zO
# MYIB4DCCAdwCAQEwPzArMSkwJwYDVQQDDCBHTy5NQVJLIERBTklFTC5FTVBMRU8u
# MTI0NjA3MjI3OQIQaR4m7KJl/JhC323QKJ9O5jAJBgUrDgMCGgUAoHgwGAYKKwYB
# BAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAc
# BgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUURzj
# qCjGA07TnvvANGJd5GhEDZIwDQYJKoZIhvcNAQEBBQAEggEAxbv6If8JDA/CqI/N
# OvEd3fUnlChPBkfzRqKIy5Z3bH3Yia2FoSpnAdVjR7YwkT/2nNOs33rBN/BLlc2A
# AqmHox5NjtzMI1zrhlcKHejGsXFwSNI4YgALHtv6GyJjTJKoFd1h3fLOlqrr/mTe
# JuRFFR1cTNCQnQeT9+VtaNDNCrg+it74ckL2baVHaWUkGqPDmZtqFFMwuG4feaDe
# Jd7h9+9AzztGWcXbV1i4/hmSZp0Ovh3Y2yvYKz/JgiQqRvW2O240wHQOPsc0r/Uy
# feC0tS5utY1KlE5MVyn5ErO+ae1pYbvU9Uyo5OKDJpQMIJ2KwL22+VP2IoQREau6
# cYYfEA==
# SIG # End signature block
