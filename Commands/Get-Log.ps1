
Function Get-Log { 
<#
.SYNOPSIS
Used to get the parsed log content for a log. 

.DESCRIPTION
This is the entry point for each of the specific log formats. It will determine the log format and parse it accordingly. 

.PARAMETER Credential
Credential to log in with

.PARAMETER LogonType
How this credential will log in (Default is NetOnly but Interactive is also common)

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
            if ($script:LogFiles[$File.FullName].StreamReaderPosition -le $sr.BaseStream.length){
                $sr.BaseStream.Position = $script:LogFiles[$File.FullName].StreamReaderPosition
            }
        }
        
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

        #close stream
        $sr.close()
        $sr.Dispose()
        $FS.Close()
        $FS.Dispose()
    }
    End {
    }
}