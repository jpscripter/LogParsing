
Function Get-LogEntryFromCMXML { 
<#
.SYNOPSIS
Used to parse one of the Configmgr log file format. THis formate has an XML like attribute tag for each line. 

.DESCRIPTION
This format is specific to the Configmgr log format and pulls the XML like attributes on each line

.PARAMETER LogContent
the -raw log content that you want broken into different entries. 

.PARAMETER AllDetails
This creates a PSCustom object for all of the properties in the XML attributes tag for advanced usage.

.EXAMPLE
$LogSplat = @{
    AllDetails = $AllDetails.IsPresent
    LogContent = $LogContent
}
$logEntries = Get-LogEntryFromCMXML @LogSplat 

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
            if ([string]::IsNullOrEmpty($match.groups[1].value)){Continue}
            $entry.Message = $match.groups[1].value
            $entry.Component = $Loghash['component']
            $entry.thread = $Loghash['thread']
            $entry.Source = $source

            $Detailshash = @{}
            if ($AllDetails.IsPresent){
                $DetailsHash += $Loghash
            }
            $DateTimeString = "$($Loghash['Date']) $($Loghash['time'].split('-').split('+')[0])"
            $datetime = 0
            $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            $entry.datetime = $datetime
            
            $entry.severity = Get-LogEntrySeverity -Message $match.groups[1].value
            if ($entry.severity -eq [severity]::Error){
                [int]$errorcode = Get-LogEntryErrorMessage -message $match.groups[1].value
                if ($errorcode -eq 0){
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
                        Write-verbose -message "Could not convert $errorcode to error message:`n$message"
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
