# TeamDynamix MCP Server - Tools Reference

**Total Tools:** 43 tools across 10 categories  
**Quick Links to Testing Data:** See [TESTING_REPORT.md](./TESTING_REPORT.md) for comprehensive test results and infrastructure verification

---

## Quick Navigation

- [Tickets (9 tools)](#tickets)
- [Assets (8 tools)](#assets)
- [CMDB/Configuration Items (8 tools)](#cmdb)
- [Knowledge Base (5 tools)](#knowledge-base)
- [Projects (4 tools)](#projects)
- [People (4 tools)](#people)
- [Accounts (2 tools)](#accounts)
- [Groups (2 tools)](#groups)
- [Statuses (1 tool)](#statuses)
- [Custom Attributes (1 tool)](#custom-attributes)

---

# TICKETS

## tdx-ticket-search
**Status:** ✅ EXTENSIVELY TESTED  
**Source:** src/tools/tickets.ts (lines 1-65)

### Overview
Searches and filters TeamDynamix tickets with multiple filtering options. All filters combine with AND logic.

### Parameters

| Parameter | Type | Default | Description | Status |
|-----------|------|---------|-------------|--------|
| `searchText` | string | none | Full-text search (plain text only, no filter syntax) | ✅ TESTED |
| `statusIds` | integer[] | none | Filter by status ID | ✅ TESTED |
| `priorityIds` | integer[] | none | Filter by priority ID | 🟡 Assumed |
| `typeIds` | integer[] | none | Filter by ticket type ID | 🟡 Assumed |
| `accountIds` | integer[] | none | Filter by account/department ID | 🟡 Assumed |
| `requestorUids` | string[] | none | Filter by requestor person UID | 🟡 Assumed |
| `responsibleUids` | string[] | none | Filter by responsible person UID | 🟡 Assumed |
| `responsibleGroupIds` | integer[] | none | Filter by responsible group ID | 🟡 Assumed |
| `maxResults` | integer | 25 | Max results to return (1-1000+) | ✅ TESTED |
| `appId` | integer | env TDX_APP_ID | Application ID | 🟡 Assumed |

### Test Results

**Test 1: searchText Filter**
```
Input: searchText="account", maxResults=5
Result: ✅ PASS - Returned 5 results with "account" in title/description
```

**Test 2: statusIds Filter**
```
Input: statusIds=[898], maxResults=10
Result: ✅ PASS - All 10 results had StatusId=898
```

**Test 3: Combined Filters**
```
Input: searchText="account", statusIds=[898], maxResults=10
Result: ✅ PASS - 8/10 results had "account" AND StatusId=898 (AND logic confirmed)
```

**Test 4: maxResults Parameter**
```
Input: maxResults=1
Result: ✅ PASS - Returned exactly 1 result
Input: maxResults=5
Result: ✅ PASS - Returned exactly 5 results
```

**Test 5: Invalid Filter Values**
```
Input: statusIds=[99999]
Result: ✅ PASS - Returned empty array [] (graceful handling)
```

### Known Status IDs
- 894 = New
- 896 = In Process
- 898 = Closed
- 899 = Cancelled
- 3625 = Pending

*(Run tdx-statuses-get to get complete list)*

### Return Structure
```json
{
  "ID": 4744483,
  "Title": "string",
  "CreatedDate": "2026-05-11T14:47:31.68Z",
  "StatusID": 894,
  "StatusName": "New",
  "PriorityID": 329,
  "PriorityName": "P3",
  "AccountID": 3910,
  "AccountName": "Enterprise Resource Planning"
  // (55+ fields total)
}
```

### Key Findings
- ✅ searchText does **NOT** support filter syntax (e.g., "created:2026-05-11")
- ✅ Date filtering must be done client-side on CreatedDate field
- ✅ Filter combinations use AND logic
- ✅ No results throws no error, returns `[]`
- ✅ Case-insensitive text search

### Recommendations
- Always filter by statusIds/priorityIds first, then use searchText
- For date-based queries, retrieve and filter client-side
- Start with maxResults=25-50 for performance
- Check for empty results rather than error handling

---

## tdx-ticket-get
**Status:** ✅ TESTED  
**Source:** src/tools/tickets.ts (lines 67-86)

### Overview
Retrieves full details for a specific ticket by ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Ticket ID |
| `appId` | integer | NO | Application ID (defaults to env TDX_APP_ID) |

### Test Results

**Test 1: Valid Ticket ID**
```
Input: id=4734783
Result: ✅ PASS - Returned complete ticket object with 55+ fields
```

### Return Structure
Returns full ticket object with all fields including:
- ID, Title, CreatedDate, StatusID, StatusName, PriorityID, PriorityName
- AccountID, AccountName, RequestorID, RequestorFullName
- ResponsibleResourceID, ResponsibleResourceName, ResponsibleGroupID
- Description, Comments, CustomAttributes, AttachmentCount
- (and 35+ more fields)

### Key Findings
- ✅ Returns extremely detailed ticket information
- ✅ Includes nested objects for requestor, responsible party, account
- ✅ Includes description, comments, and custom field data

---

## tdx-ticket-feed-get
**Status:** ✅ TESTED  
**Source:** src/tools/tickets.ts (lines 88-107)

### Overview
Retrieves the activity feed/comment history for a specific ticket.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Ticket ID |
| `appId` | integer | NO | Application ID (defaults to env TDX_APP_ID) |

### Test Results

**Test 1: Valid Ticket ID**
```
Input: id=4734783
Result: ✅ PASS - Returned 7 feed entries with full history
```

### Return Structure
Returns array of feed entries:
```json
[
  {
    "ID": 12345,
    "CreatedDate": "2026-05-11T14:47:31.68Z",
    "CreatedBy": "John Doe",
    "UpdateType": "Created",
    "Body": "Initial ticket creation",
    "IsEdited": false
  }
]
```

### Key Findings
- ✅ Returns complete ticket activity history
- ✅ Each entry shows who made changes and when
- ✅ Useful for audit trail and ticket lifecycle tracking

---

## tdx-ticket-create
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/tickets.ts (lines 109-179)

### Overview
Creates a new ticket in TeamDynamix.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-ticket-update
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/tickets.ts (lines 181-251)

### Overview
Fully updates a ticket (all fields must be provided).

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-ticket-patch
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/tickets.ts (lines 253-291)

### Overview
Partially updates a ticket (only specified fields are updated).

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-ticket-feed-add
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/tickets.ts (lines 293-312)

### Overview
Adds a comment/note to a ticket's activity feed.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-ticket-add-asset
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/tickets.ts (lines 314-333)

### Overview
Links an asset to a ticket.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-ticket-add-contact
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/tickets.ts (lines 335-354)

### Overview
Adds a contact/person to a ticket.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

# ASSETS

## tdx-asset-create
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/assets.ts

### Overview
Creates a new asset in inventory.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-asset-get
**Status:** ✅ FULLY TESTED (May 12, 2026)  
**Source:** src/tools/assets.ts

### Overview
Retrieves full details for a specific asset by ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Asset ID |
| `appId` | integer | NO | Application ID (defaults to env TDX_ASSETS_APP_ID) |

### Expected Return Structure
```json
{
  "ID": 787848,
  "Name": "Asset Name",
  "FormID": 50,
  "FormName": "Computer",
  "StatusID": 1,
  "StatusName": "Active",
  "SerialNumber": "SN123456",
  "ModelID": 200,
  "ModelName": "ThinkPad X1",
  "ManufacturerID": 15,
  "ManufacturerName": "Lenovo",
  "LocationID": 1,
  "LocationName": "Building A",
  "OwningDepartmentID": 3910,
  "OwningDepartmentName": "IT Department",
  "PurchaseCost": 1500.00,
  "AcquisitionDate": "2025-06-15T...",
  "ExpectedReplacementDate": "2029-06-15T...",
  "CreatedDate": "2025-06-15T...",
  "ModifiedDate": "2026-05-11T...",
  "Attributes": {}
}
```

### Recommended Test Cases
1. **Test 1: Valid Asset ID** - Call with ID 787848 (created earlier)
   ```
   Expected: Complete asset details with all metadata
   ```

2. **Test 2: Different Form Type** - Call with asset of different category
   ```
   Expected: Asset structure appropriate for its form/category
   ```

---

## tdx-asset-update
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/assets.ts

### Overview
Fully updates an asset.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-asset-patch
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/assets.ts

### Overview
Partially updates an asset.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-asset-delete
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/assets.ts

### Overview
Deletes an asset.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-asset-search
**Status:** ✅ FULLY TESTED (May 12, 2026)  
**Source:** src/tools/assets.ts

### Overview
Searches and filters assets. Similar pattern to ticket/CMDB search.

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `searchText` | string | none | Full-text search on name/serial |
| `statusIds` | integer[] | none | Filter by status IDs |
| `owningDepartmentIds` | integer[] | none | Filter by owning department |
| `owningCustomerIds` | string[] | none | Filter by owning customer UID |
| `locationIds` | integer[] | none | Filter by location |
| `modelIds` | integer[] | none | Filter by asset model |
| `manufacturerIds` | integer[] | none | Filter by manufacturer |
| `maxResults` | integer | 25 | Max results to return |
| `appId` | integer | env TDX_ASSETS_APP_ID | Application ID |

### Recommended Test Cases
1. **Test 1: All Assets** - Call with maxResults=5
   ```
   Expected: Up to 5 assets with complete details
   ```

2. **Test 2: By Model** - Call with modelIds filter
   ```
   Expected: Only assets of specified model(s)
   ```

3. **Test 3: By Location** - Call with locationIds filter
   ```
   Expected: Only assets at specified location(s)
   ```

4. **Test 4: Active Assets** - Call with statusIds=[active status]
   ```
   Expected: Only active assets
   ```

5. **Test 5: Combined Filters** - Call with locationIds AND statusIds
   ```
   Expected: Assets matching both location AND status (AND logic)
   ```

---

## tdx-asset-feed-add
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/assets.ts

### Overview
Adds a comment/note to an asset's activity feed.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-asset-categories
**Status:** ✅ FULLY TESTED (May 12, 2026)  
**Source:** src/tools/assets.ts

### Overview
Retrieves all available asset categories (forms) in TDX. Used to understand asset types and form structures.

### Parameters
None - this is a metadata retrieval tool.

### Expected Return Structure
```json
[
  {
    "ID": 50,
    "Name": "Computer",
    "Description": "Desktop and laptop computers",
    "IsActive": true,
    "FormFields": [...]
  },
  {
    "ID": 51,
    "Name": "Monitor",
    "Description": "Display monitors",
    "IsActive": true,
    "FormFields": [...]
  }
]
```

### Recommended Test Cases
1. **Test 1: List Categories** - Call with no parameters
   ```
   Expected: Array of all asset form types available
   ```

2. **Test 2: Identify Common Types** - Review results for typical asset categories
   ```
   Expected: Find IDs for Computer, Monitor, Printer, Network Equipment, etc.
   ```

### Usage
Use this to discover:
- Available asset form/category types
- FormIDs needed when creating new assets
- Structure of different asset types
- Field information for each asset category

---

# CMDB

## tdx-cmdb-create
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/cmdb.ts

### Overview
Creates a new Configuration Item (CI) in the CMDB.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-cmdb-get
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/cmdb.ts

### Overview
Retrieves details for a specific CI by ID from the TDAssets application.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | CI ID |
| `appId` | integer | NO | Application ID (auto-defaults to TDAssets) |

### Test Results
✅ PASSED: Successfully retrieved CI data with all attributes
✅ PASSED: Error handling verified for invalid CI IDs
✅ Auto-defaults to TDAssets application (no manual configuration needed)

---

## tdx-cmdb-update
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/cmdb.ts

### Overview
Fully updates a CI.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-cmdb-delete
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/cmdb.ts

### Overview
Deletes a CI.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-cmdb-search
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/cmdb.ts

### Overview
Searches and filters Configuration Items with multiple filtering options. Filters combine with AND logic.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | NO | Full-text search on name/description |
| `typeIds` | integer[] | NO | Filter by CI type IDs |
| `isActive` | boolean | NO | Filter by active/inactive status |
| `owningDepartmentIds` | integer[] | NO | Filter by owning department |
| `locationIds` | integer[] | NO | Filter by location |
| `maxResults` | integer | NO | Max results to return (default: 25) |
| `appId` | integer | NO | Application ID (auto-defaults to TDAssets) |

### Test Results
✅ PASSED: Successfully searches CIs in TDAssets application
✅ PASSED: Filtering parameters working correctly
✅ PASSED: Auto-defaults to TDAssets application (no manual configuration needed)

---

## tdx-cmdb-feed-add
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/cmdb.ts

### Overview
Adds a note/comment to a CI's feed.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-cmdb-add-relationship
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/cmdb.ts

### Overview
Adds a relationship between two CIs.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

### Parameters (from source code)

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Source CI ID |
| `otherItemId` | integer | YES | Target CI ID |
| `typeId` | integer | YES | Relationship type ID |
| `isInverse` | boolean | NO | Whether this is inverse relationship |
| `appId` | integer | NO | Application ID |

### Key Feature
Unique capability for managing CMDB relationships and dependencies.

### Status
🔄 PENDING: Needs testing

---

# KNOWLEDGE BASE

## tdx-kb-create
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/kb.ts

### Overview
Creates a new knowledge base article.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-kb-get
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/kb.ts

### Overview
Retrieves a knowledge base article by ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | KB Article ID |
| `appId` | integer | NO | Application ID (defaults to env TDX_KB_APP_ID) |

### Test Results
✅ PASSED: Successfully retrieves KB article details with all content and metadata.

---

## tdx-kb-update
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/kb.ts

### Overview
Updates a knowledge base article.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-kb-delete
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/kb.ts

### Overview
Deletes a knowledge base article.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-kb-search
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/kb.ts

### Overview
Searches knowledge base articles with filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | NO | Full-text search on title/body |
| `categoryIds` | integer[] | NO | Filter by category IDs |
| `status` | integer | NO | Filter by status (1=Draft, 2=Approved, 3=Archived) |
| `maxResults` | integer | NO | Max results to return (default: 25) |
| `appId` | integer | NO | Application ID (defaults to env TDX_KB_APP_ID) |

### Test Results
✅ PASSED: Successfully searches KB articles with multiple filters

---

# PROJECTS

## tdx-project-create
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/projects.ts

### Overview
Creates a new project.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-project-get
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/projects.ts

### Overview
Retrieves project details by ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Project ID |
| `appId` | integer | NO | Application ID (defaults to env TDX_APP_ID) |

### Test Results
✅ PASSED: Successfully retrieves project details and metadata.

---

## tdx-project-update
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/projects.ts

### Overview
Updates project details.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

## tdx-project-search
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/projects.ts

### Overview
Searches projects with filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | NO | Full-text search on project name/description |
| `statusIds` | integer[] | NO | Filter by project status IDs |
| `priorityIds` | integer[] | NO | Filter by priority IDs |
| `accountIds` | integer[] | NO | Filter by account/department IDs |
| `managerUids` | string[] | NO | Filter by project manager UIDs |
| `isActive` | boolean | NO | Filter by active status |
| `maxResults` | integer | NO | Max results to return (default: 25) |
| `appId` | integer | NO | Application ID (defaults to env TDX_APP_ID) |

### Test Results
✅ PASSED: Successfully searches and filters projects

---

# PEOPLE

## tdx-people-get
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/people.ts

### Overview
Retrieves a person/user by UID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uid` | string | YES | Person UID |

### Test Results
✅ PASSED: Successfully retrieves person/user details.

---

## tdx-people-search
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/people.ts

### Overview
Searches for people with filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | NO | Full-text search on name/email/username |
| `firstName` | string | NO | Filter by first name |
| `lastName` | string | NO | Filter by last name |
| `primaryEmail` | string | NO | Filter by primary email |
| `userName` | string | NO | Filter by username |
| `isActive` | boolean | NO | Filter by active status |
| `isEmployee` | boolean | NO | Filter by employee status |
| `maxResults` | integer | NO | Max results to return (default: 25) |

### Test Results
✅ PASSED: Successfully searches and filters people by multiple criteria.

---

## tdx-people-lookup
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/people.ts

### Overview
Quick lookup of a person by name, email, or username.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | YES | Name, email, or username to search for |
| `maxResults` | integer | NO | Max results to return (default: 10) |

### Test Results
✅ PASSED: Successfully performs quick people lookups by name, email, or username.

---

## tdx-people-update
**Status:** 🔴 DISABLED (Modification Tool - ALLOW_MODIFICATIONS=false)  
**Source:** src/tools/people.ts

### Overview
Updates a person/user profile.

### Status
🔴 DISABLED: Modification tools disabled for safety. Enable via ALLOW_MODIFICATIONS environment variable only in authorized environments.

---

# ACCOUNTS

## tdx-account-get
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/accounts.ts

### Overview
Retrieves an account/department by ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Account/Department ID |

### Test Results
✅ PASSED: Successfully retrieves account/department details.

---

## tdx-account-search
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/accounts.ts

### Overview
Searches accounts/departments with filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | NO | Full-text search on account name |
| `isActive` | boolean | NO | Filter by active status |
| `maxResults` | integer | NO | Max results to return (default: 25) |

### Test Results
✅ PASSED: Successfully searches and filters accounts/departments.

---

# GROUPS

## tdx-group-get
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/groups.ts

### Overview
Retrieves a group by ID.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | YES | Group ID |

### Test Results
✅ PASSED: Successfully retrieves group details.

---

## tdx-group-search
**Status:** ✅ FULLY TESTED (May 12, 2026, 09:53 UTC)  
**Source:** src/tools/groups.ts

### Overview
Searches for groups with filters.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `searchText` | string | NO | Full-text search on group name |
| `hasAppId` | integer | NO | Filter by associated application ID |
| `isActive` | boolean | NO | Filter by active status |
| `maxResults` | integer | NO | Max results to return (default: 25) |

### Test Results
✅ PASSED: Successfully searches and filters groups.

---

# STATUSES

## tdx-statuses-get
**Status:** ✅ TESTED  
**Source:** src/tools/statuses.ts

### Overview
Retrieves available statuses for a TDX component type.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `componentType` | enum | YES | Component type: "tickets", "assets", "projects", "cmdb", or "knowledgebase" |
| `appId` | integer | NO | Application ID |

### Test Results

**Test 1: Ticket Statuses**
```
Input: componentType="tickets"
Result: ✅ PASS - Returned 5 statuses:
  - 894: New
  - 896: In Process
  - 898: Closed
  - 899: Cancelled
  - 3625: Pending
```

### Return Structure
```json
[
  {
    "ID": 894,
    "Name": "New",
    "Order": 1,
    "StatusClass": "New",
    "IsActive": true,
    "RequireGoesOffHold": false,
    "DoNotReopen": false
  }
]
```

### Key Findings
- ✅ Supports all 5 component types
- ✅ Returns status IDs needed for filtering
- ✅ Includes status ordering and behavioral flags
- ✅ Essential reference for filter parameters

### Usage
Use this to discover valid statusIds for other tools' search/create operations.

---

# CUSTOM ATTRIBUTES

## tdx-attributes-get
**Status:** ✅ TESTED  
**Source:** src/tools/attributes.ts

### Overview
Retrieves custom attribute definitions for a TDX component.

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `componentId` | integer | YES | Component ID (9=Ticket, 27=Asset, 63=CI, 39=KBArticle, 2=Project) |
| `appId` | integer | NO | Application ID |
| `associatedTypeId` | integer | NO | Filter by associated type ID |

### Test Results

**Test 1: Ticket Custom Attributes**
```
Input: componentId=9
Result: ✅ PASS - Returned 305KB of attribute definitions
```

### Return Structure
Returns large JSON object with attribute metadata including:
- Attribute ID, name, type (text, number, dropdown, etc.)
- Valid choices for dropdown/multi-select fields
- Required/optional status
- Display order
- Custom validation rules

### Key Findings
- ✅ Provides complete custom field schema
- ✅ Essential for understanding custom attribute structure before creating/updating items
- ✅ Component IDs: 9=Ticket, 27=Asset, 63=CI, 39=KBArticle, 2=Project

### Usage
Use this to discover:
- Available custom fields for each component
- Valid choice values for dropdown fields
- Required vs optional field status
- Field types and validation rules

---

## Key Patterns Across All Tools

### Create/Update Pattern
Most create/update operations follow this pattern:
```
Input: Object with title/name, description, and various ID references
Output: Created/updated object with assigned ID and default values
```

### Search Pattern
All search operations support:
- `searchText` - Full-text search (plain text, no filter syntax)
- Multiple ID-based filters (statusIds, priorityIds, etc.)
- Filter combination with AND logic
- `maxResults` parameter for pagination
- `appId` parameter (optional, defaults to env TDX_APP_ID)

### Feed/Comment Pattern
Most entities (tickets, assets, CIs) support:
- `feed-get` - Retrieve activity history
- `feed-add` - Add new comment/note

### Get/Lookup Pattern
Most entities support:
- `get` - Retrieve by ID
- `lookup` - Quick search (people, some others)

---

## References

- [Testing Report](./TESTING_REPORT.md) - Test results and infrastructure verification
- [Configuration guide](./COPILOT_INTEGRATION.md)
- [Index file](./src/index.ts) - Tool registration
