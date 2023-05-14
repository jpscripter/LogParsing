Function New-LogWatcher { 
    <#
.SYNOPSIS
This is used to monitor a log for changes and run a peice of code if there is a string found. 

.DESCRIPTION
This will add a file watcher to the log and monitor for changes, if it changes, than we will read the new content, parse it and execute a scriptblock if it matches some criteria

.PARAMETER File
File object to the log file

.PARAMETER ScriptBlock
What actions should we pass through into the scriptblock

.EXAMPLE
PS C:\> New-LogWatcher -File C:\TestLogs\ConfigMgrAdminUISetup.log
CMXML

.LINK
http://www.JPScripter.com
#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [System.IO.FileInfo]$File,
        [scriptblock] $scriptblock
    )
    Begin{

    }
    Process {

        #Set watcher at end of log
        $logType = Get-logtype -File $file 
        Write-Verbose -Message "Adding watcher for $logType : $file"
        $fs = [System.IO.FileStream]::new($File.fullname, 'Open', 'Read', [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
        $sr = [System.IO.StreamReader]::new($fs);
        $script:LogFiles[$File.FullName].StreamReaderPosition = $sr.BaseStream.Length 

        $EventAction = @"
            #Wait-Debugger
            Write-Verbose -Message "`$(`$eventArgs.fullpath) "
            `$Logs = Get-Log -file `$eventArgs.fullpath -NewContentOnly 
            Write-Verbose -Message "`$(`$logs.count) new log entries"
            `$Logs.foreach({$Scriptblock})
"@
        $directory = $file.Directory.FullName
        $Filter = $file.name
        $watcher = New-Object -typename System.IO.FileSystemWatcher -ArgumentList ($directory, $filter)

        Register-ObjectEvent -InputObject $watcher -EventName changed -Action ([scriptblock]::Create($EventAction))
    }
    End {
    }
}