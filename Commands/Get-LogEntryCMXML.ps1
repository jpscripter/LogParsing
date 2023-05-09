
Function Get-LogEntryCMXML { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [System.IO.FileInfo]$File,
        [switch] $AllDetails
    )
    Begin{
        $XMLpattern = '<\!\[LOG\[(.*)]LOG]\!><(.*)>'
    }
    Process {
        #wait-debugger
        if (-not $file.Exists){
            Write-Warning -Message "File not found: $($File.Fullname)"
            return
        }

        #Override if called directly and not in memory
        if (-not $script:LogFiles.contains($File.FullName)){
            #Get First line for match
            $fs = [System.IO.FileStream]::new($File.fullname, 'Open', 'Read', [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
            $sr = [System.IO.StreamReader]::new($fs)
            $LogDetails = new-object -TypeName LogDetails 
            $LogDetails.Type = 'CMXMLLog'
            $LogDetails.StreamReader = $sr
            $script:LogFiles.add($File.FullName,$LogDetails)
        }else{
            $sr = $script:LogFiles[$File.FullName].StreamReader
        }
            
        # find new entries
        $LogContent = $sr.ReadToEnd()
        $matches = [regex]::matches($LogContent,$XMLpattern)
        $logEntries = new-object -TypeName System.Collections.Generic.List[LogEntry]
        foreach($match in $matches){
            $DetailRow = $match.groups[2].value.split(' ')
            $DetailsHash = @{}
            foreach ($detail in $DetailRow){
                try{
                    $name = $detail.split('=')[0]
                    $value = $detail.split('=')[1] -replace '"',''
                    $DetailsHash.add($name,$value)
                }
                Catch{
                    Write-warning -Message "$name duplicated for $file"
                }
            }

            #build entry
            $entry = new-object logEntry
            $entry.Message = $match.groups[1].value
            $entry.Component = $DetailsHash['component']
            $entry.thread = $DetailsHash['thread']
            if ($AllDetails.IsPresent){
                $entry.details = $DetailsHash | ConvertTo-Json
            }
            $DateTimeString = "$($DetailsHash['Date']) $($DetailsHash['time'].split('.')[0])"
            $datetime = 0
            $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            $entry.datetime = $datetime
            $logEntries.add($entry)
        }

        #save to memory and return
        if ($script:LogFiles[$File.FullName].LogEntry.count -eq 0){
            $script:LogFiles[$File.FullName].LogEntry = $logEntries
        }else{
            $script:LogFiles[$File.FullName].LogEntry.addrange($logEntries)
        }
        $script:LogFiles[$File.FullName].LogEntry 

    }
    End {
    }
}