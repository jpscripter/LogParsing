
Function Get-LogEntryFromCM { 
    <#
.SYNOPSIS
Used to parse one of the Configmgr log file format. 

.DESCRIPTION
This format is specific to the Configmgr log format that has some attributes separated by the $$

.PARAMETER LogContent
the -raw log content that you want broken into different entries. 

.PARAMETER Source
What is the files name

.PARAMETER AllDetails
Does nothing and is for splatting in the main get-log cmdlet. This is mostly only for CMXML and iis logs 

.EXAMPLE
$LogSplat = @{
    AllDetails = $AllDetails.IsPresent
    LogContent = $LogContent
}
$logEntries = Get-LogEntryFromCM @LogSplat 

.LINK
http://www.JPScripter.com
#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [string]$Source,
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
            if ([string]::IsNullOrEmpty($Message)){Continue}
            $entry.Message = $message
            $entry.Source = $source
            $entry.Component = $match.groups[2].value
            $entry.thread = $match.groups[4].value 
            $entry.severity = Get-LogEntrySeverity -Message $message
            if ($entry.severity -eq [severity]::Error){
                [int]$errorcode = Get-LogEntryErrorMessage -message $message
                if ($errorcode -eq 0){
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
                        Write-verbose -message "Could not convert $errorcode to error message:`n$message"
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