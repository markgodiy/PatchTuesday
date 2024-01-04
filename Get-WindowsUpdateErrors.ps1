function Get-WindowsUpdateErrors {
    [CmdletBinding()]
    param (
    )

    begin {
        # Initialize an empty array
        $updateErrors = @()
    }

    process {
        # Query the event log and process each relevant entry
        Get-WinEvent -LogName System |
        Where-Object {
            $_.ProviderName -eq 'Microsoft-Windows-WindowsUpdateClient' -and
            $_.Message -match 'Installation Failure: Windows failed to install the following update'
        } |
        ForEach-Object {
            # Extract the update title from the message
            $updateTitle = $_.Message -split 'Installation Failure: Windows failed to install the following update' | Select-Object -Last 1

            # Create a custom object with the desired information
            $updateDetails = [PSCustomObject]@{
                FailedOn    = $_.TimeCreated
                UpdateTitle = $updateTitle.Trim()
            }

            # Add the object to the array
            $updateErrors += $updateDetails
        }
    }

    end {
        # Output the array containing Windows Update errors
        $updateErrors
    }
}
