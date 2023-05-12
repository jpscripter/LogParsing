
Function Get-LogEntryErrorMessage { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$Message
    )
    $errorPattern = '(?i)error.*?((\-|0x|)\d+)'
    $match = [regex]::match($Message,$errorPattern)
    $match.Groups[1].value

}