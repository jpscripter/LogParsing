
Function Get-LogEntryFromUnknown{ 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [switch] $AllDetails
    )
    Begin{
        $DatePattern = '\d{1,2}[\/-]\d{1,2}[\/-]\d{4}'
        $TimePattern = '\d{1,2}[:]\d{1,2}(([:]\d{1,4})|)'
    }
    Process {

        # find new entries
        $LogMatches = $LogContent.Split("`n")
        $logEntries = new-object -TypeName Collections.arraylist
        foreach($match in $LogMatches){
            #build entry
            $entry = new-object logEntry
            $entry.Message = $match
            if ([String]::IsNullOrWhiteSpace($match)){Continue}
            $entry.Severity = Get-LogEntrySeverity -message $match

            $Date = [regex]::match($match, $DatePattern).value
            $Time = [regex]::match($match, $TimePattern).value
            $DateTimeString = "$date $Time"
            $datetime = 0
            $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            $entry.datetime = $datetime
            $null = $logEntries.add($entry)
        }
    }
    End {
        $logEntries
    }
}