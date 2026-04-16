#
# TDX MCP Server Setup for Windows
# Right-click and "Run with PowerShell" to execute
#

# Change to the script's directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Clear-Host
Write-Host "=============================================="
Write-Host "  TDX MCP Server Setup for Windows"
Write-Host "=============================================="
Write-Host ""
Write-Host "This script will:"
Write-Host "  1. Collect your TDX admin API keys"
Write-Host "  2. Install dependencies"
Write-Host "  3. Build the MCP server"
Write-Host "  4. Configure GitHub Copilot Chat MCP settings"
Write-Host ""
Write-Host "You'll need your BEID and Web Services Key from"
Write-Host "TDAdmin > Organization Details > API Settings."
Write-Host ""

# Check for Node.js
$nodeVersion = $null
try {
    $nodeVersion = node --version
} catch {
    Write-Host "ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/ and try again."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Node.js version: $nodeVersion"
Write-Host ""

# Get TDX Base URL
Write-Host "=============================================="
Write-Host "  Step 1: TDX API Configuration"
Write-Host "=============================================="
Write-Host ""
Write-Host "Enter the TDX Web API base URL (no trailing slash)."
Write-Host ""
Write-Host "Default: https://yourorg.teamdynamix.com/TDWebApi/api"
Write-Host ""
$TdxBaseUrl = Read-Host "TDX Base URL (press Enter for default)"

if ([string]::IsNullOrWhiteSpace($TdxBaseUrl)) {
    $TdxBaseUrl = "https://yourorg.teamdynamix.com/TDWebApi/api"
}

Write-Host ""
Write-Host "Using Base URL: $TdxBaseUrl"
Write-Host ""

# Get BEID
$TdxBeid = Read-Host "BEID (from TDAdmin)"
if ([string]::IsNullOrWhiteSpace($TdxBeid)) {
    Write-Host "ERROR: BEID is required." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get Web Services Key
Write-Host ""
$TdxWebServicesKey = Read-Host "Web Services Key (from TDAdmin)"
if ([string]::IsNullOrWhiteSpace($TdxWebServicesKey)) {
    Write-Host "ERROR: Web Services Key is required." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get TDX App ID
Write-Host ""
$TdxAppId = Read-Host "TDX Application ID (integer)"
if ([string]::IsNullOrWhiteSpace($TdxAppId)) {
    Write-Host "ERROR: App ID is required." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  Step 2: Installing dependencies..."
Write-Host "=============================================="
Write-Host ""

npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: npm install failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  Step 3: Building MCP server..."
Write-Host "=============================================="
Write-Host ""

npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Build failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  Step 4: Configuring GitHub Copilot Chat..."
Write-Host "=============================================="
Write-Host ""

# Create .vscode directory if it doesn't exist
$VscodeDir = Join-Path $ScriptDir ".vscode"
if (-not (Test-Path $VscodeDir)) {
    New-Item -ItemType Directory -Path $VscodeDir -Force | Out-Null
    Write-Host "Created .vscode directory"
}

# Create .vscode/mcp.json
$mcpConfigFile = Join-Path $VscodeDir "mcp.json"
$mcpConfig = @{
    servers = @{
        tdx = @{
            type = "stdio"
            command = "node"
            args = @("`${workspaceFolder}/dist/index.js")
            env = @{
                TDX_BASE_URL = "`${input:tdxBaseUrl}"
                TDX_BEID = "`${input:tdxBeid}"
                TDX_WEB_SERVICES_KEY = "`${input:tdxWebServicesKey}"
                TDX_APP_ID = "`${input:tdxAppId}"
            }
        }
    }
}

$mcpConfig | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigFile -Encoding UTF8
Write-Host "Created .vscode/mcp.json"

# Create .vscode/settings.json with input variable definitions
$settingsFile = Join-Path $VscodeDir "settings.json"
$existingSettings = @{}

if (Test-Path $settingsFile) {
    try {
        $existingSettings = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable
    } catch {
        $existingSettings = @{}
    }
}

# Add input variable definitions (merge with existing if present)
if (-not $existingSettings.ContainsKey('inputBox.input.variables')) {
    $existingSettings['inputBox.input.variables'] = @{}
}

$existingSettings['inputBox.input.variables']['tdxBaseUrl'] = @{
    description = "TDX Web API Base URL (e.g., https://yourorg.teamdynamix.com/TDWebApi/api)"
}
$existingSettings['inputBox.input.variables']['tdxBeid'] = @{
    description = "TDX Admin BEID from TDAdmin > Organization Details > API Settings"
}
$existingSettings['inputBox.input.variables']['tdxWebServicesKey'] = @{
    description = "TDX Web Services Key from TDAdmin > Organization Details > API Settings"
}
$existingSettings['inputBox.input.variables']['tdxAppId'] = @{
    description = "Default TDX Application ID (integer)"
}

$existingSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
Write-Host "Updated .vscode/settings.json"

Write-Host ""
Write-Host "=============================================="
Write-Host "  Setup Complete!"
Write-Host "=============================================="
Write-Host ""
Write-Host "The TDX MCP server has been configured for GitHub Copilot Chat."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open VS Code in this workspace"
Write-Host "  2. When prompted, provide your TDX credentials:"
Write-Host "     - TDX Base URL"
Write-Host "     - TDX BEID"
Write-Host "     - TDX Web Services Key"
Write-Host "     - TDX App ID"
Write-Host "  3. Open Copilot Chat (Ctrl+Shift+I)"
Write-Host "  4. The TDX tools will be available automatically"
Write-Host ""
Write-Host "You can now use commands like:"
Write-Host "  - 'Search for open tickets assigned to me'"
Write-Host "  - 'Look up person john.doe@example.com'"
Write-Host "  - 'Get ticket #12345'"
Write-Host "  - 'Search the knowledge base for VPN setup'"
Write-Host "  - 'Find all assets in the IT department'"
Write-Host ""
Read-Host "Press Enter to exit"
