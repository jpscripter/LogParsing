
Function Get-LogEntryFromUnknown{ 
<#
.SYNOPSIS
Used to parse an unknown file format. This mostly looks for keywords and dates.

.DESCRIPTION
This is the catchall for unknown log formates. if there is a common log format for your organization, you should add it to the modules by updating the get-logtype cmdlet and adding your own parsing logic. 

.PARAMETER LogContent
the -raw log content that you want broken into different entries. 

.PARAMETER AllDetails
Does nothing and is for splatting in the main get-log cmdlet. This is mostly only for CMXML and iis logs 

.EXAMPLE
$LogSplat = @{
    AllDetails = $AllDetails.IsPresent
    LogContent = $LogContent
}
$logEntries = Get-LogEntryFromUnknown @LogSplat

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
            if ([string]::IsNullOrEmpty($match)){Continue}
            $entry.Message = $match
            $entry.Source = $source
            if ([String]::IsNullOrWhiteSpace($match)){Continue}
            $entry.Severity = Get-LogEntrySeverity -message $match
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