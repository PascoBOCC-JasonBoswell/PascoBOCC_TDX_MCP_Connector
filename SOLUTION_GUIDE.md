# TDX MCP Connector - Complete Solution Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Deployment](#deployment)
5. [Configuration](#configuration)
6. [HTTP API Reference](#http-api-reference)
7. [Copilot Studio Integration](#copilot-studio-integration)
8. [Service Management](#service-management)
9. [Security](#security)
10. [Troubleshooting](#troubleshooting)
11. [Future Enhancements](#future-enhancements)

---

## Overview

### What is TDX MCP Connector?

The TDX MCP Connector is a persistent HTTP service that wraps the [TeamDynamix (TDX) REST API](https://solutions.teamdynamix.com/TDWebApi/) and exposes it through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). This enables AI-assisted IT service management through Microsoft Copilot Studio.

### Key Features

- ✅ **43 Tools** across 10 domains (tickets, assets, CMDB, knowledge base, people, projects, accounts, groups, statuses, attributes)
- ✅ **Persistent HTTP Service** - Stays running after client disconnects (unlike stdio MCP)
- ✅ **API Key Authentication** - Secure access with configurable API keys
- ✅ **Auto-Restart Capability** - Systemd service with automatic recovery on failure
- ✅ **Process Pooling** - Efficient resource usage (max 5 concurrent MCP processes)
- ✅ **CORS Enabled** - Cross-origin requests supported
- ✅ **Copilot Studio Ready** - Direct integration with Microsoft Copilot Studio

### Current Deployment Status

| Component | Status | Details |
|-----------|--------|---------|
| Server | ✅ Running | Ubuntu 26.04 LTS at 10.210.1.38 |
| Service | ✅ Active | systemd service tdx-mcp |
| HTTP Wrapper | ✅ Deployed | Port 3000, HTTP wrapper.js |
| API Authentication | ✅ Active | 64-char hex key (non-expiring) |
| Auto-Start | ✅ Enabled | Service auto-starts on boot |
| Auto-Restart | ✅ Enabled | Restarts on failure (10-second delay) |

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Microsoft Copilot Studio                                    │
│ (Makes HTTP requests with API key)                          │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP Request
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ Ubuntu 26.04 LTS Server (10.210.1.38)                       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ systemd Service: tdx-mcp                            │   │
│  │ Port: 3000                                          │   │
│  │                                                     │   │
│  │  ┌───────────────────────────────────────────────┐ │   │
│  │  │ HTTP Wrapper (src/http-wrapper.js)            │ │   │
│  │  │                                               │ │   │
│  │  │ ✓ /health (public - no auth)                 │ │   │
│  │  │ ✓ /status (protected - requires API key)     │ │   │
│  │  │ ✓ /tools (protected - requires API key)      │ │   │
│  │  │ ✓ /mcp (protected - requires API key)        │ │   │
│  │  │                                               │ │   │
│  │  │ [On-demand Process Pool]                      │ │   │
│  │  │ • Max 5 concurrent MCP processes              │ │   │
│  │  │ • 10-second timeout per request               │ │   │
│  │  │ • Auto-cleanup of idle processes              │ │   │
│  │  └───────────────────────────────────────────────┘ │   │
│  │                                                     │   │
│  │  ┌───────────────────────────────────────────────┐ │   │
│  │  │ MCP Server (dist/index.js) - Spawned on-demand│ │   │
│  │  │                                               │ │   │
│  │  │ • 43 tools (tickets, assets, CMDB, etc.)     │ │   │
│  │  │ • TDX API client (auth.ts, tdx-client.ts)    │ │   │
│  │  │ • Token auto-refresh (24-hour expiry)        │ │   │
│  │  └───────────────────────────────────────────────┘ │   │
│  │                                                     │   │
│  │  ┌───────────────────────────────────────────────┐ │   │
│  │  │ .env Configuration                            │ │   │
│  │  │ • TDX_BASE_URL                                │ │   │
│  │  │ • TDX_BEID (admin token)                      │ │   │
│  │  │ • TDX_WEB_SERVICES_KEY                        │ │   │
│  │  │ • TDX_APP_ID                                  │ │   │
│  │  └───────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────┬─────────────────────────────────┘
                          │ (External API calls)
                          ↓
        ┌────────────────────────────────────┐
        │ TeamDynamix API                    │
        │ https://yourorg.teamdynamix.com    │
        │ /TDWebApi/api                      │
        └────────────────────────────────────┘
```

### Key Components

**HTTP Wrapper** (`src/http-wrapper.js`)
- Persistent Node.js server listening on port 3000
- Accepts HTTP requests with JSON payloads
- Spawns MCP server processes on-demand
- Manages process pool for efficiency
- Implements API key authentication

**MCP Server** (`dist/index.js`)
- Compiled TypeScript source
- Implements 43 MCP tools
- Handles TDX API communication
- Manages authentication tokens
- Auto-refreshes tokens before expiry

**Process Pool**
- Maintains up to 5 concurrent MCP processes
- Spawns new process for each request
- Releases process after 10-second timeout
- Auto-cleanup of orphaned processes

**Systemd Service**
- Auto-starts on server boot
- Auto-restarts on failure (10-second delay)
- Manages environment variables (API key, port)
- Logs to journalctl for monitoring

---

## Quick Start

### Prerequisites

- Ubuntu 26.04 LTS server with SSH access
- `sudo` privileges
- 2+ GB free disk space
- Network access to TDX API

### 30-Second Deploy (Automated)

```bash
# 1. On your Windows machine, run the deployment script
powershell -ExecutionPolicy Bypass -File deploy-ubuntu.ps1

# 2. Follow the prompts and enter:
#    - Server IP: 10.210.1.38
#    - Username: itmcp
#    - SSH key location: (press Enter for default)

# 3. Wait for completion (3-5 minutes)

# 4. Verify service is running
ssh itmcp@10.210.1.38 "curl http://localhost:3000/health"
```

### Manual Deploy (Ubuntu Server)

```bash
# SSH into server
ssh itmcp@10.210.1.38

# Run setup script
sudo bash ~/setup-ubuntu.sh

# Copy .env file
sudo cp /path/to/.env /opt/tdx-mcp/.env
sudo chmod 600 /opt/tdx-mcp/.env

# Start service
sudo systemctl start tdx-mcp

# Verify
sudo systemctl status tdx-mcp
curl http://localhost:3000/health
```

### Verify Deployment

```bash
# Health check (no auth required)
curl http://10.210.1.38:3000/health

# Expected response:
# {"status":"healthy","uptime":123.45,"timestamp":"2026-05-07T15:28:40.060Z"}

# Check status (requires API key)
curl -H "Authorization: Bearer <YOUR_API_KEY>" http://10.210.1.38:3000/status
```

---

## Deployment

### Option 1: PowerShell Deployment Script (Recommended)

**File:** `deploy-ubuntu.ps1`

```powershell
# Run from Windows PowerShell
powershell -ExecutionPolicy Bypass -File deploy-ubuntu.ps1

# Prompts for:
# - Ubuntu server IP
# - SSH username
# - SSH key location
# - .env file path

# Automatically:
# ✓ Tests SSH connectivity
# ✓ Copies project files via SCP
# ✓ Transfers .env file
# ✓ Executes remote setup script
# ✓ Verifies service is running
```

**Advantages:**
- One-command deployment from Windows
- Automatic error handling
- Progress feedback
- Secure SCP file transfer

**Disadvantages:**
- Requires PowerShell 5.0+
- Requires OpenSSH client

### Option 2: Ubuntu Setup Script

**File:** `setup-ubuntu.sh`

Installs from scratch:
1. Updates system packages
2. Installs Node.js 22 LTS
3. Creates tdx-mcp service user
4. Installs npm dependencies
5. Builds TypeScript
6. Creates systemd service
7. Generates API key
8. Enables auto-start

**Usage:**
```bash
sudo bash setup-ubuntu.sh
```

### Option 3: Manual Step-by-Step

See [DEPLOYMENT_UBUNTU.md](DEPLOYMENT_UBUNTU.md) for complete manual deployment guide.

### Installation Directory Structure

```
/opt/tdx-mcp/
├── .env                           # TDX API credentials (KEEP SECRET)
├── package.json                   # Dependencies
├── package-lock.json
├── tsconfig.json                  # TypeScript config
├── src/                           # TypeScript source
│   ├── index.ts                   # MCP server entry
│   ├── http-wrapper.js            # HTTP wrapper (active)
│   ├── auth.ts                    # TDX authentication
│   ├── config.ts                  # Configuration
│   ├── tdx-client.ts              # TDX API client
│   └── tools/                     # Tool implementations
│       ├── tickets.ts
│       ├── assets.ts
│       ├── cmdb.ts
│       ├── people.ts
│       └── ...
├── dist/                          # Compiled JavaScript
│   ├── index.js
│   ├── http-wrapper.js
│   └── ...
└── node_modules/                  # Dependencies
```

---

## Configuration

### Environment Variables

**Required (.env file)**

```bash
# TDX API Configuration
TDX_BASE_URL="https://yourorg.teamdynamix.com/TDWebApi/api"
TDX_BEID="YOUR_ADMIN_BEID"                    # From TDAdmin > Organization Details
TDX_WEB_SERVICES_KEY="YOUR_WEB_SERVICES_KEY"  # From TDAdmin > Organization Details
TDX_APP_ID=1234                               # Default application ID (integer)
```

**Optional**

```bash
# Override for asset operations
TDX_ASSETS_APP_ID=5678

# Service port (configured in systemd)
MCP_HTTP_PORT=3000                            # Default

# API key for HTTP wrapper (configured in systemd)
MCP_API_KEY="your-64-char-hex-key"            # Non-expiring static key
```

### Finding TDX Configuration Values

**TDX_BASE_URL**
- From TDAdmin: Organization > General Settings
- Format: `https://yourtenant.teamdynamix.com/TDWebApi/api`

**TDX_BEID (Admin BEID)**
- From TDAdmin: Organization > API Settings
- Copy the "BE ID" value for your service account

**TDX_WEB_SERVICES_KEY**
- From TDAdmin: Organization > API Settings
- Copy the "Web Services Key" (keep secret!)

**TDX_APP_ID**
- Application ID for default operations
- Examples: 1 (tickets), 27 (assets), 63 (CMDB)
- From TDAdmin: Administration > Applications

### Systemd Service Configuration

**File:** `/etc/systemd/system/tdx-mcp.service`

```ini
[Unit]
Description=TDX MCP HTTP Server
After=network.target

[Service]
Type=simple
User=tdx-mcp
WorkingDirectory=/opt/tdx-mcp
Environment="NODE_ENV=production"
Environment="MCP_HTTP_PORT=3000"
Environment="MCP_API_KEY=<YOUR_API_KEY>"
ExecStart=/usr/bin/node /opt/tdx-mcp/src/http-wrapper.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tdx-mcp

[Install]
WantedBy=multi-user.target
```

**Key Settings:**
- `Restart=on-failure` - Auto-restart if process crashes
- `RestartSec=10` - Wait 10 seconds before restarting
- `WantedBy=multi-user.target` - Auto-start on boot
- `User=tdx-mcp` - Run as non-root service user

---

## HTTP API Reference

### Base URL
```
http://10.210.1.38:3000
```

### Authentication

All endpoints except `/health` require API key in the `Authorization` header:

```
Authorization: Bearer <YOUR_API_KEY>
```

### Endpoints

#### 1. Health Check (Public)

**Purpose:** Server health monitoring, load balancer checks, no authentication required

```http
GET /health
```

**Response (200):**
```json
{
  "status": "healthy",
  "uptime": 123.45,
  "timestamp": "2026-05-07T15:28:40.060Z"
}
```

**Usage:**
```bash
curl http://10.210.1.38:3000/health
```

---

#### 2. Service Status (Protected)

**Purpose:** Service metadata, configuration, and statistics

```http
GET /status
Authorization: Bearer <API_KEY>
```

**Response (200):**
```json
{
  "service": "TDX MCP HTTP Wrapper",
  "version": "1.0.0",
  "port": "3000",
  "uptime": 123.45,
  "timestamp": "2026-05-07T15:28:40.060Z"
}
```

**Response (401):**
```json
{
  "error": "Unauthorized: Invalid or missing API key"
}
```

**Usage:**
```bash
curl -H "Authorization: Bearer <YOUR_API_KEY>" http://10.210.1.38:3000/status
```

---

#### 3. List Available Tools (Protected)

**Purpose:** Discover all MCP tools and their names

```http
GET /tools
Authorization: Bearer <API_KEY>
```

**Response (200):**
```json
{
  "tools": [
    "tickets_create",
    "tickets_query",
    "tickets_update",
    "assets_create",
    "assets_query",
    "assets_update",
    "cmdb_create",
    "cmdb_query",
    "people_get",
    "projects_create",
    "accounts_list",
    "groups_list",
    "kb_search"
  ]
}
```

**Usage:**
```bash
curl -H "Authorization: Bearer <YOUR_API_KEY>" http://10.210.1.38:3000/tools
```

---

#### 4. Invoke MCP Tool (Protected)

**Purpose:** Execute any MCP tool and get results

```http
POST /mcp
Content-Type: application/json
Authorization: Bearer <API_KEY>

{
  "method": "<tool_name>",
  "params": {
    "<param_name>": "<param_value>",
    ...
  }
}
```

**Response (200):**
```json
{
  "result": {
    ...tool_output...
  }
}
```

**Response (400):**
```json
{
  "error": "Invalid request",
  "details": "..."
}
```

**Response (401):**
```json
{
  "error": "Unauthorized: Invalid or missing API key"
}
```

**Response (500):**
```json
{
  "error": "Tool execution failed",
  "details": "..."
}
```

**Examples:**

Query open tickets:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_API_KEY>" \
  -d '{
    "method": "tickets_query",
    "params": {
      "query": "status:open AND priority:1"
    }
  }' \
  http://10.210.1.38:3000/mcp
```

Create a ticket:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_API_KEY>" \
  -d '{
    "method": "tickets_create",
    "params": {
      "title": "Urgent: Network Down",
      "description": "Building A lost connectivity",
      "priority": 1,
      "status": 1
    }
  }' \
  http://10.210.1.38:3000/mcp
```

---

### Error Handling

All error responses include:
- `error` - Error message
- `details` (optional) - Additional context
- HTTP status code

**Common Status Codes:**

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | Request completed successfully |
| 400 | Bad Request | Missing required parameters |
| 401 | Unauthorized | Invalid or missing API key |
| 404 | Not Found | Endpoint doesn't exist |
| 500 | Server Error | Tool execution failed |
| 503 | Service Unavailable | Process pool exhausted |

---

## Copilot Studio Integration

### Prerequisites

- Access to Microsoft Copilot Studio tenant
- HTTP endpoint: `http://10.210.1.38:3000`
- API key: `<YOUR_API_KEY>` (see Copilot Studio configuration)
- Network connectivity from Copilot Studio to server

### Setup Steps

#### Step 1: Create Custom Connector

1. Go to [Copilot Studio](https://copilotstudio.microsoft.com)
2. Select your environment
3. Go to **Plugins** (left sidebar)
4. Click **+ Create a plugin**
5. Select **Connect to web service**
6. Name: `TDX MCP Connector`
7. Click **Create**

#### Step 2: Configure Endpoint

1. Go to **Plugins** > **TDX MCP Connector**
2. Click **Settings**
3. Set:
   - **Base URL**: `http://10.210.1.38:3000`
   - **Auth type**: `API Key`
   - **Header name**: `Authorization`
   - **Header value**: `Bearer <YOUR_API_KEY>`

#### Step 3: Create Actions

For each tool you need, create an action:

**Example: Query Tickets**

1. Click **+ Add action**
2. Name: `Query Tickets`
3. Method: `POST`
4. URL: `/mcp`
5. Body (JSON):
```json
{
  "method": "tickets_query",
  "params": {
    "query": "<user_query>"
  }
}
```
6. Parameters:
   - Name: `user_query`
   - Type: `String`
   - Description: `Search query for tickets (e.g., "status:open")`
   - Required: Yes

**Example: Create Ticket**

1. Click **+ Add action**
2. Name: `Create Ticket`
3. Method: `POST`
4. URL: `/mcp`
5. Body (JSON):
```json
{
  "method": "tickets_create",
  "params": {
    "title": "<title>",
    "description": "<description>",
    "status": "<status>"
  }
}
```
6. Parameters:
   - `title` (String, Required)
   - `description` (String, Required)
   - `status` (String, Optional)

#### Step 4: Use in Agent

1. Go to **Agents** > Create or edit agent
2. Click **+ Add action**
3. Select **TDX MCP Connector**
4. Choose actions to enable
5. Click **Publish**

### Testing Integration

**Test the health endpoint (no auth):**
```bash
curl http://10.210.1.38:3000/health
```

**Test with API key:**
```bash
curl -H "Authorization: Bearer <YOUR_API_KEY>" \
  http://10.210.1.38:3000/status
```

**Test MCP tool invocation:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <YOUR_API_KEY>" \
  -d '{"method":"tickets_query","params":{"query":"status:open"}}' \
  http://10.210.1.38:3000/mcp
```

---

## Service Management

### Basic Commands

```bash
# Check status
sudo systemctl status tdx-mcp

# Start service
sudo systemctl start tdx-mcp

# Stop service
sudo systemctl stop tdx-mcp

# Restart service
sudo systemctl restart tdx-mcp

# View live logs
sudo journalctl -u tdx-mcp -f

# View last 50 lines
sudo journalctl -u tdx-mcp -n 50

# View logs since boot
sudo journalctl -u tdx-mcp --since today

# Enable auto-start
sudo systemctl enable tdx-mcp

# Disable auto-start
sudo systemctl disable tdx-mcp
```

### Monitoring

**Check service status:**
```bash
ssh itmcp@10.210.1.38 "sudo systemctl status tdx-mcp"
```

**Monitor in real-time:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f"
```

**Check recent errors:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -p err -n 20"
```

**Check service uptime:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" http://10.210.1.38:3000/status
```

### Performance Metrics

The HTTP wrapper reports:

```json
{
  "service": "TDX MCP HTTP Wrapper",
  "version": "1.0.0",
  "port": "3000",
  "uptime": 86400.5,          // Seconds running
  "timestamp": "2026-05-07T15:28:40.060Z"
}
```

**Key Metrics:**
- **uptime** - Seconds since service started (uptime of 86400+ = running > 1 day)
- **timestamp** - Current server time (helps detect timezone issues)

### Automatic Restart Behavior

The service is configured to automatically restart on failure:

```
Restart=on-failure       # Restart if process exits with non-zero code
RestartSec=10           # Wait 10 seconds between restart attempts
```

**Scenarios:**
- ✅ Process crashes → Auto-restart after 10 seconds
- ✅ Network error → Auto-restart after 10 seconds
- ✅ Server reboots → Auto-start on boot (via systemd)
- ✅ Manual stop → Stays stopped (systemctl stop)

---

## Security

### API Key Management

**Current Setup:**
- Static 64-character hexadecimal API key
- Never expires (unless manually rotated)
- Required for all endpoints except `/health`
- Stored in systemd service file (protected)

**Your Current API Key:**
```
<YOUR_API_KEY>
```

⚠️ **Keep this key secret** - It provides access to all TDX operations through the HTTP endpoint.

### Rotating the API Key

**Generate new key:**
```bash
openssl rand -hex 32
# Output: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**Update service:**
```bash
ssh itmcp@10.210.1.38 "sudo nano /etc/systemd/system/tdx-mcp.service"
```

Find and update:
```ini
Environment="MCP_API_KEY=your-new-key-here"
```

**Restart service:**
```bash
ssh itmcp@10.210.1.38 "sudo systemctl daemon-reload && sudo systemctl restart tdx-mcp"
```

**Update Copilot Studio:**
- Go to Copilot Studio plugin settings
- Update the Authorization header with new key

### File Permissions

**Protected files:**
```bash
# .env file (TDX credentials) - read-only to service user
sudo chmod 600 /opt/tdx-mcp/.env
sudo chown tdx-mcp:tdx-mcp /opt/tdx-mcp/.env

# Service file - readable by root only
sudo chmod 644 /etc/systemd/system/tdx-mcp.service
```

### Network Security

**Option 1: SSH Tunnel (Recommended for development)**
```bash
ssh -L 3000:localhost:3000 itmcp@10.210.1.38
# Now access via: http://localhost:3000
```

**Option 2: Open Firewall (Production)**
```bash
# Allow access from Copilot Studio IP
sudo ufw allow from 203.0.113.0 to any port 3000

# Or allow from anywhere (less secure)
sudo ufw allow 3000/tcp
```

**Option 3: VPN/Private Network**
- Restrict access to private VPN only
- Recommend for production environments

### TDX API Credentials

**In .env file:**
```
TDX_BEID="YOUR_ADMIN_BEID"
TDX_WEB_SERVICES_KEY="YOUR_WEB_SERVICES_KEY"
```

**Protection:**
- File permissions: 600 (read-only to service user)
- Never commit to git (.gitignore)
- Rotate regularly (security best practice)
- Consider using vault/secrets manager for production

### Best Practices

1. **API Key Rotation**
   - Rotate every 30-90 days
   - Immediately if exposed
   - Update all clients before disabling old key

2. **Credential Storage**
   - Never log full API keys (only first 8 chars)
   - Never commit credentials to git
   - Use environment variables or secrets manager

3. **Access Control**
   - Restrict `/health` to trusted IPs (it's public)
   - Restrict `/mcp` to Copilot Studio IPs
   - Monitor failed authentication attempts

4. **Monitoring**
   - Watch for repeated 401 errors (potential attack)
   - Monitor process resource usage
   - Check logs for TDX API errors

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -n 100"
```

**Common causes:**
- Missing .env file
- Invalid TDX credentials
- Port 3000 already in use
- Permission issues

**Solutions:**

```bash
# Verify .env exists
ssh itmcp@10.210.1.38 "ls -la /opt/tdx-mcp/.env"

# Check port availability
ssh itmcp@10.210.1.38 "sudo lsof -i :3000"

# Fix permissions
ssh itmcp@10.210.1.38 "sudo chown -R tdx-mcp:tdx-mcp /opt/tdx-mcp"

# Test manually
ssh itmcp@10.210.1.38 "sudo -u tdx-mcp /usr/bin/node /opt/tdx-mcp/src/http-wrapper.js"
```

### Health Check Fails

**Test connectivity:**
```bash
curl -v http://10.210.1.38:3000/health
```

**If connection refused:**
```bash
# Check if service is running
ssh itmcp@10.210.1.38 "sudo systemctl status tdx-mcp"

# Check if port is listening
ssh itmcp@10.210.1.38 "sudo netstat -tulpn | grep 3000"

# Restart service
ssh itmcp@10.210.1.38 "sudo systemctl restart tdx-mcp"
```

**If timeout:**
```bash
# Check firewall rules
ssh itmcp@10.210.1.38 "sudo ufw status"

# Check network connectivity
ping 10.210.1.38

# SSH tunnel as alternative
ssh -L 3000:localhost:3000 itmcp@10.210.1.38
# Then: curl http://localhost:3000/health
```

### 401 Unauthorized Errors

**Problem:** "Invalid or missing API key"

**Solutions:**
```bash
# Verify correct API key
curl -H "Authorization: Bearer 226ee1edd38aea72c27c62e44d0d4edb101a97922568db6db77036f83fbcebde" \
  http://10.210.1.38:3000/status

# Check what key is configured on server
ssh itmcp@10.210.1.38 "sudo grep MCP_API_KEY /etc/systemd/system/tdx-mcp.service"

# If key mismatch, update it
ssh itmcp@10.210.1.38 "sudo nano /etc/systemd/system/tdx-mcp.service"
# Edit MCP_API_KEY line, then:
ssh itmcp@10.210.1.38 "sudo systemctl daemon-reload && sudo systemctl restart tdx-mcp"
```

### MCP Tool Returns Error

**Example error:**
```json
{
  "error": "Tool execution failed",
  "details": "TDX API error: 401 Unauthorized"
}
```

**Solutions:**

1. **Check TDX credentials:**
```bash
ssh itmcp@10.210.1.38 "cat /opt/tdx-mcp/.env | grep TDX_"
```

2. **Verify API access:**
```bash
curl -u BEID:WEB_SERVICES_KEY \
  https://yourorg.teamdynamix.com/TDWebApi/api/tickets/search
```

3. **Check TDX API token expiry:**
- Tokens auto-refresh every 24 hours
- If error persists, verify credentials are correct

4. **View detailed error logs:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f"
# Make the failing request and watch logs
```

### High CPU/Memory Usage

**Check resource usage:**
```bash
ssh itmcp@10.210.1.38 "ps aux | grep http-wrapper"
```

**If high memory:**
```bash
# Check for process leaks
ssh itmcp@10.210.1.38 "ps aux | grep 'node.*http-wrapper\|node.*index.js' | wc -l"

# Restart service
ssh itmcp@10.210.1.38 "sudo systemctl restart tdx-mcp"
```

**If high CPU:**
```bash
# Check if TDX API is slow
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f"

# Look for slow requests
# If consistent, may need to optimize queries or increase timeout
```

### Connection Timeouts

**Problem:** Requests to MCP endpoint timeout after 10 seconds

**Possible causes:**
1. TDX API is slow
2. Large result sets
3. Network latency

**Solutions:**
```bash
# Test TDX API directly
curl -u BEID:KEY \
  https://yourorg.teamdynamix.com/TDWebApi/api/tickets/search \
  -d '{"query":"status:open"}'

# Monitor response times in logs
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f | grep -i duration"

# If TDX API is slow, may need to:
# - Optimize search queries (more specific filters)
# - Request fewer results (pagination)
# - Contact TDX support for API performance issues
```

### Process Pool Exhausted

**Problem:** 503 Service Unavailable response

**Cause:** All 5 concurrent MCP processes are busy with > 10-second requests

**Solutions:**

1. **Wait and retry** - Requests will complete after 10 seconds

2. **Reduce request volume** - Spread requests out over time

3. **Optimize queries** - Faster requests free up processes sooner

4. **Monitor with logs:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f | grep -i pool"
```

5. **Increase pool size (advanced):**
   - Edit src/http-wrapper.js
   - Find: `const MAX_PROCESSES = 5;`
   - Change to: `const MAX_PROCESSES = 10;` (or desired value)
   - Rebuild and redeploy

---

## Future Enhancements

### Planned Features

#### 1. Advanced API Key Rotation (24-Hour Ephemeral Keys)

**What:** Automatic daily key rotation without manual intervention

**How it works:**
- New key generated daily at midnight UTC
- Old keys become invalid after 24 hours
- Copilot automatically fetches new keys on 401 errors
- No manual key rotation needed

**Benefits:**
- ✅ Shorter exposure window if key is compromised
- ✅ Zero manual maintenance
- ✅ Audit trail of all key rotations
- ✅ Similar to OAuth2 token rotation

**Implementation timeline:** 1-2 days when needed

**See:** [Advanced API Key Rotation Plan](/memories/session/advanced-api-key-rotation.md)

#### 2. JWT-Based Token Authentication

**Alternative:** Use JSON Web Tokens instead of static keys

**Benefits:**
- Standard authentication format
- Built-in expiration support
- Easier integration with auth services
- Better security audit trail

#### 3. Multi-Tenant Support

**What:** Support multiple TDX instances from single deployment

**How:**
- Accept TDX credentials per request
- Route requests to correct TDX tenant
- Useful for MSPs and large organizations

#### 4. Caching Layer

**What:** Cache TDX API responses to reduce latency

**Benefits:**
- Faster response times
- Reduced TDX API calls
- Better handling of temporary outages

**Considerations:**
- Cache invalidation strategy
- Stale data risks
- Storage requirements

#### 5. Rate Limiting

**What:** Limit requests per API key

**Benefits:**
- Prevent abuse
- Ensure fair resource allocation
- Better resource predictability

#### 6. Metrics & Monitoring

**What:** Prometheus-compatible metrics endpoint

**Metrics:**
- Request count by endpoint
- Response times
- Error rates
- Process pool utilization

#### 7. Advanced Logging

**What:** Structured logging with ELK stack integration

**Benefits:**
- Better debugging
- Performance analysis
- Security audit trails
- Compliance requirements

### Contributing Enhancements

To implement a feature:

1. **Discuss requirements** - What problem does it solve?
2. **Design solution** - How will it be implemented?
3. **Implement changes** - Modify source files
4. **Test thoroughly** - Unit and integration tests
5. **Document changes** - Update guides
6. **Deploy carefully** - Test on staging first

---

## Support & Resources

### Documentation Files

- [DEPLOYMENT_UBUNTU.md](DEPLOYMENT_UBUNTU.md) - Ubuntu deployment guide
- [COPILOT_INTEGRATION.md](COPILOT_INTEGRATION.md) - Copilot Studio setup
- [README.md](README.md) - Project overview
- [SOLUTION_GUIDE.md](SOLUTION_GUIDE.md) - This file

### Log Access

**View service logs:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f"
```

**Export logs for analysis:**
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp --since '2 hours ago' > tdx-logs.txt"
scp itmcp@10.210.1.38:tdx-logs.txt ./
```

### Debugging Commands

```bash
# Service status
sudo systemctl status tdx-mcp

# Check configuration
sudo cat /etc/systemd/system/tdx-mcp.service

# Test HTTP endpoints
curl -v http://localhost:3000/health

# Verify API key
grep MCP_API_KEY /etc/systemd/system/tdx-mcp.service

# Test with API key
curl -H "Authorization: Bearer YOUR_KEY" http://localhost:3000/status

# Monitor process usage
top -p $(pgrep -f http-wrapper)

# Check file permissions
ls -la /opt/tdx-mcp/

# Verify .env file
ls -la /opt/tdx-mcp/.env
```

### Getting Help

1. **Check logs first:**
   ```bash
   sudo journalctl -u tdx-mcp -n 50
   ```

2. **Check this troubleshooting guide:** See [Troubleshooting](#troubleshooting) section

3. **Verify configuration:**
   ```bash
   sudo systemctl cat tdx-mcp
   cat /opt/tdx-mcp/.env
   ```

4. **Test components individually:**
   - Test TDX API directly
   - Test HTTP wrapper health endpoint
   - Test MCP tools with curl

5. **Escalation:** If unresolved, check logs for specific error messages

---

## Summary

**Deployment Status:** ✅ Active and running

**Key Points:**
- Persistent HTTP service running on 10.210.1.38:3000
- API key authentication required (except `/health`)
- Auto-restart on failure and server reboot enabled
- 43 MCP tools available for Copilot Studio
- Ready for production Copilot integration

**Next Steps:**
1. Configure Copilot Studio with the HTTP endpoint
2. Create actions for needed TDX operations
3. Test end-to-end from Copilot to TDX
4. Monitor service health and performance
5. Plan for advanced key rotation (future enhancement)

**For Questions:** See documentation files or troubleshooting guide above.

---

**Last Updated:** May 7, 2026  
**Version:** 1.0  
**Author:** Deployment Automation
