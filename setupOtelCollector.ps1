$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Paths
$OtelDir = "C:\Program Files\OpenTelemetry Collector"
$OtelExe = "$OtelDir\otelcol-contrib.exe"
$OtelConfig = "$OtelDir\config.yaml"
$OtelArchive = "$env:TEMP\otelcol-contrib_0.128.0_windows_amd64.tar.gz"

# Create output directory
New-Item -ItemType Directory -Force -Path "C:\Monitoring_2\otel-traces"

# Download the OpenTelemetry Collector archive
Invoke-WebRequest -Uri "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_windows_amd64.tar.gz" -OutFile $OtelArchive

# Create install directory
New-Item -ItemType Directory -Force -Path $OtelDir

# Extract the collector
tar -xzf $OtelArchive -C $OtelDir

# Download config file
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/filippovicini/otelScript/refs/heads/main/otel-collector-config.yaml" `
  -OutFile $OtelConfig -UseBasicParsing

# Validate collector binary
if (-not (Test-Path $OtelExe)) {
    throw "otelcol-contrib.exe not found in $OtelDir"
}
if (-not (Test-Path $OtelConfig)) {
    throw "config.yaml not found in $OtelDir"
}

# Remove existing service if it exists
if (Get-Service -Name "otelcol" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "otelcol" -Force
    $svc = Get-WmiObject -Class Win32_Service -Filter "name='otelcol'"
    $svc.delete()
    Start-Sleep -Seconds 2
}

# Create and start the service
New-Service -Name "otelcol" `
    -DisplayName "OpenTelemetry Collector" `
    -Description "OpenTelemetry Collector for trace/metric/log collection" `
    -BinaryPathName "`"$OtelExe`" --config `"$OtelConfig`"" `
    -StartupType Automatic

Start-Service -Name "otelcol"

Write-Host "OpenTelemetry Collector installed and started successfully"
