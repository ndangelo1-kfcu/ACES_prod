# Set file location and name
$fileLocation = "KFCU_SSIS\Live\ACES"
$fileName = "ACES_ETL\ACESExport.py"

# Navigate to the folder containing the virtual environment and Python script
Set-Location -Path ("\\vsarcu02\c$\" + $fileLocation)

# Activate the virtual environment
& ("\\vsarcu02\c$\" + $fileLocation + "\venv\Scripts\Activate.ps1")

# Run the Python script with retry logic
$pythonScriptPath = ("\\vsarcu02\c$\" + $fileLocation + "\" + $fileName)
if (-Not (Test-Path $pythonScriptPath)) {
    Write-Output "Python script not found at $pythonScriptPath"
    & "deactivate"
    exit 1
}

$maxRetries = 3
$retryCount = 0
$success = $false

while ($retryCount -lt $maxRetries -and -not $success) {
    $process = Start-Process -FilePath ("\\vsarcu02\c$\" + $fileLocation + "\venv\Scripts\python.exe") -ArgumentList $pythonScriptPath -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -eq 0) {
        Write-Output "Python script completed successfully"
        $success = $true
    } else {
        Write-Output "Python script failed with exit code $($process.ExitCode). Retrying ($($retryCount + 1)/$maxRetries)..."
        $retryCount++
        Start-Sleep -Seconds 10
    }
}

# Deactivate the virtual environment
& "deactivate"

if (-not $success) {
    Write-Output "Python script failed after $maxRetries attempts."
    exit 1
} else {
    exit 0
}