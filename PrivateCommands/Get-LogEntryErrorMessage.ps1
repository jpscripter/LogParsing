
Function Get-LogEntryErrorMessage { 
    param(
        [string]$Message
    )
    if (-not [string]::IsNullOrEmpty($Message)){
        $errorPattern = '(?i)error[code\s:=is]*\s(((\-|)[1-9][\d]*)|(0x[\da-f]{4,}))'
        $match = [regex]::match($Message,$errorPattern)
        $match.Groups[1].value
    }
}