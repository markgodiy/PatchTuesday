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

        $result = 0

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
            if ($result.SDKversion -notin $results.SDKversion) {
            $results += $result
            }
        
            if ($firstResultLine -eq 0) {
                $firstResultLine = $lineNumber
            }
        }
    }

    # Group the results by Version, SDKversion, and Releasedate, and select the first item from each group
    $uniqueResults = $results | Group-Object SDKversion, CoreVersion, Releasedate | ForEach-Object { $_.Group[0] }

    # Iterate through the unique results and add the DownloadUrl and Type properties
    $uniqueResults | ForEach-Object {
        $DownloadURL = Get-DownloadURL $_.SDKversion
        $_ | Add-Member -MemberType NoteProperty -Name "DownloadUrl" -Value $DownloadURL -PassThru | Out-Null
    }

    # Display the unique results
    $uniqueResults 
}
