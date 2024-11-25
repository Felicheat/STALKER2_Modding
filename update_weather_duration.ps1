param(
    [string]$DirectoryPath
)

Get-ChildItem -Path $DirectoryPath -Filter "*.cfg" | ForEach-Object {  # Assuming your files are .txt files
    $FilePath = $_.FullName
    $fileContent = Get-Content $FilePath

    $newContent = $fileContent | ForEach-Object {
        if ($_ -match 'WeatherDurationMin\s*=\s*([\d.]+)\.f') {
            $currentValue = [float]$matches[1]
            if ($currentValue -gt 400.0) {
                $newValue = $currentValue * 0.75
                if ($newValue -lt 400.0) { $newValue = 400.0 }
                $_ -replace "WeatherDurationMin\s*=\s*$currentValue\.f", "WeatherDurationMin = $newValue.f" 
            }
            else{
                $_
            }
        } elseif ($_ -match 'WeatherDurationMax\s*=\s*([\d.]+)\.f') {
            $currentValue = [float]$matches[1]
            if ($currentValue -gt 1000.0) {
                $newValue = $currentValue * 0.75
                if ($newValue -lt 1000.0) { $newValue = 1000.0 }
                $_ -replace "WeatherDurationMax\s*=\s*$currentValue\.f", "WeatherDurationMax = $newValue.f"
            }
            else{
                $_
            }
        } else {
            $_
        }
    }

    $newContent | Set-Content $FilePath
}