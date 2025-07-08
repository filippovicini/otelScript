param(
    [string]$CollectorVersion = "0.86.0",
    [string]$OutputPath = "C:\Monitoring_2\otel-traces"
)

$ErrorActionPreference = "Stop"

# Create output directory if it doesn't exist
New-Item -ItemType Directory -Force -Path $OutputPath

# Download and extract OpenTelemetry Collector
$collectorZip = "otelcol-contrib-$CollectorVersion-windows_amd64.zip"
$downloadUrl = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$CollectorVersion/$collectorZip"
$outputZip = Join-Path $env:TEMP $collectorZip

# Download the collector
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputZip

# Extract to Program Files
$installPath = "${env:ProgramFiles}\OpenTelemetry Collector"
New-Item -ItemType Directory -Force -Path $installPath
Expand-Archive -Path $outputZip -DestinationPath $installPath -Force

# Copy config file from artifacts
$configSource = "config\otel-collector-config.yaml"
$configDest = Join-Path $installPath "config.yaml"
Copy-Item -Path $configSource -Destination $configDest -Force

# Create and start Windows service
$serviceName = "otelcol"
$binaryPath = """${installPath}\otelcol-contrib.exe"" --config ""${configDest}"""

# Remove existing service if it exists
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Stop-Service -Name $serviceName -Force
    $proc = Get-WmiObject -Class Win32_Service -Filter "name='$serviceName'"
    $proc.delete()
}

# Create and start the service
New-Service -Name $serviceName `
    -DisplayName "OpenTelemetry Collector" `
    -Description "OpenTelemetry Collector for trace/metric/log collection" `
    -BinaryPathName $binaryPath `
    -StartupType Automatic

Start-Service -Name $serviceName

Write-Host "OpenTelemetry Collector installed and started successfully"
