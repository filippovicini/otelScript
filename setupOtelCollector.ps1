$ErrorActionPreference = "Stop"

# Create output directory
New-Item -ItemType Directory -Force -Path "C:\Monitoring_2\otel-traces"

# Download the OpenTelemetry Collector archive
Invoke-WebRequest -Uri "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.128.0/otelcol-contrib_0.128.0_windows_amd64.tar.gz" -OutFile "$env:TEMP\otelcol-contrib_0.128.0_windows_amd64.tar.gz"

# Create install directory
New-Item -ItemType Directory -Force -Path "C:\Program Files\OpenTelemetry Collector"

# Extract the collector
tar -xzf "$env:TEMP\otelcol-contrib_0.128.0_windows_amd64.tar.gz" -C "C:\Program Files\OpenTelemetry Collector"

# Copy config file (assumes config is already present in the same directory as the script)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/filippovicini/otelScript/refs/heads/main/otel-collector-config.yaml" `
  -OutFile "C:\Program Files\OpenTelemetry Collector\config.yaml" -UseBasicParsing

# Remove existing service if it exists
if (Get-Service -Name "otelcol" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "otelcol" -Force
    $svc = Get-WmiObject -Class Win32_Service -Filter "name='otelcol'"
    $svc.delete()
}

# Create and start the service
New-Service -Name "otelcol" `
    -DisplayName "OpenTelemetry Collector" `
    -Description "OpenTelemetry Collector for trace/metric/log collection" `
    -BinaryPathName "`"C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe`" --config `"C:\Program Files\OpenTelemetry Collector\config.yaml`"" `
    -StartupType Automatic

Start-Service -Name "otelcol"

Write-Host "OpenTelemetry Collector installed and started successfully"
