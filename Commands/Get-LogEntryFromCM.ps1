
Function Get-LogEntryFromCM { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [switch] $AllDetails
    )
    Begin{
        $pattern = '(.*)\$\$<(.*)><(.*)><thread=([0-9]*).*>'
    }
    Process {

        # find new entries
        $LogMatches = [regex]::matches($LogContent,$pattern)
        $logEntries = new-object -TypeName Collections.arraylist
        foreach($match in $LogMatches){
           
            #build entry
            $entry = new-object logEntry
            $entry.Message = $match.groups[1].value
            $entry.Component = $match.groups[2].value
            $entry.thread = $match.groups[4].value
            $DateTimeString = "$($match.groups[3].value.split('.')[0])"
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