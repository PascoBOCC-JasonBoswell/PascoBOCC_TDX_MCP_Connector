#!/bin/bash

# Update MCP Server to HTTP Wrapper on Ubuntu Server
# This replaces the stdio server with an HTTP wrapper

set -e

echo "=== Updating TDX MCP to HTTP Wrapper ==="

# Update files
echo "Copying HTTP wrapper..."
sudo cp /tmp/tdx-mcp-source/PascoBOCC_TDX_MCP_Connector/src/http-wrapper.js /opt/tdx-mcp/src/
sudo cp /tmp/tdx-mcp-source/PascoBOCC_TDX_MCP_Connector/package.json /opt/tdx-mcp/

# Update systemd service
echo "Updating systemd service..."
sudo tee /etc/systemd/system/tdx-mcp.service > /dev/null << 'EOF'
[Unit]
Description=TDX MCP HTTP Server
After=network.target

[Service]
Type=simple
User=tdx-mcp
WorkingDirectory=/opt/tdx-mcp
ExecStart=/usr/bin/node /opt/tdx-mcp/src/http-wrapper.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tdx-mcp
Environment="NODE_ENV=production"
Environment="MCP_HTTP_PORT=3000"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Start the service
echo "Starting HTTP wrapper service..."
sudo systemctl start tdx-mcp

# Check status
sleep 2
echo "Service status:"
sudo systemctl status tdx-mcp

# Test the endpoint
echo ""
echo "Testing HTTP wrapper..."
sleep 2
curl -s http://localhost:3000/health | jq . || echo "Health check failed (service may still be starting)"

echo ""
echo "=== Update Complete ==="
echo "HTTP Wrapper is running on http://localhost:3000"
echo "Endpoints:"
echo "  - Health: http://localhost:3000/health"
echo "  - Status: http://localhost:3000/status"
echo "  - Tools: http://localhost:3000/tools"
echo "  - MCP: http://localhost:3000/mcp (POST JSON-RPC)"
