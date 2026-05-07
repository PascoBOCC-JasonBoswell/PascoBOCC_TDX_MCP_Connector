# TDX MCP HTTP API Response Schema

## Overview

This document describes the response format from the TDX MCP HTTP wrapper. All responses are designed for agent consumption with pre-parsed data, metadata, and execution metrics.

## Standard Response Format

All successful API responses follow this structure:

```json
{
  "success": true,
  "results": {
    "success": true,
    "type": "tickets|assets|configurationItems|projects|accounts|groups|people|knowledgeBase|statuses|unknown",
    "timestamp": "2026-05-07T18:30:00.000Z",
    "tool": "tool-name",
    "data": [],
    "meta": {
      "count": 10,
      "resultType": "array|object",
      "query": {},
      "tool": {
        "name": "tool-name",
        "type": "tickets"
      }
    }
  },
  "meta": {
    "executionTimeMs": 1250,
    "timestamp": "2026-05-07T18:30:00.000Z"
  }
}
```

**Note**: The `results` field contains a single transformed result object. Typically, one MCP tool call produces one result. If multiple results are returned, they appear as an array in the `results` field.

## Response Fields

### Top Level

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Indicates if request was successful |
| `results` | object | Primary result container |
| `meta` | object | Response metadata (execution time, timestamp) |

### Results Object

| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Query execution success flag |
| `type` | string | Entity type returned (tickets, assets, etc.) |
| `timestamp` | ISO 8601 | When the query was executed |
| `tool` | string | MCP tool name that was called |
| `data` | array\|object | **Actual parsed data** - ready for use (no parsing needed) |
| `meta` | object | Query and result metadata |

### Meta Object (within Results)

| Field | Type | Description |
|-------|------|-------------|
| `count` | number | Number of items in result set |
| `resultType` | string | `"array"` if data is array, `"object"` if single object |
| `query` | object | Original query parameters sent to the tool |
| `tool` | object | Tool information (name, entity type) |

### Response Meta Object (top level)

| Field | Type | Description |
|-------|------|-------------|
| `executionTimeMs` | number | Query execution time in milliseconds |
| `timestamp` | ISO 8601 | Response generation timestamp |

## Entity Types

The `type` field indicates what kind of data was returned:

| Type | Description | Example Tools |
|------|-------------|----------------|
| `tickets` | ServiceNow/TDX tickets | `tdx-ticket-search`, `tdx-ticket-get`, `tdx-ticket-create` |
| `assets` | IT assets/inventory | `tdx-asset-search`, `tdx-asset-get`, `tdx-asset-create` |
| `configurationItems` | CMDB configuration items | `tdx-cmdb-search`, `tdx-cmdb-get`, `tdx-cmdb-create` |
| `projects` | Projects | `tdx-project-get`, `tdx-project-search`, `tdx-project-create` |
| `accounts` | Department/account records | `tdx-account-search`, `tdx-account-get` |
| `groups` | User groups/teams | `tdx-group-search`, `tdx-group-get` |
| `people` | User/person records | `tdx-people-get`, `tdx-people-search`, `tdx-people-lookup` |
| `knowledgeBase` | Knowledge base articles | `tdx-kb-search`, `tdx-kb-get`, `tdx-kb-create` |
| `statuses` | Status options | `tdx-statuses-get` |

## Usage Examples

### Example 1: Ticket Search Response

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "tdx-ticket-search",
    "arguments": {
      "statusIds": [896],
      "maxResults": 10
    }
  },
  "id": 1
}
```

**Response:**
```json
{
  "success": true,
  "results": {
    "success": true,
    "type": "tickets",
    "timestamp": "2026-05-07T18:30:00.123Z",
    "tool": "tdx-ticket-search",
    "data": [
      {
        "ID": 4733346,
        "Title": "Terminated - K.J.G",
        "CreatedDate": "2026-05-07T16:30:44.357Z",
        "StatusID": 896,
        "StatusName": "In Process",
        "AccountName": "Corrections",
        ...
      },
      ...
    ],
    "meta": {
      "count": 10,
      "resultType": "array",
      "query": {
        "statusIds": [896],
        "maxResults": 10
      },
      "tool": {
        "name": "tdx-ticket-search",
        "type": "tickets"
      }
    }
  },
  "meta": {
    "executionTimeMs": 1250,
    "timestamp": "2026-05-07T18:30:00.123Z"
  }
}
```

### How to Access Data

```javascript
// In JavaScript/Node.js
const response = await fetch('http://10.210.1.38:3000/mcp', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_API_KEY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    jsonrpc: '2.0',
    method: 'tools/call',
    params: {
      name: 'tdx-ticket-search',
      arguments: { statusIds: [896] }
    },
    id: 1
  })
});

const json = await response.json();

// Access the actual data directly (no parsing needed!)
const tickets = json.results.data;
const count = json.results.meta.count;
const executionTime = json.meta.executionTimeMs;

console.log(`Retrieved ${count} tickets in ${executionTime}ms`);
tickets.forEach(ticket => {
  console.log(`${ticket.ID}: ${ticket.Title}`);
});
```

## Error Responses

When an error occurs:

```json
{
  "success": false,
  "error": "Error message describing what went wrong",
  "details": "Additional context about the error",
  "meta": {
    "executionTimeMs": 150,
    "timestamp": "2026-05-07T18:30:00.123Z"
  }
}
```

## Performance Metrics

- **Typical query time**: 800-2000ms (including MCP process overhead)
- **Process pool warm-up time**: <1s (on server startup)
- **Max result set**: 500 items (configurable per tool)

## Key Advantages for Agents

1. ✅ **Data Already Parsed**: Access `results.data` directly - it's already a JavaScript object/array
2. ✅ **Result Metadata**: `meta.count` tells you how many items you got
3. ✅ **Query Echo**: `meta.query` shows what parameters were used
4. ✅ **Performance Metrics**: `meta.executionTimeMs` for monitoring
5. ✅ **Entity Type Classification**: `type` field identifies the data type immediately
6. ✅ **Consistent Structure**: All tool responses follow the same schema

## Accessing Nested Data

```javascript
// Good - Direct access to parsed data
const tickets = response.results.data;
tickets.forEach(ticket => {
  console.log(ticket.Title);
});

// Not needed - Data is already parsed
// ❌ DON'T DO THIS: JSON.parse(response.results.data.text)

// Get metadata about the response
const resultCount = response.results.meta.count;
const executionTime = response.meta.executionTimeMs;
const queryUsed = response.results.meta.query;
```

## Query Parameters by Tool

### tdx-ticket-search

**Arguments:**
```json
{
  "statusIds": [number],           // Array of status IDs to filter
  "searchText": "string",          // Full-text search
  "priorityIds": [number],         // Array of priority IDs
  "typeIds": [number],             // Array of ticket type IDs
  "accountIds": [number],          // Array of account/department IDs
  "responsibleUids": [string],     // Array of user UIDs
  "responsibleGroupIds": [number], // Array of group IDs
  "requestorUids": [string],       // Array of requestor UIDs
  "maxResults": number             // Max items to return (default: 25, max: 500)
}
```

**Response Data:**
```json
[
  {
    "ID": number,
    "Title": string,
    "Description": string,
    "CreatedDate": "ISO 8601",
    "ModifiedDate": "ISO 8601",
    "StatusID": number,
    "StatusName": string,
    "PriorityID": number,
    "PriorityName": string,
    "AccountName": string,
    "RequestorName": string,
    "ResponsibleFullName": string,
    "ResponsibleGroupName": string,
    // ... many more fields
  }
]
```

### Other Tools

See individual tool documentation for parameters and response structures.

## Best Practices

1. **Always check `success` field** before accessing `data`
2. **Use `meta.count`** to know result set size
3. **Check `resultType`** to determine if `data` is array or object
4. **Monitor `executionTimeMs`** for performance tracking
5. **Store `query`** for audit/debugging purposes
6. **Use `type` field** for data validation and routing

## Implementation Example

```typescript
interface MCPResponse<T> {
  success: boolean;
  results: {
    success: boolean;
    type: string;
    timestamp: string;
    tool: string;
    data: T;
    meta: {
      count: number;
      resultType: 'array' | 'object';
      query: Record<string, any>;
      tool: { name: string; type: string };
    };
  };
  meta: {
    executionTimeMs: number;
    timestamp: string;
  };
}

// Usage
async function queryTickets() {
  const response = await fetch(...) as MCPResponse<Ticket[]>;
  
  if (!response.success) {
    throw new Error('Request failed');
  }
  
  const tickets = response.results.data;
  console.log(`Got ${response.results.meta.count} tickets in ${response.meta.executionTimeMs}ms`);
  
  return tickets;
}
```

## Related Documentation

- [MCP Tools Reference](./tools-reference.md) - Detailed tool documentation
- [API Authentication](./authentication.md) - Bearer token setup
- [Response Transformation](./response-transformation.md) - How responses are built
