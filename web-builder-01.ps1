$inputFile = Join-Path $PSScriptRoot "data.txt"
$headerFile = Join-Path $PSScriptRoot "header.txt"
$footerFile = Join-Path $PSScriptRoot "footer.txt"
$outputFolder = Join-Path $PSScriptRoot "output"

# Confirm the required files exist.
foreach ($requiredFile in @($inputFile, $headerFile, $footerFile)) {
    if (-not (Test-Path $requiredFile)) {
        Write-Error "Required file not found: $requiredFile"
        exit 1
    }
}

# Read the header and footer before processing data.txt.
$headerContent = Get-Content -Path $headerFile -Raw
$footerContent = Get-Content -Path $footerFile -Raw

# Create the output folder if it does not exist.
New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

$currentTitle = $null
$currentCopy = New-Object System.Collections.Generic.List[string]

function Save-Record {
    param (
        [string]$Title,
        [System.Collections.Generic.List[string]]$CopyLines
    )

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return
    }

    # Replace spaces with underscores.
    $safeFileName = $Title.Trim() -replace '\s+', '_'

    # Replace characters Windows does not allow in filenames.
    $safeFileName = $safeFileName -replace '[<>:"/\\|?*]', '_'

    $outputFile = Join-Path $outputFolder "$safeFileName.txt"

    # Join multiline copy content together.
    $copyContent = $CopyLines -join [Environment]::NewLine

    # Build the final file in three parts:
    # 1. header.txt
    # 2. copy content
    # 3. footer.txt
    $finalContent = @(
        $headerContent.TrimEnd()
        $copyContent
        $footerContent.TrimStart()
    ) -join [Environment]::NewLine

    Set-Content -Path $outputFile -Value $finalContent -Encoding UTF8

    Write-Host "Created: $outputFile"
}

foreach ($line in Get-Content -Path $inputFile) {

    if ($line -match '^<title>(.*)$') {

        # Save the previous record before starting the next one.
        Save-Record -Title $currentTitle -CopyLines $currentCopy

        $currentTitle = $matches[1]
        $currentCopy.Clear()
    }
    elseif ($line -match '^<copy>(.*)$') {
        $currentCopy.Add($matches[1])
    }
    elseif ($null -ne $currentTitle -and $currentCopy.Count -gt 0) {
        # Preserve additional copy lines if the copy spans multiple lines.
        $currentCopy.Add($line)
    }
}

# Save the final record.
Save-Record -Title $currentTitle -CopyLines $currentCopy
