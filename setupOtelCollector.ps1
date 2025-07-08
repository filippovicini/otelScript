$ErrorActionPreference = "Stop"

# Create output directory
New-Item -ItemType Directory -Force -Path "C:\Monitoring_2\otel-traces"

# Download and extract OpenTelemetry Collector
Invoke-WebRequest -Uri "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.86.0/otelcol-contrib-0.86.0-windows_amd64.zip" -OutFile "$env:TEMP\otelcol-contrib-0.86.0-windows_amd64.zip"

# Create install directory
New-Item -ItemType Directory -Force -Path "C:\Program Files\OpenTelemetry Collector"

# Extract the collector
Expand-Archive -Path "$env:TEMP\otelcol-contrib-0.86.0-windows_amd64.zip" -DestinationPath "C:\Program Files\OpenTelemetry Collector" -Force

# Copy config file (assumes config is already present in the same directory as the script)
Copy-Item -Path "config\otel-collector-config.yaml" -Destination "C:\Program Files\OpenTelemetry Collector\config.yaml" -Force

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
