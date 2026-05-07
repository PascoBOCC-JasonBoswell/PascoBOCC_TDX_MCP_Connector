#Requires -Version 5.0
# PowerShell Script to Deploy TDX MCP to Ubuntu Server

param()

# Configuration
[string]$ServerIP = "10.210.1.38"
[string]$ServerUser = "itmcp"
[string]$LocalProjectPath = "c:\_repos\PascoBOCC-JasonBoswell\PascoBOCC_TDX_MCP_Connector"
[string]$EnvFilePath = "c:\_repos\PascoBOCC-JasonBoswell\PascoBOCC_TDX_MCP_Connector\.env"

function Test-SSH {
    Write-Host "Testing SSH connection..." -ForegroundColor Yellow
    $target = $ServerUser + "@" + $ServerIP
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new $target "echo 'SSH connection successful'" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SSH connection successful" -ForegroundColor Green
        return $true
    } else {
        Write-Host "SSH connection failed" -ForegroundColor Red
        Write-Host "  - Server IP: $ServerIP" -ForegroundColor Red
        Write-Host "  - Username: $ServerUser" -ForegroundColor Red
        return $false
    }
}

function Copy-ProjectToServer {
    Write-Host "`nCopying project files to server..." -ForegroundColor Yellow
    
    # Create temp directory with proper permissions first
    $target = $ServerUser + "@" + $ServerIP
    ssh -o StrictHostKeyChecking=accept-new $target "rm -rf /tmp/tdx-mcp-source && mkdir -p /tmp/tdx-mcp-source && chmod 777 /tmp/tdx-mcp-source"
    
    # Now copy the files
    $copyTarget = $ServerUser + "@" + $ServerIP + ":/tmp/tdx-mcp-source"
    scp -r -o StrictHostKeyChecking=accept-new "$LocalProjectPath" $copyTarget
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Project files copied successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Failed to copy project files" -ForegroundColor Red
        return $false
    }
}

function Copy-EnvToServer {
    Write-Host "`nCopying .env file to server..." -ForegroundColor Yellow
    
    if (-not (Test-Path $EnvFilePath)) {
        Write-Host ".env file not found at $EnvFilePath" -ForegroundColor Red
        return $false
    }
    
    $target = $ServerUser + "@" + $ServerIP + ":/tmp/tdx-mcp.env"
    scp -o StrictHostKeyChecking=accept-new "$EnvFilePath" $target
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ".env file copied successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Failed to copy .env file" -ForegroundColor Red
        return $false
    }
}

function Run-SetupScript {
    Write-Host "`nRunning setup script on server..." -ForegroundColor Yellow
    
    $target = $ServerUser + "@" + $ServerIP
    
    $setupScript = @"
#!/bin/bash
set -e
sudo mkdir -p /opt/tdx-mcp
sudo cp -r /tmp/tdx-mcp-source/PascoBOCC_TDX_MCP_Connector/* /opt/tdx-mcp/
sudo cp /tmp/tdx-mcp.env /opt/tdx-mcp/.env
sudo chmod 600 /opt/tdx-mcp/.env
cd /opt/tdx-mcp
echo 'Installing dependencies...'
sudo npm install
echo 'Fixing permissions on tsc...'
sudo chmod +x node_modules/.bin/tsc
echo 'Building project...'
sudo npm run build
echo 'Removing dev dependencies...'
sudo npm prune --omit=dev
echo 'Setting permissions...'
sudo chown -R tdx-mcp:tdx-mcp /opt/tdx-mcp
echo 'Creating systemd service...'
sudo mkdir -p /etc/systemd/system
sudo tee /etc/systemd/system/tdx-mcp.service > /dev/null << 'EOF'
[Unit]
Description=TDX MCP Connector Server
After=network.target

[Service]
Type=simple
User=tdx-mcp
WorkingDirectory=/opt/tdx-mcp
ExecStart=/usr/bin/node /opt/tdx-mcp/dist/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tdx-mcp
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
echo 'Setup complete!'
"@
    
    $setupScript | ssh -o StrictHostKeyChecking=accept-new -t $target "cat > /tmp/setup-deploy.sh && bash /tmp/setup-deploy.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Setup completed successfully" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Setup script failed" -ForegroundColor Red
        return $false
    }
}

function Show-NextSteps {
    Write-Host "`nDeployment Complete - Next Steps" -ForegroundColor Green
    Write-Host "`nSSH to your server:" -ForegroundColor Cyan
    $target = $ServerUser + "@" + $ServerIP
    Write-Host "  ssh $target" -ForegroundColor Cyan
    Write-Host "`nStart the service:" -ForegroundColor Cyan
    Write-Host "  sudo systemctl start tdx-mcp" -ForegroundColor Cyan
    Write-Host "`nCheck service status:" -ForegroundColor Cyan
    Write-Host "  sudo systemctl status tdx-mcp" -ForegroundColor Cyan
}

# Main execution
Write-Host "TDX MCP Connector - Deploy to Ubuntu Server" -ForegroundColor Cyan
Write-Host "`nConfiguration:" -ForegroundColor Yellow
Write-Host "  Server: $ServerIP"
Write-Host "  User: $ServerUser"
Write-Host "  Project: $LocalProjectPath"

if (-not (Test-SSH)) {
    exit 1
}

if (-not (Copy-ProjectToServer)) {
    exit 1
}

if (-not (Copy-EnvToServer)) {
    exit 1
}

if (-not (Run-SetupScript)) {
    exit 1
}

Show-NextSteps
Write-Host "`nAll done! Your MCP server is ready for deployment.`n" -ForegroundColor Green
