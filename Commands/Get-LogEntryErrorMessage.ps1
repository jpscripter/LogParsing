
Function Get-LogEntryErrorMessage { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$Message
    )
    $errorPattern = '(?i)error[code\s:=is]*\s(((\-|)[1-9][\d]*)|(0x[\da-f]{4,}))'
    $match = [regex]::match($Message,$errorPattern)
    $match.Groups[1].value

}