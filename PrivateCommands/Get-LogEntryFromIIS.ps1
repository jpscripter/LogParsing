
Function Get-LogEntryFromIIS { 
    <#
.SYNOPSIS
Used to parse an IIS log file format. 

.DESCRIPTION
This format is specific to the IIS log format and pulls the fields from the fields header. 

.PARAMETER LogContent
the -raw log content that you want broken into different entries. 

.PARAMETER AllDetails
This creates a PSCustom object for all of the properties in the fields header for advanced usage.

.EXAMPLE
$LogSplat = @{
    AllDetails = $AllDetails.IsPresent
    LogContent = $LogContent
}
$logEntries = Get-LogEntryFromIIS @LogSplat 

.LINK
http://www.JPScripter.com
#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$LogContent,
        [string] $headers,
        [switch] $AllDetails
    )
    Begin{
        $HeadersNames = $headers.Split()
    }
    Process {

        # find new entries
        $LogMatches = $LogContent.split("`n")
        $logEntries = new-object -TypeName Collections.arraylist
        foreach($match in $LogMatches){
            if ($match.StartsWith('#')){Continue}
            $DetailRow = $match.split()
            $DetailsHash = @{}
            for($i = 0; $I -lt $DetailRow.count; $i++){
                try{
                    $name = $HeadersNames[$i]
                    $value = $DetailRow[$i]
                    $DetailsHash.add($name,$value)
                }
                Catch{
                    Write-warning -Message "$name duplicated for $file"
                }
            }

            #skip empty rows
            if ($DetailsHash.Keys.count -le 1){
                Continue
            }

            #build entry
            $entry = new-object logEntry
            if ([string]::IsNullOrEmpty($match)){Continue}
            $entry.Message = $match
            $entry.Component = $DetailsHash['cs-uri-stem']
            
            # custom iis errors
            switch ($DetailsHash['sc-status']){
                '200'{
                    $entry.severity = 'normal'
                    break
                }
                '404'{
                    $entry.severity = 'warning'
                    break
                }
                default {
                    $entry.severity = 'Error'
                    break
                }
            }

            #skip if cant passe date
            if ( $DetailsHash.ContainsKey('Date') -and $DetailsHash.ContainsKey('time')){
                if ($AllDetails.IsPresent){
                    $entry.details = $DetailsHash 
                }
                $DateTimeString = "$($DetailsHash['Date']) $($DetailsHash['time'].split('.')[0])"
                $datetime = 0
                $Null = [datetime]::TryParse($DateTimeString, [ref] $datetime)
            }
            $entry.datetime = $datetime
            $null = $logEntries.add($entry)
        }
    }
    End {
        $logEntries
    }
}