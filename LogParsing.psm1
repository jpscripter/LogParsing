#region settings
$script:LogFiles = @{}
$script:ErrorKeywords = @('fail','error[:\s]', 'unsuccessful')
$script:WarningKeywords = @('warning')
$script:DebugKeywords = @('debug')
$script:VerboseKeywords = @('verbose')
$script:InformationKeywords = @('info','STATMSG')
#endregion

#region classes
enum Severity {
    normal = 0
    information = 1
    warning = 2
    Error = 3
    verbose = 4
    debug = 5
}
class LogEntry{
    [string] $Message
    [string] $Component
    [DateTime] $Datetime
    [int] $thread
    [PSCustomObject] $details
    [Severity] $severity = 1
}
class LogDetails 
{
    LogDetails (){
        $this.LogEntry = new-object Collections.arraylist
    }
    [int] $StreamReaderPosition
    [string] $type
    [Collections.arraylist] $LogEntry
    [string]$logParsingParams
}
#endregion

#region add commands
if (Test-Path -Path $PSScriptRoot\Commands\){
    $Commands = Get-ChildItem -Path $PSScriptRoot\Commands\*.ps1 -file -Recurse
    Foreach($CMD in $Commands){
	    Write-Verbose -Message "Cmdlet File: $CMD"  
	    . $CMD
    }
}
#endregion
