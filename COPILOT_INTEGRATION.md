# TDX MCP HTTP Server - Copilot Studio Integration

## Status
✅ **Server is running and ready for Copilot Studio integration**

## Service Details
- **Status**: Active (running)
- **Port**: 3000
- **Server**: 10.210.1.38
- **User**: tdx-mcp
- **Service**: systemd (tdx-mcp.service)

## HTTP Endpoints

### Health Check
```
GET http://10.210.1.38:3000/health
```
Response:
```json
{
  "status": "healthy",
  "uptime": 29.54,
  "timestamp": "2026-05-07T15:22:09.310Z"
}
```

### Service Status
```
GET http://10.210.1.38:3000/status
```
Response:
```json
{
  "service": "TDX MCP HTTP Wrapper",
  "version": "1.0.0",
  "port": "3000",
  "uptime": 29.54,
  "timestamp": "2026-05-07T15:22:17.460Z"
}
```

### List Available Tools
```
GET http://10.210.1.38:3000/tools
```
Response:
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

### MCP Tool Invocation
```
POST http://10.210.1.38:3000/mcp
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "invoke_tool",
  "params": {
    "name": "tickets_query",
    "arguments": {
      "query": "status:open"
    }
  }
}
```

## Copilot Studio Configuration

### Step 1: Add Custom Connector
In Copilot Studio:
1. Go to **Plugins**
2. Click **+ Create a plugin**
3. Select **Connect to web service**
4. Name: `TDX MCP Connector`

### Step 2: Configure Authentication (if needed)
- Auth type: `API Key` (if adding auth layer)
- Endpoint base URL: `http://10.210.1.38:3000`

### Step 3: Create Actions
Create actions for each tool:

**Example: Query Tickets**
```
POST /mcp
{
  "method": "tickets_query",
  "params": {
    "query": "<user_input>"
  }
}
```

**Example: Create Ticket**
```
POST /mcp
{
  "method": "tickets_create",
  "params": {
    "title": "<title>",
    "description": "<description>",
    "status": "<status>"
  }
}
```

## Service Management

### Check Service Status
```bash
ssh itmcp@10.210.1.38 "sudo systemctl status tdx-mcp"
```

### View Logs
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -f"
```

### Restart Service
```bash
ssh itmcp@10.210.1.38 "sudo systemctl restart tdx-mcp"
```

### Stop Service
```bash
ssh itmcp@10.210.1.38 "sudo systemctl stop tdx-mcp"
```

### Start Service
```bash
ssh itmcp@10.210.1.38 "sudo systemctl start tdx-mcp"
```

## Network Configuration

### Port 3000 Access
If accessing from remote machines:

**Option 1: SSH Tunnel (Secure)**
```bash
ssh -L 3000:localhost:3000 itmcp@10.210.1.38
```

**Option 2: Open Firewall (if needed)**
```bash
sudo ufw allow 3000/tcp
```

## Troubleshooting

### Service Not Starting
```bash
ssh itmcp@10.210.1.38 "sudo journalctl -u tdx-mcp -n 50"
```

### Health Check Fails
```bash
ssh itmcp@10.210.1.38 "curl -v http://localhost:3000/health"
```

### MCP Endpoint Not Responding
```bash
ssh itmcp@10.210.1.38 "sudo systemctl restart tdx-mcp && sleep 2 && curl http://localhost:3000/health"
```

## Integration Notes

- The HTTP wrapper spawns MCP server processes on demand
- Each request creates a subprocess that processes the tool invocation
- Processes are pooled for efficiency (max 5 concurrent)
- Timeouts after 10 seconds per request
- CORS enabled for cross-origin requests

## Environment Variables

Available environment variables:
- `MCP_HTTP_PORT` - HTTP server port (default: 3000)
- `NODE_ENV` - Set to "production" for the service

## Next Steps

1. **Configure Copilot Studio** with the HTTP endpoints
2. **Test connectivity** from Copilot to the MCP service
3. **Create agent actions** for each tool you need
4. **Configure authentication** if required for the TDX API

## Support

For issues, check:
- Service logs: `sudo journalctl -u tdx-mcp -f`
- Configuration: `/opt/tdx-mcp/.env`
- HTTP wrapper source: `/opt/tdx-mcp/src/http-wrapper.js`
