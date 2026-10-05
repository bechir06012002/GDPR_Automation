# 🧪 Testing Guide

Complete testing procedures for the GDPR DSAR Automation Platform.

## Test Environment Setup

Before testing, ensure you have:

✅ Development n8n instance OR production webhook URL
✅ Test Supabase project (or test branch of production DB)
✅ Test email account (Gmail with app password)
✅ OpenAI API key with testing quota
✅ Railway staging environment

## Test 1: Basic Webhook Connectivity

**Objective:** Verify webhook endpoint is responding

**Steps:**

1. Get your webhook URL from n8n:
   - Open n8n workflow
   - Find "Webhook" node
   - Copy test URL

2. Send test request:
```bash
curl -X POST https://your-webhook-url \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "identifier": "TEST-001"
  }'
```

3. Expected response:
```
HTTP 200 OK
{
  "status": "success",
  "dsar_id": "550e8400-..."
}
```

**Pass Criteria:** HTTP 200 with successful response

---

## Test 2: Complete End-to-End Flow (Auto-Approve Path)

**Objective:** Verify complete DSAR processing for LOW RISK request

**Prerequisites:**
- All credentials configured in n8n
- Email account ready to receive 2 emails
- Test database empty

**Steps:**

1. **Submit DSAR Request**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@gmail.com",
    "name": "Low Risk Test",
    "identifier": "TEST-AUTO-001"
  }'
```

2. **Monitor n8n Workflow**
   - Open n8n workflow
   - Click "Execute Workflow"
   - Watch nodes execute (should take 2-5 minutes)
   - Check for green checkmarks on all nodes

3. **Verify Database Records**
   - Go to Supabase SQL Editor
   - Run verification queries (see below)
   - Should see: 1 dsar_request, 5 audit_log entries

4. **Check Emails Received**
   - Email 1: Encrypted PDF (should arrive within 1 min)
   - Email 2: Password (should arrive 5 min later)

5. **Verify Audit Trail**
```sql
SELECT action, timestamp FROM audit_log 
WHERE dsar_id = (SELECT id FROM dsar_requests WHERE identifier = 'TEST-AUTO-001')
ORDER BY timestamp;
```

Expected events:
- REQUEST_RECEIVED
- RISK_ASSESSMENT_COMPLETED
- AUTO_APPROVED
- PASSWORD_DELIVERY_INITIATED

**Pass Criteria:**
- ✅ HTTP 200 response
- ✅ All n8n nodes green
- ✅ 2 emails received
- ✅ 5 audit events logged
- ✅ Database records created

---

## Test 3: High-Risk Path (Manual Review)

**Objective:** Verify manual review workflow

**Modifications for HIGH RISK:**
Use suspicious data pattern to trigger high-risk assessment:
- Multiple different email addresses
- Contradictory data
- Flags in email content

**Steps:**

1. **Submit HIGH RISK Request**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@gmail.com",
    "name": "John * (suspicious)",
    "identifier": "TEST-MANUAL-001",
    "additional_info": "Multiple accounts on record need verification"
  }'
```

2. **Monitor Workflow**
   - Should branch to FALSE (manual review)
   - Queue in approval_queue table
   - Skip password generation

3. **Check Dashboard**
   - Open approval dashboard
   - Should show 1 pending approval
   - Click to view details

4. **Approve in Dashboard**
   - Click "Approve" button
   - Should generate password
   - Trigger email delivery

5. **Verify Audit Trail**
```sql
SELECT action FROM audit_log 
WHERE dsar_id = (SELECT id FROM dsar_requests WHERE identifier = 'TEST-MANUAL-001')
ORDER BY timestamp;
```

Expected events:
- REQUEST_RECEIVED
- RISK_ASSESSMENT_COMPLETED
- MANUAL_REVIEW_QUEUED

**Pass Criteria:**
- ✅ Request queued for manual review
- ✅ Appears in dashboard
- ✅ Can approve/deny
- ✅ Audit events logged correctly

---

## Test 4: Input Validation

**Objective:** Verify input validation catches errors

**Test 4.1: Missing Email**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "identifier": "TEST-VAL-001"
  }'
```

Expected: HTTP 400 with validation error

**Test 4.2: Invalid Email**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "not-an-email",
    "name": "Test User",
    "identifier": "TEST-VAL-002"
  }'
```

Expected: HTTP 400 with email format error

**Test 4.3: Missing Name**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "identifier": "TEST-VAL-003"
  }'
```

Expected: HTTP 400 with missing name error

**Test 4.4: Missing Identifier**
```bash
curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User"
  }'
```

Expected: HTTP 400 with missing identifier error

**Pass Criteria:**
- ✅ All invalid inputs rejected
- ✅ Clear error messages
- ✅ No database entries created
- ✅ HTTP 400 responses

---

## Test 5: Rate Limiting

**Objective:** Verify rate limiting at 100 req/min

**Steps:**

1. **Send 100 valid requests rapidly**
```bash
for i in {1..100}; do
  curl -X POST https://your-webhook-url/webhook/dsar-intake-test \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"test$i@example.com\", \"name\": \"Test $i\", \"identifier\": \"RATELIMIT-$i\"}" &
done
```

2. **Send 101st request**
   Should get HTTP 429 (Too Many Requests)

3. **Wait 1 minute, resend**
   Should get HTTP 200 (window reset)

**Pass Criteria:**
- ✅ First 100 requests: 200 OK
- ✅ Request 101+: 429 Too Many Requests
- ✅ After 1 minute: Can send again

---

## Test 6: Encryption & Decryption

**Objective:** Verify AES-256 encryption works correctly

**Steps:**

1. **Check encrypted password stored**
```sql
SELECT password_hash FROM encryption_vault 
WHERE dsar_id = (SELECT id FROM dsar_requests WHERE identifier = 'TEST-AUTO-001');
```

2. **Verify 16-char password sent in email**
   - Check inbox for "Decryption Password" email
   - Password should be 16 characters
   - Mix of upper, lower, numbers, symbols

3. **Test PDF Decryption**
   - Download encrypted PDF
   - Open in any PDF reader
   - Paste password
   - Verify PDF opens and shows data

4. **Verify Password Expiry**
   - Wait 24 hours (or check database)
   - Password should be marked expired
   - Should not work for decryption

**Pass Criteria:**
- ✅ Password generated (16 chars)
- ✅ PDF encrypted
- ✅ Password decrypts PDF
- ✅ Password expires after 24 hours

---

## Test 7: Security & Audit Logging

**Objective:** Verify security measures and audit trail

**Check Rate Limit Logging**
```sql
SELECT ip_address, COUNT(*) as request_count 
FROM audit_log 
WHERE action = 'REQUEST_RECEIVED'
GROUP BY ip_address
ORDER BY request_count DESC;
```

**Check Credential Masking**
```sql
SELECT action_details FROM audit_log 
WHERE action = 'REQUEST_RECEIVED' LIMIT 1;
```

Expected: Emails masked as `test***@***`

**Check No Passwords in Logs**
```sql
SELECT * FROM audit_log 
WHERE action_details::text ILIKE '%[A-Z0-9]{16}%';
```

Expected: No results (passwords not in audit logs)

**Check Audit Trail Integrity**
```sql
SELECT COUNT(*) FROM audit_log WHERE dsar_id IS NULL;
```

Expected: 0 (all audit entries linked to DSAR)

**Pass Criteria:**
- ✅ Rate limits enforced
- ✅ Emails masked in audit
- ✅ Passwords not logged
- ✅ Audit trail complete

---

## Test 8: Error Handling

**Objective:** Verify graceful error handling

**Test 8.1: Database Connection Error**
- Temporarily disable Supabase
- Send DSAR request
- Should get HTTP 500 with reference ID
- Error logged to audit_log

**Test 8.2: Email Delivery Failure**
- Disable SMTP credentials
- Send DSAR request
- Should log error
- Admin notified

**Test 8.3: AI Assessment Failure**
- Disable OpenAI API key
- Send DSAR request
- Should fallback or retry
- Request doesn't fail

**Pass Criteria:**
- ✅ All errors handled gracefully
- ✅ No unhandled exceptions
- ✅ User gets reference ID
- ✅ Admin notified
- ✅ System continues running

---

## Test 9: Dashboard Functionality

**Objective:** Verify approval dashboard works

**Steps:**

1. **Submit HIGH RISK request** (see Test 3)

2. **Access Dashboard**
   - Navigate to: https://your-railway-app.up.railway.app/
   - Should show approval queue
   - Should list pending requests

3. **Test Approve Button**
   - Click "Approve"
   - Should trigger password generation
   - Should send emails
   - Should update status

4. **Test Deny Button**
   - Submit another HIGH RISK request
   - Click "Deny"
   - Should update status to "denied"
   - Should send denial notification

5. **Check Real-time Updates**
   - Dashboard should refresh every 5 seconds
   - New requests should appear
   - Status should update in real-time

**Pass Criteria:**
- ✅ Dashboard accessible
- ✅ Shows pending requests
- ✅ Approve/deny buttons work
- ✅ Real-time updates working

---

## Test 10: Data Retention & Cleanup

**Objective:** Verify automatic data deletion

**Steps:**

1. **Submit DSAR & complete delivery**

2. **Check initial data**
```sql
SELECT COUNT(*) FROM dsar_requests WHERE status = 'delivered';
```

3. **Simulate 91 days passing** (in test DB)
```sql
UPDATE dsar_requests SET received_at = NOW() - INTERVAL '91 days' 
WHERE identifier = 'TEST-AUTO-001';
```

4. **Run retention policy**
```sql
DELETE FROM dsar_requests 
WHERE received_at < NOW() - INTERVAL '90 days' 
  AND status IN ('delivered', 'denied');
```

5. **Verify deletion**
```sql
SELECT COUNT(*) FROM dsar_requests WHERE identifier = 'TEST-AUTO-001';
```

Expected: 0 (record deleted)

6. **Verify cascade delete**
```sql
SELECT COUNT(*) FROM audit_log WHERE dsar_id = '...';
```

Expected: 0 (all related records deleted)

**Pass Criteria:**
- ✅ Old DSARs deleted after 90 days
- ✅ Audit logs deleted after 180 days
- ✅ Cascade deletes work
- ✅ No orphaned records

---

## Automated Testing (CI/CD)

### GitHub Actions Workflow

```yaml
name: Integration Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test webhook connectivity
        run: |
          curl -f https://your-webhook-url/health || exit 1
      - name: Test validation
        run: |
          python scripts/test_validation.py
      - name: Test encryption
        run: |
          python scripts/test_encryption.py
      - name: Integration test
        run: |
          python scripts/test_integration.py
```

---

## Performance Testing

### Load Test (100 concurrent requests)

```bash
# Using Apache Bench
ab -n 100 -c 10 -p request.json \
  -T application/json \
  https://your-webhook-url/webhook/dsar-intake-test
```

Expected:
- Response time < 500ms
- 0 errors
- All requests succeed

### Stress Test (1000+ requests over 1 minute)

```bash
# Watch for rate limiting
for i in {1..1000}; do
  curl -X POST ... &
  if [ $((i % 100)) -eq 0 ]; then
    echo "Sent $i requests"
    sleep 1
  fi
done
```

---

## Test Data Cleanup

After testing, clean up test data:

```sql
-- Delete test DSARs
DELETE FROM dsar_requests WHERE identifier LIKE 'TEST-%';

-- Verify cleanup
SELECT COUNT(*) FROM dsar_requests WHERE identifier LIKE 'TEST-%';
-- Should return 0
```

---

## Test Checklist

```
BEFORE DEPLOYMENT:
☐ Test 1: Webhook connectivity
☐ Test 2: End-to-end auto-approve flow
☐ Test 3: Manual review workflow
☐ Test 4: Input validation
☐ Test 5: Rate limiting
☐ Test 6: Encryption & decryption
☐ Test 7: Audit logging
☐ Test 8: Error handling
☐ Test 9: Dashboard functionality
☐ Test 10: Data retention

WEEKLY:
☐ Run full test suite
☐ Check error logs
☐ Verify audit trail
☐ Test backup recovery

MONTHLY:
☐ Load testing
☐ Security audit
☐ Compliance verification
```

---

**All tests passing = Ready for production! 🚀**
