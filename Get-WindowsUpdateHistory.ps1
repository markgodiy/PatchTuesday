function Get-WindowsUpdateHistory {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        # Initialize an empty array
        $updateHistory = @()
    }
    
    process {

        # Define a helper function to categorize updates
        function Categorize-Update ($title) {
            if ($title -match "Security") { return "Security Update" }
            elseif ($title -match "Cumulative" -or $title -match "Quality") { return "Quality Update" }
            elseif ($title -match "Feature") { return "Feature Update" }
            elseif ($title -match "Driver") { return "Driver Update" }
            elseif ($title -match "Definition") { return "Definition Update" }
            else { return "Other Update" }
        }
        
        # Query the event log and process each relevant entry
        Get-WinEvent -LogName System | 
        Where-Object {
            $_.ProviderName -eq 'Microsoft-Windows-WindowsUpdateClient' -and
            $_.Message -match 'Installation Successful: Windows successfully installed the following update:'
        } |
        ForEach-Object {
            # Extract the update title from the message
            $updateTitle = $_.Message -split 'Windows successfully installed the following update:' | Select-Object -Last 1
        
            # Create a custom object with the desired information
            $updateDetails = [PSCustomObject]@{
                InstalledOn = $_.TimeCreated
                Category    = Categorize-Update -title $updateTitle
                UpdateTitle = $updateTitle.Trim()
            }
        
            # Add the object to the array
            $updateHistory += $updateDetails
        }
        

    }
    
    end {
        # Output the array
        $updateHistory
    }
}