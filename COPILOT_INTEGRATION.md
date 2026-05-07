# TDX MCP HTTP Server - Copilot Studio Integration

## Status
✅ **Server is running and ready for Copilot Studio integration**
🔐 **API Key Authentication: ACTIVE** (All endpoints except `/health` require authentication)
📊 **Available Tools**: 43 tools across 10 domains

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
    "tdx-ticket-create",
    "tdx-ticket-search",
    "tdx-ticket-get",
    "tdx-ticket-update",
    "tdx-ticket-patch",
    "tdx-ticket-feed-get",
    "tdx-ticket-feed-add",
    "tdx-asset-create",
    "tdx-asset-search",
    "tdx-asset-get",
    "tdx-cmdb-create",
    "tdx-cmdb-search",
    "tdx-people-get",
    "tdx-projects-create",
    "tdx-account-search",
    "tdx-group-get",
    "tdx-kb-search",
    "... and 26 more tools ..."
  ]
}
```

**Complete tool list** (43 total):
- **Tickets** (9 tools): create, search, get, update, patch, feed-get, feed-add, add-asset, add-contact
- **Assets** (8 tools): create, search, get, update, patch, delete, categories, feed-add
- **CMDB** (7 tools): create, search, get, update, delete, feed-add, add-relationship
- **KB** (5 tools): search, create, get, update, delete
- **People** (4 tools): get, search, lookup, update
- **Projects** (4 tools): create, search, get, update
- **Accounts** (2 tools): get, search
- **Groups** (2 tools): get, search
- **Attributes** (1 tool): get
- **Statuses** (1 tool): get

### MCP Tool Invocation

**POST /mcp** - Direct MCP JSON-RPC endpoint for tool invocation
```
POST http://10.210.1.38:3000/mcp
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "tdx-ticket-search",
    "arguments": {
      "statusIds": [896],
      "maxResults": 10
    }
  }
}
```

**Response Format**:
```json
{
  "success": true,
  "results": {
    "success": true,
    "type": "tickets",
    "timestamp": "2026-05-07T18:30:00.123Z",
    "tool": "tdx-ticket-search",
    "data": [ ],
    "meta": {
      "count": 10,
      "resultType": "array",
      "query": { "statusIds": [896], "maxResults": 10 },
      "tool": { "name": "tdx-ticket-search", "type": "tickets" }
    }
  },
  "meta": {
    "executionTimeMs": 1250,
    "timestamp": "2026-05-07T18:30:00.123Z"
  }
}
```

## API Key Authentication

### Current Configuration
✅ **API Key is ACTIVE and deployed**

**Your API Key:**
```
226ee1edd38aea72c27c62e44d0d4edb101a97922568db6db77036f83fbcebde
```

**Protected Endpoints** (require API key):
- `GET /status`
- `GET /tools`
- `POST /mcp`

**Public Endpoints** (no authentication):
- `GET /health` (for load balancers and health checks)

### API Key Expiration
**❌ The MCP_API_KEY does NOT expire**
- This is a static authentication token configured in the systemd service
- It persists across service restarts and server reboots
- It only changes if you manually update it in the systemd service file

**Note**: This is different from the TDX API tokens in your `.env` file, which expire after 24 hours. The MCP wrapper automatically refreshes those tokens, so you don't need to worry about them.

### To Change the API Key

You may want to rotate your API key for security reasons:
- If you suspect the key has been compromised
- On a regular security rotation schedule
- When changing Copilot Studio configurations

**Steps to rotate the key:**

1. **Generate a new secure key:**
```bash
openssl rand -hex 32
```

2. **Update the service file:**
```bash
ssh itmcp@10.210.1.38 "sudo nano /etc/systemd/system/tdx-mcp.service"
```

3. **Find and update this line in the `[Service]` section:**
```ini
Environment="MCP_API_KEY=your-new-key-here"
```

4. **Restart the service:**
```bash
ssh itmcp@10.210.1.38 "sudo systemctl daemon-reload && sudo systemctl restart tdx-mcp"
```

5. **Update Copilot Studio** with the new key in the Authorization header

### Use API Key in Requests

Once enabled, all authenticated endpoints require the API key in the `Authorization` header:

**With curl:**
```bash
curl -H "Authorization: Bearer 226ee1edd38aea72c27c62e44d0d4edb101a97922568db6db77036f83fbcebde" \
  http://10.210.1.38:3000/status
```

**In Copilot Studio:**
Add this header to all authenticated requests:
```
Authorization: Bearer 226ee1edd38aea72c27c62e44d0d4edb101a97922568db6db77036f83fbcebde
```

**Example MCP request with API key:**
```
POST http://10.210.1.38:3000/mcp
Content-Type: application/json
Authorization: Bearer 226ee1edd38aea72c27c62e44d0d4edb101a97922568db6db77036f83fbcebde

{
  "method": "tickets_query",
  "params": {
    "query": "status:open"
  }
}
```

### Generate a New API Key

If you need to generate a new secure API key for rotation or security reasons:

**On Ubuntu:**
```bash
openssl rand -hex 32
```

**Example output:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

Then update your service file with the new key (see "To Change the API Key" section above).

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

- **Process Pooling**: HTTP wrapper maintains a pool of warm MCP processes for fast response times
- **Process Management**: Each request uses an available process from the pool (max 5 concurrent)
- **Request Timeout**: 10 seconds per request via `/mcp` endpoint, 30 seconds via HTTP transport
- **CORS**: Enabled for cross-origin requests from any origin
- **Response Format**: All `/mcp` responses transformed into agent-friendly JSON with metadata
- **API Key**: Static, non-expiring authentication token - persists across restarts

## HTTP Endpoints Summary

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/health` | GET | No | Health check (returns status, uptime) |
| `/status` | GET | Yes | Service status and version |
| `/tools` | GET | Yes | List all 43 available tools |
| `/mcp` | POST | Yes | Direct MCP JSON-RPC tool invocation |
| `/` | GET | Yes | MCP-over-HTTP SSE connection |
| `/` | POST | Yes | MCP-over-HTTP request/response |

## Environment Variables

Available environment variables:
- `MCP_HTTP_PORT` - HTTP server port (default: 3000)
- `MCP_API_KEY` - API key for authentication (generated during setup)
- `NODE_ENV` - Environment mode (default: production)
- `TDX_BASE_URL` - TeamDynamix API base URL
- `TDX_BEID` - TeamDynamix Business Edition ID
- `TDX_WEB_SERVICES_KEY` - TeamDynamix API key
- `TDX_APP_ID` - Default TDX App ID for service requests
- `TDX_ASSETS_APP_ID` - TDX App ID for asset requests
- `TDX_KB_APP_ID` - TDX App ID for knowledge base requests
- `MCP_API_KEY` - HTTP wrapper API key for request authentication (never expires, only changes if manually updated)
- `NODE_ENV` - Set to "production" for the service

**Note on credential management:**
- **MCP_API_KEY**: HTTP wrapper authentication - permanent unless manually rotated
- **TDX API credentials** (in .env): Auto-refresh every 24 hours - no manual action needed

## Next Steps

1. ✅ **API Key Authentication** - Already configured and active
2. **Configure Copilot Studio** with the HTTP endpoints (see Copilot Studio Configuration section above)
3. **Test connectivity** from Copilot to the MCP service using the API key
4. **Create agent actions** for each tool you need
5. **Test tool invocations** end-to-end from Copilot Studio

## Support

For issues, check:
- Service logs: `sudo journalctl -u tdx-mcp -f`
- Configuration: `/opt/tdx-mcp/.env`
- HTTP wrapper source: `/opt/tdx-mcp/src/http-wrapper.js`
