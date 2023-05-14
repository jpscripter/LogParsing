
Function Get-LogEntrySeverity { 
<#
.SYNOPSIS
Used to get the severity of the log message from the message itself

.DESCRIPTION
first looks to see if the message starts with the keywords defined in the modules

.PARAMETER Message
The log message line to parse

.EXAMPLE
PS C:\> Get-LogEntrySeverity -Message 'test error code 5'
Error
PS C:\> Get-LogEntrySeverity -Message 'infomational: test error'
information

.LINK
http://www.JPScripter.com
#>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$Message
    )

    Process {
        $Statuses = @('error','warning','verbose','debug','information')
        #Headers
        foreach($status in $statuses){
            $keywords = get-variable -name "$($status)Keywords" -scope script -ValueOnly
            foreach($Word in $keywords){
                if ($Message -like "$Word*"){
                    return [Severity]$status
                }
            }
        }
        #Parsing full message with regex
        foreach($status in $statuses){
            $keywords = get-variable -name "$($status)Keywords" -scope script -ValueOnly
            foreach($Word in $keywords){
                if ($Message -imatch $Word){
                    return [Severity]$status
                }
            }
        }
        return [Severity]::normal

    }
    End {
    }
}