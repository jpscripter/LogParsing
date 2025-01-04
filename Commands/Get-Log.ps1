
Function Get-Log { 
<#
.SYNOPSIS
Used to get the parsed log content for a log. 

.DESCRIPTION
This is the entry point for each of the specific log formats. It will determine the log format and parse it accordingly. 

.PARAMETER Tail
Only Read the last part of the log. Length of the file in characters less this tails offset will be the start position.

.PARAMETER AllDetails
Include all details that could be parsed from the file. 

.PARAMETER NewContentOnly
Only returns the content that was written since the last read.

.EXAMPLE
PS> $Cred = Get-Credential
Get-CredentialToken -Credential $Cred

.LINK
http://www.JPScripter.com

#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [System.IO.FileInfo]$File,
        [int]$Tail = 0,
        [switch] $AllDetails,
        [switch] $NewContentOnly
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
        $fs = [System.IO.FileStream]::new($File.fullname, 'Open', 'Read', [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
        $sr = [System.IO.StreamReader]::new($fs);
        
        #Pickup where we left off unless the log rolled over
        if ($NewContentOnly.IsPresent){
            if ($script:LogFiles[$File.FullName].StreamReaderPosition -eq $sr.BaseStream.length){
                return
            }elseif($script:LogFiles[$File.FullName].StreamReaderPosition -lt $sr.BaseStream.length){
                $sr.BaseStream.Position = $script:LogFiles[$File.FullName].StreamReaderPosition
            }
        # if new log and only grabbing the last part of the log
        }elseif(($tail -ne 0)){
            $newLocation = $sr.BaseStream.Length - $tail
            if ($newLocation -gt $sr.BaseStream.position -and $newLocation -lt $sr.BaseStream.length){
                $sr.BaseStream.position = $newLocation
            } else{
                Write-Warning -Message "$tail offset is out of the range of the file."
            }
        }
        
        # find new entries
        $LogContent = $sr.ReadToEnd()
        $script:LogFiles[$File.FullName].StreamReaderPosition = $sr.BaseStream.Position 

        if (-not [string]::IsNullOrWhiteSpace($LogContent)){
            $LogSplat = @{
                AllDetails = $AllDetails.IsPresent
                LogContent = $LogContent
                Source = $script:LogFiles[$File.FullName].Source
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
            if ($script:CacheLogs){
                $script:LogFiles[$File.FullName].LogEntry += $logEntries
            }
        }
        $logEntries

        #close stream
        $sr.close()
        $sr.Dispose()
        $FS.Close()
        $FS.Dispose()
    }
    End {
    }
}