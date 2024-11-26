# Initialize an empty hashtable to store the Strike values and corresponding lines
$strikeValues = @{}

# Initialize a variable to track the current protection block
$inProtectionBlock = $false

# Read the .cfg file
$lines = Get-Content "ArmorPrototypes.cfg"

# Loop through each line in the file
for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]

  # Check if the line marks the beginning of a protection block
  if ($line -replace '\s','' -eq "Protection:struct.begin") {
    $inProtectionBlock = $true
    continue
  }

  # Check if the line marks the end of a protection block
  if ($line -replace '\s','' -eq "struct.end") {
    $inProtectionBlock = $false
    continue
  }

  # If inside a protection block, extract the Strike value
  if ($inProtectionBlock -and ($line -replace '\s','') -match "Strike=([\d.]+)") {
    $strikeValue = $matches[1] -as [double]
    $strikeValues[$i] = $strikeValue
  }
}


# Analyze the range of Strike values
$maxValue = ($strikeValues.Values | Measure-Object -Maximum).Maximum
# Initialize variables to calculate total percent reduction
$totalPercentReduction = 0
$countValidValues = 0  # Number of values where original value is not zero

# Normalize the Strike values logarithmically
$normalizedValues = @{}
foreach ($key in $strikeValues.Keys) {
  $originalValue = $strikeValues[$key]

  if ($originalValue -le 1.50) {
    # No change for values below 1.5
    $normalizedValue = $originalValue
  } elseif ($originalValue -gt 1.50 -and $originalValue -le 20) {
    # Weaker normalization between 1.5 and 2, with a minimum of 1.5
    $calculatedValue = 3 * [Math]::Log10(($originalValue / $maxValue) * 8.50 + 1.00)
    $normalizedValue = [Math]::Round([Math]::Max(1.30, $calculatedValue), 2)
  } elseif ($originalValue -gt 2.00 -and $originalValue -le 2.50) {
    # Weaker normalization between 2.0 and 2.5, with a minimum of 1.8
    $calculatedValue = 3 * [Math]::Log10(($originalValue / $maxValue) * 8.00 + 1.00)
    $normalizedValue = [Math]::Round([Math]::Max(1.80, $calculatedValue), 2)
  } elseif ($originalValue -gt 2.50 -and $originalValue -le 3.00) {
    # Weaker normalization between 2.5 and 3.0, with a minimum of 2.3
    $calculatedValue = 3.5 * [Math]::Log10(($originalValue / $maxValue) * 7.5 + 1.00)
    $normalizedValue = [Math]::Round([Math]::Max(2.30, $calculatedValue), 2)
  } else {
    # Stronger normalization for values above 3.0, with a minimum of 2.8
    $calculatedValue = 3.5 * [Math]::Log10(($originalValue / $maxValue) * 7.0 + 1.00)
    $normalizedValue = [Math]::Round([Math]::Max(2.80, $calculatedValue), 2)
  }

  if ($normalizedValue -ge $originalValue) {
    $normalizedValue = $originalValue * 0.9
  }

  # Calculate percent reduction if original value is not zero
  if ($originalValue -ne 0) {
  $percentReduction = (($originalValue - $normalizedValue) / $originalValue) * 100
  $totalPercentReduction += $percentReduction
  $countValidValues += 1
  } else {
      # Handle the case when original value is zero
      # Since percent reduction is undefined, we'll skip it
      continue
  }

  $normalizedValues[$key] = [Math]::Round($normalizedValue, 2)
  Write-Output $normalizedValue
}

# Calculate average percent reduction
if ($countValidValues -gt 0) {
  $averagePercentReduction = $totalPercentReduction / $countValidValues
} else {
  $averagePercentReduction = 0
}

Write-Output "Average Percent Reduction: $([Math]::Round($averagePercentReduction, 2))%"


# Update the .cfg file with the normalized values
foreach ($key in $normalizedValues.Keys) {
  $lines[$key] = "      Strike = {0:F2}" -f [Math]::Round($normalizedValues[$key], 2)
}

# Write the modified lines back to the .cfg file
Set-Content "ArmorPrototypes.cfg" -Value $lines