
Function Get-LogEntryFromCMXML { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [switch] $AllDetails
    )
    Begin{
        $pattern = '<\!\[LOG\[(.*)]LOG]\!><(.*)>'
    }
    Process {

        # find new entries
        $matches = [regex]::matches($LogContent,$pattern)
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
                $entry.details = [PSCustomObject]$DetailsHash 
            }

            $DateTimeString = "$($DetailsHash['Date']) $($DetailsHash['time'].split('.')[0])"
            $datetime = 0
            $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            $entry.datetime = $datetime
            
            $entry.severity = 
            $null = $logEntries.add($entry)
        }
    }
    End {
        $logEntries
    }
}