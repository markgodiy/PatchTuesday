function Convert-DataFeedToCSV {
    <# 
    .DESCRIPTION
        Author. Mark Go.
        This script will open an Excel workbook, refresh all data connections, and save the first worksheet as a CSV file in the same directory as the input file. If no output file is specified, the CSV file will be saved in the same directory as the input file, with the same name as the input file, but with a CSV extension.
    
    .PARAMETER InputFile
        The full path to the Excel workbook to open.

    .PARAMETER OutputFile
        The full path to the CSV file to save.
    
    .PARAMETER Visible
        If specified, the Excel window will be visible. Otherwise, it will be hidden.
    
    .EXAMPLE
        Import-CNDDataFeed -InputFile "C:\Temp\MyWorkbook.xlsx" -Visible
    
    .LINK
    
    
    #>
    [cmdletbinding()]
    param(    
        $InputFile,
        $OutputFile,
        [switch]$Visible
        )
    
    begin {
    
        # Check if the input file exists
        if (-not $InputFile) {
            Write-Error "InputFile parameter is required"
            Break
        } elseif (-not (Test-Path $InputFile)) {
            Write-Error "InputFile not found: $InputFile"
            Break
        } else {
            $file = (Get-Item $InputFile).FullName
        }
    
        # If no output file is specified, use the same path as the input file, but with a CSV extension
        if (-not $OutputFile) {
            $outputFile = $outputFile = (Get-Item $InputFile).DirectoryName +"\"+ (Get-Item $InputFile).BaseName + ".csv"
        }
        Write-Verbose "OutputFile: $outputFile"


    
        # Create a new Excel Application object
        Write-Verbose "Creating Excel Application object"
        $x1 = New-Object -ComObject "Excel.Application"
        $x1.DisplayAlerts = $false
        $x1.Visible = $false
        
        # Make the Excel window invisible (optional), Display Alerts
        if ($Visible) {
            $x1.Visible = $true
            $x1.DisplayAlerts = $True
        }
        
    } process {
        # Open the workbook
        Write-Verbose "Opening workbook: $file" 
        $wb = $x1.Workbooks.Open($file)
    
        # Refresh all data connections in the workbook
        Write-Verbose "Refreshing all data connections in the workbook"
        $wb.RefreshAll()
    
        while ($wb.Connections | Where-Object { $_.Refreshing -eq $true }) {
            $wb.Connections
            Write-Verbose "Waiting for refresh to complete..."
            Start-Sleep -Seconds 1
        }
    
        # Save the workbook as CSV
        try {
            $ws = $wb.Worksheets.Item(1) # Get the first worksheet
            write-verbose "Recalculating worksheet 1"
            $ws.Calculate()
            write-verbose "Saving worksheet 1"
            $ws.SaveAs($outputFile, [Microsoft.Office.Interop.Excel.XlFileFormat]::xlCSV) 
            Write-Output "CSV File saved successfully`r`n`n$outputFile`r`n"
            Get-ChildItem $outputFile
            Write-Output "`r`n"
            $x1.DisplayAlerts = $true
        }
        catch {
            Write-Error "Error saving file: $_"
        }
    
    } end {
    
        # Close the workbook and quit Excel
        Write-verbose "Closing workbook and quitting Excel"
        $wb.Close()
        $x1.Quit()
    
        # Release COM objects
        Write-Verbose "Releasing COM objects"
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($x1) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    
    }
    } # End function Import-CNDDataFeed
    