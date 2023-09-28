<#

.DESCRIPTION
Author: Mark Go
Purpose: Get latest .NET SDK version and download link

.NOTES
Internet connection required to reach dotnet URL. https://dotnet.microsoft.com/en-us/download

.EXAMPLE
Get-DotNETLatest

Other Links for future revision purposes? 
$x86href="https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-$($version)-windows-x86-installer"
$arm64href="https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-$($version)-windows-arm64-installer"
$macos_intel64href="https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-$($version)-macos-x64-installer"
$macos_ARMhref="https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-$($version)-macos-arm64-installer"

#>

function Get-DotNETLatest {

    # Function to extract major version from a given number
    function Get-MajorSDKVersion ($number) {
        $majorVersionPattern = "$($number)\.\d+\.\d+"
        foreach ($line in ($script:dotnetmainpage -split "`r`n")) {
            if ($line -match $majorVersionPattern) {
                Return $Matches[0]
            } 
        }
    }

    # Function to get the download URL for a specific SDK version
    function Get-DownloadURL ($SDKversion) {
        $x64href = "https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-$SDKversion-windows-x64-installer"        
        $dotnetinstallersite = (Invoke-WebRequest $x64href).Content
        if ($dotnetinstallersite -match "https:\/\/download\.visualstudio\.microsoft\.com\/download\/pr\/[a-f\d-]+\/[a-f\d-]+\/dotnet-sdk-\d+\.\d+\.\d+-win-x64\.exe") {
            Return $matches[0]           
        }
    }

    # Go to .NET website and get html content
    $script:dotnetmainpage = (iwr https://dotnet.microsoft.com/en-us/download).Content

    # Split the input string into lines
    $lines = $dotnetmainpage -split "`r`n"

    # Initialize the line number where the first result was found
    $firstResultLine = 0

    # Initialize an array to store results
    $results = @()

    # Iterate through the lines to find version information
    foreach ($lineNumber in $firstResultLine..($lines.Length - 1)) {

        $line = $lines[$lineNumber]
    
        $versionpattern = 'Version (\d+\.\d+\.\d+), released (January|February|March|April|May|June|July|August|September|October|November|December) (\d{1,2}), (\d{4})'

        if ($line -match $versionpattern) {

            $result = [pscustomobject]@{
                Name         = "DotNET"
                SDKversion   = Get-MajorSDKVersion ($(($Matches[1] -split "\."))[0])
                CoreVersion  = $Matches[1]
                Releasedate  = $(get-date "$($Matches[4]) $($Matches[2]) $($Matches[3])" -Format "yyyy-MMM-dd")
            }

            # Add the result to the array if the version is not already present
            if ($result.version -notin $results.Version) {
                $results += $result
            }
        
            if ($firstResultLine -eq 0) {
                $firstResultLine = $lineNumber
            }
        }
    }

    # Group the results by Version, SDKversion, and Releasedate, and select the first item from each group
    $uniqueResults = $results | Group-Object CoreVersion, SDKversion, Releasedate | ForEach-Object { $_.Group[0] }

    # Iterate through the unique results and add the DownloadUrl and Type properties
    $uniqueResults | ForEach-Object {
        $DownloadURL = Get-DownloadURL $_.SDKversion
        $_ | Add-Member -MemberType NoteProperty -Name "DownloadUrl" -Value $DownloadURL -PassThru | Out-Null
    }

    # Display the unique results
    $uniqueResults 
}


# SIG # Begin signature block
# MIIFoAYJKoZIhvcNAQcCoIIFkTCCBY0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdYHsftxvSVp5gJBVZ6bZHmC0
# VvegggMqMIIDJjCCAg6gAwIBAgIQaR4m7KJl/JhC323QKJ9O5jANBgkqhkiG9w0B
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
# BgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUXoug
# nkO53m+BHPQAAMHn7B6kGFowDQYJKoZIhvcNAQEBBQAEggEARitdzqdy0ev0i8gO
# 0nmGHg1KqZNqUfSuq99yLvnpLKTDSzLH6QHpOc2d3wL9OwAQk/FKGdYQ9TV4yU2A
# VzPJG80D4/TeYUMfttzsUCHcdqyQOT+rbcFiIz6VMg3c4N3QFeL8LZ9f5e8AzkOh
# v7zU/Gjs3V2ZRQvPBr2Juys4CbN4lCoh7Up3lwkSYrordXkOAUiFj3k1CLobsgBf
# pdhcUWSKC5564uEpehtP1GmrDRJ0M69S136joQ4IDf7pka3V4rAai5b57v6I4oZs
# iQrPvm58lsnKKm4wwgXRjpaMpv6Haipr9oByn0qYFQQAePuq//OPtMRIa9RL/6M4
# fiyPrA==
# SIG # End signature block
