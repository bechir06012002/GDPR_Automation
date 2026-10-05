# 📚 API Documentation

Complete API reference for the GDPR DSAR Automation Platform.

## Webhook Endpoint

### DSAR Intake Webhook

**Endpoint:**
```
POST https://your-webhook-url/webhook/dsar-intake-test
```

**Purpose:** Submit a new DSAR request

**Authentication:** None (public endpoint - rate limited)

**Rate Limit:** 100 requests per minute per IP

### Request

**Headers:**
```http
Content-Type: application/json
```

**Body Schema:**
```json
{
  "email": "string (required)",
  "name": "string (required)",
  "identifier": "string (required, unique)",
  "request_type": "string (optional, default: 'full_access')",
  "additional_info": "string (optional)"
}
```

**Field Descriptions:**

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| email | String | Yes | Email address of data subject | "john@example.com" |
| name | String | Yes | Full name of data subject | "John Smith" |
| identifier | String | Yes | Unique ID (customer ID, employee ID, etc.) | "CUST-12345" |
| request_type | String | No | Type of request | "full_access", "specific_data", "deletion" |
| additional_info | String | No | Extra context for compliance team | "Specific data on marketing preferences" |

### Request Examples

**Minimal Request (required fields only):**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "name": "John Smith",
    "identifier": "CUST-12345"
  }'
```

**Full Request (all fields):**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "name": "John Smith",
    "identifier": "CUST-12345",
    "request_type": "full_access",
    "additional_info": "Please include all marketing communications"
  }'
```

**PowerShell Example:**
```powershell
$body = @{
    email = "john@example.com"
    name = "John Smith"
    identifier = "CUST-12345"
    request_type = "full_access"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://your-webhook-url/webhook/dsar-intake-test" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

**Python Example:**
```python
import requests
import json

url = "https://your-webhook-url/webhook/dsar-intake-test"
payload = {
    "email": "john@example.com",
    "name": "John Smith",
    "identifier": "CUST-12345",
    "request_type": "full_access"
}

response = requests.post(url, json=payload)
print(response.status_code)
print(response.json())
```

### Response

**Success (200 OK):**
```json
{
  "status": "success",
  "message": "DSAR request received and processing",
  "dsar_id": "550e8400-e29b-41d4-a716-446655440000",
  "identifier": "CUST-12345",
  "email": "john@example.com",
  "request_type": "full_access",
  "expected_delivery": "2-10 minutes (auto) or 1-5 days (manual review)",
  "next_steps": "You will receive an email shortly with updates"
}
```

**Rate Limit Exceeded (429 Too Many Requests):**
```json
{
  "status": "error",
  "message": "Rate limit exceeded: 100 requests per minute",
  "retry_after": 60
}
```

**Validation Error (400 Bad Request):**
```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    },
    {
      "field": "name",
      "message": "Name is required"
    }
  ]
}
```

**Server Error (500 Internal Server Error):**
```json
{
  "status": "error",
  "message": "Internal server error. Please contact support.",
  "support_email": "privacy@example.com",
  "reference_id": "ERR-550e8400"
}
```

## Response Status Codes

| Code | Status | Meaning |
|------|--------|---------|
| 200 | OK | DSAR request received successfully |
| 400 | Bad Request | Validation error in request |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | System error (not user's fault) |
| 503 | Service Unavailable | System temporarily down |

## Email Responses

### Email 1: PDF Delivery (sent immediately)

**To:** Data subject email
**Subject:** Your Data Subject Access Request Response
**Body:**
```
Dear [Name],

Thank you for submitting your Data Subject Access Request (DSAR).

Your personal data has been compiled and is attached to this email 
as a SECURE ENCRYPTED PDF.

IMPORTANT - SECURITY:
Your data is encrypted with AES-256 encryption (military-grade).
In about 5 minutes, you will receive a separate email containing 
the decryption password.

KEEP THESE EMAILS SEPARATE for security.

Never share the password via email or messaging apps.

Your data will be provided within 30 days as required by GDPR 
Article 15.

Questions? Contact: privacy@example.com

Best regards,
Compliance Team
```

### Email 2: Password Delivery (sent 5 minutes later)

**To:** Data subject email
**Subject:** Your DSAR Decryption Password
**Body:**
```
Dear [Name],

Your DSAR decryption password is:

[16-CHARACTER PASSWORD]

This password:
- Decrypts your DSAR PDF
- Expires in 24 hours
- Can only be used once

To open your encrypted PDF:
1. Download the PDF from previous email
2. Open with any PDF reader
3. Enter the password when prompted
4. Your data will be displayed

SECURITY TIPS:
- Don't share this password
- Don't email the password elsewhere
- Delete this email after use
- The password cannot be recovered if forgotten

Questions? Contact: privacy@example.com

Best regards,
Compliance Team
```

## Dashboard API (Future)

### Get DSAR Status

**Endpoint:**
```
GET /api/dsar/{dsar_id}
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "john@example.com",
  "identifier": "CUST-12345",
  "status": "delivered",
  "risk_level": "LOW",
  "received_at": "2026-10-05T10:30:00Z",
  "delivered_at": "2026-10-05T10:45:00Z",
  "data_categories": [
    "Personal Information",
    "Communication History",
    "Transaction Records",
    "System Logs"
  ],
  "total_records": 1247
}
```

### Get Approval Queue (Admin)

**Endpoint:**
```
GET /api/admin/approval-queue
```

**Response:**
```json
{
  "count": 5,
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "identifier": "CUST-12345",
      "risk_level": "HIGH",
      "risk_score": 78,
      "submitted_at": "2026-10-05T08:00:00Z",
      "reason": "Multiple data sources with conflicting information"
    }
  ]
}
```

### Approve/Deny DSAR (Admin)

**Endpoint:**
```
POST /api/admin/approve
```

**Body:**
```json
{
  "dsar_id": "550e8400-e29b-41d4-a716-446655440000",
  "action": "approve",
  "notes": "Verified identity and approved for delivery"
}
```

## Backend Processing

### FastAPI Endpoints

**Health Check:**
```
GET /health

Response:
{
  "status": "healthy"
}
```

**DSAR Processor:**
```
POST /process-dsar

Body:
{
  "dsar_id": "uuid",
  "extracted_data": {...}
}

Response:
{
  "status": "processed",
  "record_count": 1247,
  "deduped_count": 234,
  "data_categories": [...]
}
```

## Audit Log Structure

Each DSAR generates 5-7 audit log entries:

```json
{
  "id": "uuid",
  "dsar_id": "uuid",
  "action": "REQUEST_RECEIVED|RISK_ASSESSMENT_COMPLETED|AUTO_APPROVED|MANUAL_REVIEW_QUEUED|PASSWORD_DELIVERY_INITIATED",
  "actor": "webhook_intake|ai_engine|approval_system|delivery_service",
  "actor_type": "system|human",
  "timestamp": "2026-10-05T10:30:00Z",
  "action_details": {
    // Varies by action
  },
  "ip_address": "1.2.3.4",
  "created_at": "2026-10-05T10:30:00Z"
}
```

## Webhooks (Incoming Only)

This system receives webhooks (DSAR requests).

It does NOT send webhooks to external systems (can be added as extension).

## Error Handling

### Common Errors

**Invalid Email:**
```
{
  "status": "error",
  "message": "Validation failed: Invalid email format"
}
```

**Missing Required Field:**
```
{
  "status": "error",
  "message": "Validation failed: Missing email or name"
}
```

**Duplicate Identifier:**
```
{
  "status": "error",
  "message": "This DSAR identifier already exists"
}
```

**Rate Limited:**
```
{
  "status": "error",
  "message": "Rate limit exceeded: 100 requests per minute",
  "retry_after": 60
}
```

## Best Practices

### When Submitting DSARs

✅ **DO:**
- Include accurate email address
- Use unique identifier per subject
- Wait for confirmation email
- Don't resubmit if unsure
- Contact support if issue

❌ **DON'T:**
- Submit duplicate requests
- Use test emails in production
- Share passwords
- Forward security emails
- Submit requests for others

### When Processing Results

✅ **DO:**
- Save encrypted PDF safely
- Store password separately
- Verify data completeness
- Check for errors
- Contact support with reference ID

❌ **DON'T:**
- Share unencrypted data
- Forget password
- Ignore errors
- Process manually if automated
- Lose the PDF

## Support

For API issues:

1. **Check this documentation**
2. **Review docs/TROUBLESHOOTING.md**
3. **Contact support:** privacy@example.com
4. **Include:** Error message, timestamp, reference ID

## Rate Limiting Details

```
Limit: 100 requests per minute
Scope: Per IP address
Reset: Every 60 seconds (sliding window)
Headers:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 87
  X-RateLimit-Reset: 1633430160

Example:
Request 1 at 10:00:00 → OK (1/100)
Request 101 at 10:00:30 → OK (101/100 not counted yet)
Request 101 at 10:00:31 → BLOCKED (429)
Request 102 at 10:01:00 → OK (window reset)
```

---

**For complete implementation examples, see the test files in docs/TESTING.md**
