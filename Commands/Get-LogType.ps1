
Function Get-LogType { 
    <#
.SYNOPSIS
Used to quickly and efficiantly get the log format. 

.DESCRIPTION
This cmdlet is supposed to be as efficiant as possible and find the log formate for the log. We then save use a module scope script variable to record that for future lookup. This lets us know the log format and write more targetted parsing. 

.PARAMETER File
File object to the log file

.EXAMPLE
PS C:\> Get-LogType -File C:\TestLogs\ConfigMgrAdminUISetup.log
CMXML

.LINK
http://www.JPScripter.com
#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [System.IO.FileInfo]$File
    )
    Begin{
        $CMpattern = '(.*)\$\$<(.*)><(.*)><thread=([0-9]*).*>'
        $XMLpattern = '<\!\[LOG\[(.*)]LOG]\!>'
        $IISPattern = 'Internet Information Services'
        $MSIPattern = 'MSI\s\(.\)\s\(.*\)\s\[[\d:]*\]:'
    }
    Process {
        #wait-debugger
        if (-not $file.Exists){
            Write-Warning -Message "File not found: $($File.Fullname)"
            return
        }
        if (-not $script:LogFiles.contains($File.FullName)){
            #Get First line for match
            $fs = [System.IO.FileStream]::new($File.fullname, 'Open', 'Read', [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
            $sr = [System.IO.StreamReader]::new($fs);
            
            #Find Type
            # we loop here in case where is a header to the log that needs to be ingored.
            $logType = 'unknown'
            for($i = 0; $i -lt 50; $i++){
                #break if we know what it is
                if ($logType -ne 'unknown'){Break}

                $Line = $sr.ReadLine()
                # Fine type
                $LogType = $null
                Switch -regex ($line)  {
                    $CMpattern {
                        $logType = 'CM'
                        Break
                    }
                    $XMLpattern {
                        $logType = 'CMXML'
                        Break
                    }
                    $IISPattern {
                        $logType = 'IIS'
                        Break
                    }
                    $MSIPattern {
                        $logType = 'MSI'
                        Break
                    }
                    Default {
                        $logType = 'unknown'
                    }
                }
                #break for end of file
                if ($sr.EndOfStream){
                    Break
                }
            }

            #Make memory Object
            $LogDetails = new-object -TypeName LogDetails 
            $LogDetails.Type = $logtype
            $LogDetails.Source = $File.FullName
            $sr.close()
            $sr.Dispose()
            $FS.Close()
            $FS.Dispose()
            $LogDetails.StreamReaderPosition = 0
            $script:LogFiles.add($File.FullName,$LogDetails)
        
        }
    }
    End {
        $script:LogFiles[$File.FullName].Type
    }
}