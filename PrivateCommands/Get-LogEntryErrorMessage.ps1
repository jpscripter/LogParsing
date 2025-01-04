
Function Get-LogEntryErrorMessage { 
    param(
        [string]$Message
    )
    if (-not [string]::IsNullOrEmpty($Message)){
        $errorPattern = '(?i)error[code\s:=is]*\s*(((\-|)[1-9][\d]*)|(0x[\da-f]{4,}))'
        $match = [regex]::match($Message,$errorPattern)
        if ($match.Success){
            return $match.Groups[1].value
        }else{
            #Just Hex code
            $errorPattern = '(?i)(0x[\da-f]{4,})'
            $match = [regex]::match($Message,$errorPattern)
            return $match.value
        }
    }
}