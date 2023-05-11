
Function Get-LogEntrySeverity { 
    param(
        [parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$Message
    )

    Process {
        foreach($Word in $script:ErrorKeywords){
            if ($Message -match $Word){
                return [Severity]::Error
            }
        }

        foreach($Word in $script:WarningKeywords){
            if ($Message -match $Word){
                return [Severity]::warning
            }
        }

        foreach($Word in $script:VerboseKeywords){
            if ($Message -match $Word){
                return [Severity]::verbose
            }
        }
        
        foreach($Word in $script:DebugKeywords){
            if ($Message -match $Word){
                return [Severity]::debug
            }
        }

        foreach($Word in $script:InformationKeywords){
            if ($Message -like "$Word*"){
                return [Severity]::information
            }
        }

    }
    End {
        return [Severity]::normal
    }
}