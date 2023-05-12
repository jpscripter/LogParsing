
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
            $message =  $match.groups[1].value
            $entry.Message = $message
            $entry.Component = $match.groups[2].value
            $entry.thread = $match.groups[4].value 
            $entry.severity = Get-LogEntrySeverity -Message $message
            if ($entry.severity -eq [severity]::Error){
                [int]$errorcode = Get-LogEntryErrorMessage -message $message
                if ($errorcode -eq 0 ){
                    $entry.severity = [Severity]::normal
                }else{
                    Try{
                        $DetailsHash = [PSCustomObject]@{
                            Errorcode = $errorcode
                            ErrorMessage = [System.ComponentModel.Win32Exception]$errorcode
                        }
                        $entry.details = $DetailsHash
                    }
                    Catch{
                        Write-verbose -message "Could not convert $errorcode to error message"
                    }
                }
            }
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