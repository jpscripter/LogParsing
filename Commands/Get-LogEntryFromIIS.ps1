
Function Get-LogEntryFromIIS { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [string] $headers
    )
    Begin{
        $HeadersNames = $headers.Split()
    }
    Process {

        # find new entries
        $matches = $LogContent.split("`n")
        $logEntries = new-object -TypeName System.Collections.Generic.List[LogEntry]
        foreach($match in $matches){
            if ($match.StartsWith('#')){Continue}
            $DetailRow = $match.split()
            $DetailsHash = @{}
            for($i = 0; $I -lt $DetailRow.count; $i++){
                try{
                    $name = $HeadersNames[$i]
                    $value = $DetailRow[$i]
                    $DetailsHash.add($name,$value)
                }
                Catch{
                    Write-warning -Message "$name duplicated for $file"
                }
            }

            #skip empty rows
            if ($DetailsHash.Keys.count -le 1){
                Continue
            }

            #build entry
            $entry = new-object logEntry
            $entry.Message = $match
            $entry.Component = $DetailsHash['cs-uri-stem']
            $entry.thread = $DetailsHash['s-port']
            
            # custom iis errors
            switch ($DetailsHash['sc-status']){
                '200'{
                    $entry.severity = 'normal'
                    break
                }
                '404'{
                    $entry.severity = 'warning'
                    break
                }
                default {
                    $entry.severity = 'Error'
                    break
                }
            }

            #skip if cant passe date
            if ( $DetailsHash.ContainsKey('Date') -and $DetailsHash.ContainsKey('time')){
                if ($AllDetails.IsPresent){
                    $entry.details = $DetailsHash | ConvertTo-Json
                }
                $DateTimeString = "$($DetailsHash['Date']) $($DetailsHash['time'].split('.')[0])"
                $datetime = 0
                $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            }
            $entry.datetime = $datetime
            $null = $logEntries.add($entry)
        }
    }
    End {
        $logEntries
    }
}