function Get-KBEventLogs {
    [CmdletBinding()]
    param (
        [int]$Lookback = 1, # Number of days to look back for event logs. Default is 1 day.
        [string]$KBNumber # Specific KB (Knowledge Base) number to filter the logs.
    )
    
    # Calculate the start date for log lookup based on the lookback period.
    $StartDate = (Get-Date).AddDays(-$Lookback).Date
    
    # Retrieve the latest 100 event logs from the Windows Update Client provider.
    $events = Get-WinEvent -ProviderName "Microsoft-Windows-WindowsUpdateClient" -MaxEvents 100 |
        Where-Object {
            $_.TimeCreated -ge $StartDate # Filter logs to only include those on or after the start date.
        } | ForEach-Object {
            # Extract the KB number from the event log message.
            $kbMatch = $_.Message | Select-String -Pattern "KB\d{7,8}" -AllMatches
            # Get the first KB number match, if any. If none, set to $null.
            $kb = if ($kbMatch.Matches.Count -gt 0) { $kbMatch.Matches[0].Value } else { $null }

            # Add the extracted KB number as a new property to the event object.
            $_ | Add-Member -MemberType NoteProperty -Name "KBnumber" -Value $kb
            $_ # Return the modified event object.
        }
    
    # If a specific KB number is provided, filter the events to only include logs with that KB number.
    if ($KBNumber) {
        $events = $events | Where-Object { $_.KBnumber -eq $KBNumber } 
    }

    # Return the final collection of event logs.
    $events | select *
}
