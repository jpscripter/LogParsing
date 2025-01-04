
Function Get-LogEntryFromMSI { 
<#
.SYNOPSIS
Used to parse an MSI log file format. 

.DESCRIPTION
This format is specific to the msi log format and requires the date to be passed-in because the full date isnt on each line of the log

.PARAMETER LogContent
the -raw log content that you want broken into different entries. 

.PARAMETER AllDetails
Does nothing and is for splatting in the main get-log cmdlet. This is mostly only for CMXML and iis logs 

.PARAMETER date
string date in in the dd\MM\yyyy format that is used to parse the full date from the log entries.

.EXAMPLE
$LogSplat = @{
    AllDetails = $AllDetails.IsPresent
    LogContent = $LogContent
}
$logEntries = Get-LogEntryFromMSI @LogSplat -Date '05\20\2023'

.LINK
http://www.JPScripter.com
#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [string]$Source,
        [string]$date,
        [switch] $AllDetails
    )
    Begin{
    }
    Process {

        # find new entries
        $lines = $LogContent.split("`n")
        $logEntries = new-object -TypeName Collections.arraylist
        :line foreach($line in $lines){
            if($line.StartsWith('MSI')){
                if ($entry){
                    #Finalize entry
                    $entry.Message = $Message
                    $entry.Source = $source
                    $entry.severity =  Get-LogEntrySeverity -Message $message
                    if ($entry.severity -eq [severity]::Error){
                        [int]$errorcode = Get-LogEntryErrorMessage -message $message
                        if ($errorcode -eq 0){
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
                    $null = $logEntries.add($entry)
                }

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
        $entry.Message = $Message.Trim()
        $entry.severity =  Get-LogEntrySeverity -Message $message

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
                    Write-verbose -message "Could not convert $errorcode to error message"
                }
            }
        }
        
        $null = $logEntries.add($entry)
    }
    End {
        $logEntries
    }
}