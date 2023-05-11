
Function Get-LogEntryFromMSI { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [string]$date,
        [switch] $AllDetails
    )
    Begin{
        $pattern = 'MSI\s\(s|c\)'
    }
    Process {

        # find new entries
        $lines = $LogContent.split("`n")
        $logEntries = new-object -TypeName Collections.arraylist
        foreach($line in $lines){
            if ($entry -and $line.StartsWith('MSI')){
                #Finalize entry
                $entry.Message = $Message
                $entry.severity =  Get-LogEntrySeverity -Message $message
                $null = $logEntries.add($entry)

                #start next entry
                $entry = new-Object LogEntry
                $index = $line.IndexOf(']:')
                $Message = $line.substring($index+2)
                if ($line -like ("MSI ([cC])*")){
                    $Component = 'Client'
                }else{
                    $Component = 'Server'
                }
                $entry.Component = $Component
                $time = $line.Substring($line.indexof('[')+1,8)
                $entry.Datetime = "$Date $time"
                if ($Details.IsPresent)
                {
                    $Detailsline = $line.Substring($line.indexof('(')+1,9)
                    $Detailsline = $Detailsline.Substring($Detailsline.indexof('(')+1,5)
                    $entry.Details = $Detailsline
                }
            }else{
                $message += "`n$line" 
            }

        }
        #get last item
        $entry.Message = $Message
        $entry.severity =  Get-LogEntrySeverity -Message $message
        $null = $logEntries.add($entry)
    }
    End {
        $logEntries
    }
}