
Function Get-Log { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [System.IO.FileInfo]$File,
        [switch] $AllDetails
    )
    Begin{
        $DatePattern = '\d{1,2}[\/]\d{1,2}[\/]\d{4}'
        $IISFieldsPattern = '#Fields:(.*)'
    }
    Process {
        #wait-debugger
        if (-not $file.Exists){
            Write-Warning -Message "File not found: $($File.Fullname)"
            return
        }

        #Override if called directly and not in memory
        $logType = Get-logtype -File $file 
        $sr = $script:LogFiles[$File.FullName].StreamReader
        
            
        # find new entries
        $LogContent = $sr.ReadToEnd()
        if (-not [string]::IsNullOrWhiteSpace($LogContent)){
            $LogSplat = @{
                AllDetails = $AllDetails.IsPresent
                LogContent = $LogContent
            }
            switch ($LogType){
                'CMXML' {
                    $logEntries = Get-LogEntryFromCMXML @LogSplat
                }
                'CM' {
                    $logEntries = Get-LogEntryFromCM @LogSplat
                }
                'IIS' {
                    $headers = $script:LogFiles[$File.FullName].logParsingParams
                    if ([string]::IsNullOrWhiteSpace($headers)){
                        $headers = [regex]::match($LogContent,$IISFieldsPattern ).value
                        $headers = $headers.Substring($headers.IndexOf(':')+2)
                        $script:LogFiles[$File.FullName].logParsingParams = $headers
                    }
                    $logEntries = Get-LogEntryFromIIS @LogSplat -Headers $headers
                }
                'MSI' {
                    $date = $script:LogFiles[$File.FullName].logParsingParams
                    if ([string]::IsNullOrWhiteSpace($date)){
                        $date = [regex]::match($LogContent,$DatePattern).value
                        $script:LogFiles[$File.FullName].logParsingParams = $date
                    }
                    $logEntries = Get-LogEntryFromMSI @LogSplat -date $date
                }
                'Unknown' {
                    $logEntries = Get-LogEntryFromUnknown @LogSplat
                }
            }
        
            #save to memory and return
            #wait-debugger
            $script:LogFiles[$File.FullName].LogEntry += $logEntries
        }
        $script:LogFiles[$File.FullName].LogEntry 

    }
    End {
    }
}