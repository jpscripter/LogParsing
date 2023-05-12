
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
        $LogMatches = [regex]::matches($LogContent,$pattern)
        $logEntries = new-object -TypeName Collections.arraylist
        foreach($match in $LogMatches){
            $DetailRow = $match.groups[2].value.split(' ')
            $Loghash = @{}
            foreach ($detail in $DetailRow){
                try{
                    $name = $detail.split('=')[0]
                    $value = $detail.split('=')[1] -replace '"',''
                    $Loghash.add($name,$value)
                }
                Catch{
                    Write-warning -Message "$name duplicated for $file"
                }
            }

            #build entry
            $entry = new-object logEntry
            $entry.Message = $match.groups[1].value
            $entry.Component = $Loghash['component']
            $entry.thread = $Loghash['thread']

            $Detailshash = @{}
            if ($AllDetails.IsPresent){
                $DetailsHash += $Loghash
            }

            $DateTimeString = "$($DetailsHash['Date']) $($DetailsHash['time'].split('.')[0])"
            $datetime = 0
            $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            $entry.datetime = $datetime
            
            $entry.severity = Get-LogEntrySeverity -Message $match.groups[1].value
            if ($entry.severity -eq [severity]::Error){
                [int]$errorcode = Get-LogEntryErrorMessage -message $message
                if ($errorcode -eq 0 ){
                    $entry.severity = [Severity]::normal
                }else{
                    Try{
                        $ErrorHash = @{
                            Errorcode = $errorcode
                            ErrorMessage = [System.ComponentModel.Win32Exception]$errorcode
                        }
                        $DetailsHash += $ErrorHash
                    }
                    Catch{
                        Write-verbose -message "Could not convert $errorcode to error message"
                    }
                }
            }
            $entry.details = [PSCustomObject]$DetailsHash
            $null = $logEntries.add($entry)
        }
    }
    End {
        $logEntries
    }
}