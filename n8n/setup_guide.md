# n8n Workflow Setup Guide

## Prerequisites

- n8n account (cloud.n8n.io or self-hosted)
- Supabase project (with database initialized)
- Gmail account with app password
- OpenAI API key

## Step 1: Access Your n8n Instance

1. Go to https://cloud.n8n.io (or your self-hosted instance)
2. Login with your account
3. Click **Workflows** in sidebar

## Step 2: Import the Workflow

### Option A: From Workflow Export File

1. Click **Import** button (top right)
2. Select **Import from file**
3. Choose: `workflow_export.json` from this directory
4. Click **Import** ✅

### Option B: Manual Import (if file not available)

1. Click **New** → **Workflow**
2. Add nodes one at a time (refer to ARCHITECTURE.md)
3. Configure as per workflow design

## Step 3: Configure Credentials

The workflow requires 3 credentials. Configure each:

### Credential 1: Supabase

1. In workflow, click any **Supabase** node
2. Click **Credentials** → **Create New**
3. Name: `Supabase account`
4. Type: Select **Supabase**
5. Fill in:
   - **Host:** Your Supabase Project URL (from Settings > API)
   - **API Key:** Your Anon Key (public key)
6. Click **Test connection** ✅
7. Click **Create** 

### Credential 2: SMTP (Gmail)

1. Find **Send Email** (SMTP) node in workflow
2. Click **Credentials** → **Create New**
3. Name: `SMTP account`
4. Type: Select **SMTP**
5. Fill in:
   - **Host:** `smtp.gmail.com`
   - **Port:** `587`
   - **Username:** Your Gmail address (e.g., yourname@gmail.com)
   - **Password:** Your **App Password** (NOT your Gmail password!)
   
   **To generate Gmail App Password:**
   - Go to myaccount.google.com
   - Click **Security** (left sidebar)
   - Enable 2-Factor Authentication if not already enabled
   - Search for "App passwords"
   - Select: App = Mail, Device = Windows/Mac/Linux
   - Generate password → Copy it
   - Paste in n8n

6. Click **Test connection** ✅
7. Click **Create**

### Credential 3: OpenAI

1. Find **Assess Risk Level** (LLM) node in workflow
2. Click **Credentials** → **Create New**
3. Name: `OpenAI account`
4. Type: Select **OpenAI**
5. Fill in:
   - **API Key:** Your OpenAI API key (from platform.openai.com/api-keys)
6. Click **Test connection** ✅
7. Click **Create**

## Step 4: Configure Workflow Settings

1. Click **Settings** (top right)
2. Set:
   - **Execution Data:** Enable "Redact Sensitive Data"
   - **Save executions:** "All" (for debugging)
   - **Keep logs for:** "7 days"
3. Click **Save**

## Step 5: Test Workflow

### Test Mode (Before Publishing)

1. Click **Execute Workflow** button
2. Fill in test data when prompted:
   - Email: test@example.com
   - Name: Test User
   - Identifier: TEST-001
3. Watch execution flow
4. All nodes should show **green checkmark** ✓

### Expected Results:
- HTTP 200 response
- Data appears in Supabase
- 2 test emails sent (if SMTP configured)
- All nodes complete successfully

## Step 6: Verify Webhook Configuration

1. Click on **Webhook** node (first node)
2. Copy **Webhook URL** (test URL for development)
3. Note the path (typically: `/webhook/dsar-intake-test`)

## Step 7: Publish Workflow

When all tests pass:

1. Click **Publish** button (top right)
2. Enter version info:
   - Version name: `Production v1.0`
   - Description: `GDPR DSAR Automation - Phase 12 Complete`
3. Click **Publish** ✅

Now your workflow is **LIVE** in production!

## Step 8: Get Production Webhook URL

After publishing:

1. Click on **Webhook** node
2. Copy **Webhook URL** (production URL)
3. This is your live endpoint for DSAR requests
4. Should look like: `https://your-instance.n8n.cloud/webhook/dsar-intake-test`

## Testing Production Webhook

```bash
curl -X POST https://your-instance.n8n.cloud/webhook/dsar-intake-test \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your-email@example.com",
    "name": "Production Test",
    "identifier": "PROD-TEST-001"
  }'
```

Should receive:
- HTTP 200 response
- Email to your inbox
- Data in Supabase

## Monitoring

### View Execution Logs
1. Click workflow in list
2. Click **Executions** tab
3. See all run history
4. Click execution to see details

### Debug Node Execution
1. Click **Execute Workflow**
2. After execution, click on any node
3. View:
   - Input data
   - Output data
   - Errors (if any)

### Enable Detailed Logging
1. Settings → Toggle **Debug Node**
2. Run workflow
3. Console shows detailed logs

## Production Checklist

```
BEFORE GOING LIVE:
☐ All 3 credentials configured and tested
☐ Webhook test successful
☐ Email delivery working (received test emails)
☐ Data appearing in Supabase
☐ Audit logging enabled
☐ Redaction enabled in settings
☐ Retention policies configured
☐ Workflow published to production

AFTER GOING LIVE:
☐ Monitor execution logs daily
☐ Check for errors
☐ Verify email deliveries
☐ Test weekly with sample DSAR
```

## Troubleshooting

### Webhook Not Responding
- Check node is connected (blue line)
- Click "Test" on Webhook node
- Verify URL is correct
- Check n8n instance is running

### Credentials Not Working
- Test connection in credentials form
- Verify API keys are correct (copy-paste, not typed)
- Check for expiration dates
- Look at test error message

### Emails Not Sending
- Verify Gmail app password (not regular password)
- Check 2FA is enabled on Gmail
- Look at SMTP node error message
- Try sending test email manually

### Data Not in Database
- Verify Supabase credential is correct
- Check table exists: `SELECT * FROM dsar_requests LIMIT 1;`
- Look at Supabase node error message
- Verify API key has INSERT permission

## Next Steps

1. **Monitor Production:** Check workflow executions daily
2. **Setup Alerts:** Configure n8n alerts for errors
3. **Automate Cleanup:** Create scheduled workflow for data retention
4. **Integrate Systems:** Connect real Email, HubSpot, Zendesk APIs
5. **Custom Domain:** Setup custom webhook URL (optional)

## Support

- **n8n Docs:** https://docs.n8n.io
- **n8n Community:** https://community.n8n.io
- **This Project:** https://github.com/bechir06012002/GDPR_DSAR_Automation

---

**Workflow successfully setup and ready for production! 🚀**
