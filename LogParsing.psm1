#region settings
$script:LogFiles = @{}
$script:LinesToKeep = 2000
#endregion

#region classes
class LogEntry{
    [string] $Message
    [string] $Component
    [DateTime] $Datetime
    [int] $thread
    [string] $details
}
class LogDetails 
{
    LogDetails (){
        $this.LogEntry =[System.Collections.Generic.List[LogEntry]]::new()
    }
    [System.IO.StreamReader] $StreamReader
    [string] $type
    [System.Collections.Generic.List[LogEntry]] $LogEntry
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
