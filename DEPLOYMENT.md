# 🚀 Production Deployment Guide

Complete step-by-step guide to deploy the GDPR DSAR Automation Platform to production.

## Prerequisites

- ✅ n8n account (https://n8n.io)
- ✅ Supabase account (https://supabase.com)
- ✅ Railway account (https://railway.app)
- ✅ OpenAI API key (https://openai.com)
- ✅ Gmail SMTP credentials
- ✅ GitHub account

## Phase 1: Database Setup (Supabase)

### Step 1.1: Create Supabase Project

1. Go to https://supabase.com
2. Click "New Project"
3. Enter project details:
   - Name: `gdpr-dsar-automation`
   - Region: Closest to you
   - Database password: Strong password (save this!)
4. Wait for project to initialize (5-10 min)

### Step 1.2: Run Database Schema

1. Go to Supabase Dashboard
2. Click **SQL Editor** → **New Query**
3. Copy and paste: `database/schema.sql`
4. Click **Run** ✅
5. Repeat for: `database/retention_policies.sql`

### Step 1.3: Verify Tables Created

Check that these tables exist:
- `dsar_requests`
- `audit_log`
- `approval_queue`
- `encryption_vault`
- `dsar_deliveries`
- `extracted_data`
- `processed_data`
- `credentials_vault`
- `systems_inventory`

### Step 1.4: Get Credentials

In Supabase Dashboard:
1. Click **Settings** → **API**
2. Copy:
   - Project URL
   - Anon Key (public)
   - Service Role Key (keep secret!)

## Phase 2: n8n Setup

### Step 2.1: Import Workflow

1. Go to your n8n instance
2. Click **Import** → **From file**
3. Select: `n8n/workflow_export.json`
4. Click **Import** ✅

### Step 2.2: Configure Credentials

Configure 3 credentials:

#### Supabase
1. Find any Supabase node
2. Click **Credentials** → **Supabase account**
3. Fill:
   - Host: Your Supabase URL
   - API Key: Your Anon Key
4. Test & Save ✅

#### SMTP
1. Find any SMTP node
2. Click **Credentials** → **SMTP account**
3. Fill:
   - Host: `smtp.gmail.com`
   - Port: `587`
   - Email: Your Gmail address
   - Password: Your app password (not regular password)
4. Test & Save ✅

#### OpenAI
1. Find **Assess Risk Level** node
2. Click **Credentials** → **OpenAI account**
3. Fill:
   - API Key: Your OpenAI API key
4. Test & Save ✅

### Step 2.3: Update Webhook URLs

If deploying to different n8n instance:
1. Update webhook paths in workflow
2. Get your production webhook URL
3. Update in any references

### Step 2.4: Publish Workflow

1. Click **Publish** (top right)
2. Version name: `Production v1.0 - Phase 12 Complete`
3. Description: Your deployment notes
4. Click **Publish** ✅

## Phase 3: Backend Deployment (Railway)

### Step 3.1: Connect GitHub

1. Go to Railway (https://railway.app)
2. Login with GitHub
3. Create new project
4. Select: **Deploy from GitHub repo**
5. Select: `GDPR_DSAR_Automation`

### Step 3.2: Configure Environment

Railway will auto-detect `Dockerfile`. Add environment variables:

```
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_anon_key
DATABASE_URL=your_postgres_connection_string
OPENAI_API_KEY=your_openai_key
```

### Step 3.3: Deploy

1. Railway auto-deploys on push
2. Wait for deployment to complete
3. Get your Railway URL from dashboard
4. Test health endpoint:
   ```
   curl https://your-railway-app.up.railway.app/health
   ```

Should return:
```json
{"status":"healthy"}
```

### Step 3.4: Update Dashboard

1. Copy `frontend/static/index.html`
2. Update Supabase credentials in HTML
3. Push to GitHub
4. Railway redeploys automatically ✅

## Phase 4: Testing

### Test 1: Complete DSAR Flow

```powershell
$body = @{
    email = "test@example.com"
    name = "Production Test"
    identifier = "prod_test_001"
    request_type = "full_access"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://your-webhook-url" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

Expected results:
- ✅ HTTP 200 response
- ✅ 3 emails sent
- ✅ All n8n nodes green
- ✅ Data in Supabase
- ✅ Dashboard updates

### Test 2: High-Risk Scenario

Use different email/data pattern to trigger HIGH RISK

### Test 3: Error Handling

Test various error scenarios:
- Invalid email
- Missing fields
- System failures

## Phase 5: Monitoring Setup

### n8n Monitoring

1. Enable execution history
2. Set retention to 7 days
3. Monitor error rates
4. Check execution times

### Supabase Monitoring

1. Go to Supabase Dashboard
2. Click **Logs** → **API Logs**
3. Monitor for errors
4. Check query performance

### Railway Monitoring

1. Go to Railway Dashboard
2. Check **Deployments**
3. Monitor **Resource Usage**
4. Check **Logs** for errors

## Phase 6: Production Checklist

```
BEFORE GO-LIVE:
☐ Database: All tables created
☐ n8n: Workflow published & active
☐ Backend: Deployed to Railway
☐ Dashboard: Accessible & functional
☐ Credentials: All configured
☐ Testing: Complete end-to-end test passed
☐ Monitoring: Dashboards accessible
☐ Backups: Supabase backups enabled
☐ Security: Rate limiting active
☐ Encryption: AES-256 working

FIRST 24 HOURS:
☐ Monitor execution logs
☐ Check for any errors
☐ Verify email delivery
☐ Monitor system resources

ONGOING:
☐ Weekly: Review audit logs
☐ Monthly: Check data retention
☐ Daily: Monitor uptime
☐ As-needed: Review error logs
```

## Production URLs

After deployment:

| Service | URL |
|---------|-----|
| **n8n Workflow** | https://your-n8n-instance.com/workflow/ID |
| **Webhook** | https://your-webhook-url |
| **Dashboard** | https://your-railway-app.up.railway.app/ |
| **Health Check** | https://your-railway-app.up.railway.app/health |
| **Supabase** | https://supabase.com/dashboard |

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for:
- Connection errors
- Webhook failures
- Email delivery issues
- Dashboard problems
- Database errors

## Security Verification

Before production:

- ✅ Verify no secrets in logs
- ✅ Verify HTTPS everywhere
- ✅ Verify rate limiting active
- ✅ Verify credentials masked
- ✅ Verify redaction enabled
- ✅ Verify data retention configured

## Scaling

For high-volume (100+ requests/day):

1. Increase n8n worker count
2. Optimize database indexes
3. Configure caching
4. Monitor and adjust rate limits
5. Setup auto-scaling on Railway

## Support

For deployment issues:
1. Check logs (n8n, Railway, Supabase)
2. Review docs/TROUBLESHOOTING.md
3. Test individual components
4. Open GitHub issue

---

**Deployment Completed! 🎉**

Your GDPR DSAR Automation Platform is now LIVE and ready for production DSARs!
