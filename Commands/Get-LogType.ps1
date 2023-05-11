
Function Get-LogType { 
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
            $sr.BaseStream.Position = 0
            $LogDetails.StreamReader = $sr
            $script:LogFiles.add($File.FullName,$LogDetails)
        
        }
    }
    End {
        $script:LogFiles[$File.FullName].Type
    }
}