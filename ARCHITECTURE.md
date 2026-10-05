# 🏗️ System Architecture

Complete technical architecture of the GDPR DSAR Automation Platform.

## High-Level System Flow

```
Internet
  │
  ▼
┌─────────────────────────────────┐
│ Webhook Endpoint (n8n)          │
│ POST /webhook/dsar-intake-test  │
└────────────┬────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ Security Validation Layer        │
│ • Rate Limiting (100 req/min)    │
│ • HTTPS Enforcement              │
│ • Request Origin Validation      │
│ • Input Validation               │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ Data Extraction (Parallel)       │
│ • Email/IMAP Connector           │
│ • HubSpot API Integration        │
│ • Zendesk API Integration        │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ FastAPI Backend Processing       │
│ • Data Deduplication             │
│ • Data Categorization            │
│ • PII Classification             │
│ • Completeness Check             │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ AI Risk Assessment (OpenAI)      │
│ • Score: 0-100                   │
│ • Level: LOW/MEDIUM/HIGH         │
│ • Recommendation: auto/manual    │
└───────┬──────────────┬───────────┘
        │              │
   LOW RISK        HIGH RISK
        │              │
        ▼              ▼
   ┌─────────┐  ┌──────────────┐
   │Auto     │  │Queue for     │
   │Approve  │  │Manual Review │
   │Branch   │  │(Dashboard)   │
   └────┬────┘  └────┬─────────┘
        │            │
        ▼            ▼
  ┌──────────────────────────────┐
  │ Generate Secure Password     │
  │ • 16 characters              │
  │ • Mixed case, numbers, symbols
  │ • Stored in encryption_vault │
  │ • Expires in 24 hours        │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ PDF Generation               │
  │ • HTML to PDF conversion     │
  │ • Metadata embedding         │
  │ • Professional formatting    │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ Encryption (AES-256-CBC)     │
  │ • Key: Scrypt from password  │
  │ • IV: Random 16 bytes        │
  │ • Algorithm: AES-256-CBC     │
  │ • Output: Encrypted PDF      │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ Email Delivery Phase 1       │
  │ • Send encrypted PDF         │
  │ • Custom security message    │
  │ • Timestamp logging          │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ Wait 5 Minutes (Security)    │
  │ • Prevent password guessing  │
  │ • Ensure PDF delivery        │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ Email Delivery Phase 2       │
  │ • Send password separately   │
  │ • 24-hour expiry notice      │
  │ • Contact info included      │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ Audit & Tracking             │
  │ • Log delivery timestamps    │
  │ • Update request status      │
  │ • Store delivery records     │
  └────────┬─────────────────────┘
           │
           ▼
  ┌──────────────────────────────┐
  │ Supabase (Database)          │
  │ • dsar_requests              │
  │ • audit_log                  │
  │ • dsar_deliveries            │
  │ • encryption_vault           │
  └──────────────────────────────┘
```

## Component Architecture

### 1. Webhook Entry Point (n8n)
- **Purpose:** Receive DSAR requests
- **Protocol:** HTTP POST
- **Response:** Immediate 200 OK
- **URL:** `https://your-instance.com/webhook/dsar-intake-test`

### 2. Security Validation Layer
Executed in order:
1. Rate Limit Check (100 req/min)
2. Request Origin Validation
3. HTTPS Enforcement
4. Input Validation & Sanitization

### 3. Data Extraction (Parallel)
Extracts data from:
- **Email/IMAP:** Email messages
- **HubSpot:** CRM contact records
- **Zendesk:** Support tickets & user data

### 4. Backend Processing (FastAPI)
- **Endpoint:** POST `/process-dsar`
- **Functions:**
  - Deduplication
  - Categorization
  - PII extraction
  - Completeness analysis

### 5. AI Risk Assessment (OpenAI)
- **Model:** GPT-3.5-Turbo
- **Input:** Extracted data summary
- **Output:** Risk score (0-100), level (LOW/MEDIUM/HIGH)
- **Decision:** Auto-approve or manual review

### 6. Branching Logic
**LOW RISK → Auto-Approve Path:**
- Generate secure password
- Encrypt PDF (AES-256)
- Send encrypted PDF
- Wait 5 minutes
- Send password separately
- Log all events

**HIGH RISK → Manual Review Path:**
- Queue in approval_queue table
- Notify compliance team
- Wait for manual approval/denial
- Then follow delivery path

### 7. Encryption Pipeline
- **Algorithm:** AES-256-CBC
- **Key Derivation:** Scrypt (32 bytes)
- **IV:** Random 16 bytes
- **Input:** PDF content
- **Output:** Encrypted data + IV

### 8. Secure Email Delivery
**Phase 1:** Encrypted PDF
- Subject: "Your Data Subject Access Request Response"
- Attachment: Encrypted PDF
- Message: Security instructions

**Phase 2:** Password (5 minutes later)
- Subject: "Your DSAR Decryption Password"
- Body: 16-character password
- Expiry: 24 hours

### 9. Audit & Logging
Events logged per request:
1. REQUEST_RECEIVED
2. RISK_ASSESSMENT_COMPLETED
3. AUTO_APPROVED or MANUAL_REVIEW_QUEUED
4. PDF_DELIVERY_INITIATED
5. PASSWORD_DELIVERY_INITIATED

### 10. Dashboard & Tracking
- **Approval Queue:** Real-time updates (5-second refresh)
- **Delivery Status:** PDF + password delivery tracking
- **Statistics:** Pending, approved, delivered counts
- **Manual Actions:** Approve/deny buttons for manual reviews

## Database Schema

### Tables

#### `dsar_requests` (Main Records)
```
id: UUID (primary key)
email: VARCHAR
name: VARCHAR
identifier: VARCHAR (unique)
received_at: TIMESTAMP
deadline_at: TIMESTAMP
status: VARCHAR (pending, delivered, denied)
notes: TEXT
request_type: VARCHAR
```

#### `audit_log` (Complete Trail)
```
id: UUID (primary key)
dsar_id: UUID (foreign key)
action: VARCHAR (REQUEST_RECEIVED, etc.)
actor: VARCHAR (webhook_intake, ai_engine, etc.)
actor_type: VARCHAR
timestamp: TIMESTAMP
action_details: JSONB
created_at: TIMESTAMP
```

#### `approval_queue` (Manual Reviews)
```
id: UUID (primary key)
dsar_id: UUID (foreign key)
status: VARCHAR (pending, approved, denied)
risk_level: VARCHAR
notes: TEXT
created_at: TIMESTAMP
updated_at: TIMESTAMP
```

#### `encryption_vault` (Passwords)
```
id: UUID (primary key)
dsar_id: UUID (foreign key)
password_hash: TEXT (base64 encoded)
encryption_algorithm: VARCHAR
created_at: TIMESTAMP
expires_at: TIMESTAMP
is_used: BOOLEAN
```

#### `dsar_deliveries` (Tracking)
```
id: UUID (primary key)
dsar_id: UUID (foreign key)
email_to: VARCHAR
delivery_type: VARCHAR (pdf, password)
status: VARCHAR (sent)
email_subject: TEXT
email_status: VARCHAR
sent_at: TIMESTAMP
notes: TEXT
```

#### `extracted_data` (Raw Extractions)
```
id: UUID (primary key)
dsar_id: UUID (foreign key)
system_name: VARCHAR
data_json: JSONB
extracted_at: TIMESTAMP
record_count: INTEGER
```

#### `processed_data` (Categorized)
```
id: UUID (primary key)
dsar_id: UUID (foreign key)
status: VARCHAR
total_records_extracted: INTEGER
total_records_deduplicated: INTEGER
pii_summary: JSONB
data_by_category: JSONB
processed_at: TIMESTAMP
```

## Security Layers

### Layer 1: Input Validation
- Email format validation (RFC 5321)
- Required field checking
- Length validation
- Character sanitization

### Layer 2: Rate Limiting
- 100 requests per minute per IP
- Sliding window counter
- Automatic blocking of excess requests

### Layer 3: HTTPS Enforcement
- All connections encrypted
- TLS 1.2+
- Certificate validation

### Layer 4: Credential Protection
- All credentials stored separately
- Never in workflow parameters
- Masked in logs
- Redaction enabled for executions

### Layer 5: Data Encryption
- AES-256-CBC for PDF content
- Scrypt key derivation
- Random IV for each encryption
- 24-hour password expiry

### Layer 6: Audit Logging
- All events logged
- 180-day retention
- Immutable audit trail
- Compliance-ready format

### Layer 7: Access Control
- Row Level Security (RLS) on all tables
- User-scoped data access
- Admin audit log access only

### Layer 8: Error Handling
- Errors logged without exposing secrets
- Graceful failure handling
- Admin notifications

## Data Flow Sequences

### Sequence 1: Successful Auto-Approval
```
1. Webhook receives request
2. Security checks pass
3. Data extracted from 3 systems
4. AI assessment: LOW RISK
5. Password generated
6. PDF encrypted
7. Email 1 sent (PDF)
8. Wait 5 minutes
9. Email 2 sent (Password)
10. Events logged
11. Status updated to "delivered"
```

### Sequence 2: Manual Review Path
```
1. Webhook receives request
2. Security checks pass
3. Data extracted from 3 systems
4. AI assessment: HIGH RISK
5. Request queued for review
6. Compliance team notified
7. Manual review in dashboard
8. Admin approves/denies
9. If approved: encrypt & send
10. Events logged
```

### Sequence 3: Error Handling
```
1. Any error occurs
2. Error logged to audit_log
3. Admin notified via email
4. Request status updated
5. Error details stored
6. Execution stopped gracefully
```

## Performance Considerations

### Optimization Points
- Parallel data extraction (3 systems simultaneously)
- Supabase connection pooling
- Batch audit logging
- Index on dsar_id & timestamp
- Query result caching (5 seconds)

### Scalability
- n8n: 1 worker → 10+ workers
- Database: PostgreSQL auto-scaling
- Railway: Auto-scaling containers
- API: Load balancing ready

### Resource Usage
- n8n: ~200MB memory per workflow
- Database: 100MB+ for 1000 requests/month
- Storage: 500MB-1GB for data
- Bandwidth: <1GB/month

## Deployment Architecture

```
┌──────────────────────────────────────┐
│ GitHub Repository                    │
│ (Code, Docs, Configuration)          │
└──────────┬───────────────────────────┘
           │ Auto-deploy
           ▼
┌──────────────────────────────────────┐
│ Railway (FastAPI Backend)            │
│ • dsar_processor.py                  │
│ • Docker container                   │
│ • Auto-scaling                       │
│ • Health checks                      │
└──────────┬───────────────────────────┘
           │
      ┌────┴────┐
      │          │
      ▼          ▼
┌──────────┐  ┌──────────────────────┐
│ Supabase │  │ n8n Workflow         │
│ (Database)   │ (54 nodes)           │
│              │ (Orchestration)      │
└──────────┘  └──────────────────────┘
      │          │
      └────┬─────┘
           │
           ▼
    ┌────────────┐
    │ Production │
    │  System    │
    └────────────┘
```

## Security Compliance

- ✅ **GDPR Article 15:** Data access upon request
- ✅ **GDPR Article 32:** Security of processing
- ✅ **GDPR Article 33:** Breach notification ready
- ✅ **GDPR Article 17:** Right to be forgotten (90-day auto-delete)
- ✅ **ISO 27001:** Security controls in place

---

**For detailed deployment, see [DEPLOYMENT.md](DEPLOYMENT.md)**
