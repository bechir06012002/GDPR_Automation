# 🔧 Troubleshooting Guide

Common issues and their solutions.

## Webhook Issues

### Issue: Webhook Not Receiving Requests

**Symptoms:**
- curl command hangs or times out
- No execution in n8n log
- 404 error

**Solutions:**

1. **Verify webhook URL is correct**
   - In n8n, find Webhook node
   - Copy exact URL
   - Check for typos or trailing slashes

2. **Verify n8n is running**
   - Go to n8n dashboard
   - Should show "Active" workflows
   - Check server status

3. **Check firewall/network**
   ```bash
   # Test connectivity
   curl -v https://your-webhook-url
   # Should get response (200 or 405)
   ```

4. **Verify webhook is active**
   - Open n8n workflow
   - Webhook node should be connected
   - Check node settings

5. **Check for webhook redirect**
   - Some setups redirect webhooks
   - Verify endpoint is not 301/302 redirecting

**If still failing:**
- Check n8n server logs
- Contact n8n support if self-hosted
- Try test webhook URL if available

---

## Email Delivery Issues

### Issue: Emails Not Received

**Symptoms:**
- n8n shows email sent ✓
- No emails in inbox
- Found in spam folder

**Solutions:**

1. **Check email credentials**
   - Verify Gmail app password (not regular password)
   - Test with: `telnet smtp.gmail.com 587`
   - Check SMTP node in n8n

2. **Enable IMAP in Gmail**
   - Go to Gmail settings
   - Enable "Allow less secure apps"
   - Enable 2-factor authentication
   - Generate app-specific password

3. **Check email settings**
   - n8n SMTP credential > Test connection
   - Should show "Test email sent successfully"

4. **Look in spam/junk folder**
   - Gmail may mark automated emails as spam
   - Add privacy@example.com to contacts
   - Whitelist sender domain

5. **Check email size**
   - PDF + metadata shouldn't exceed limit
   - Gmail limit: 25MB
   - Reduce PDF size if needed

6. **Verify email addresses**
   ```sql
   SELECT email_to, status FROM dsar_deliveries 
   WHERE dsar_id = 'your-dsar-id';
   ```
   - Check if correct email was used

**If still not received:**
- Check n8n execution logs (click node to see sent data)
- Verify email address is correct
- Try sending test email manually
- Check email provider's delivery status

---

## Database Connection Issues

### Issue: "Cannot Connect to Supabase"

**Symptoms:**
- Workflow fails at Supabase node
- Error: "Connection refused"
- Data not saving to database

**Solutions:**

1. **Verify Supabase credentials**
   - Get URL from: Supabase Dashboard > Settings > API
   - Get key from: Same page
   - Verify no extra spaces

2. **Test connection manually**
   ```bash
   curl -X POST https://your-supabase-url/rest/v1/dsar_requests \
     -H "apikey: your-anon-key" \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com"}'
   ```
   - Should get response (error or success)

3. **Check if database exists**
   - Go to Supabase Dashboard
   - Click SQL Editor
   - Run: `SELECT 1;`
   - Should see "1"

4. **Verify tables created**
   - Run: `SELECT * FROM dsar_requests LIMIT 1;`
   - If error: Tables not created yet
   - Run database/schema.sql

5. **Check Supabase status**
   - Go to https://status.supabase.com
   - Verify no outages reported
   - Try connecting directly from Dashboard

6. **Verify RLS is disabled**
   - Check each table has RLS disabled
   - Tables > [table name] > Auth
   - Should see "Disabled" for Row Level Security

**If still failing:**
- Check Supabase error logs (in Dashboard)
- Verify API key is correct (copy-paste, not type)
- Try different API key (service key vs anon key)

---

## Encryption Issues

### Issue: "Cannot Decrypt PDF"

**Symptoms:**
- PDF opens but shows garbage
- "Wrong password" error
- PDF corrupted after encryption

**Solutions:**

1. **Verify correct password**
   - Check email for password
   - Ensure you copied exactly (16 chars)
   - Passwords are case-sensitive

2. **Check encryption status**
   ```sql
   SELECT is_used, expires_at FROM encryption_vault 
   WHERE dsar_id = 'your-dsar-id';
   ```
   - If `is_used = true` and `expires_at < now()`: Expired
   - Expired passwords don't work

3. **Verify PDF integrity**
   - Check PDF file size
   - File should be readable (not corrupted)
   - Try opening with different PDF reader

4. **Check encryption algorithm**
   ```sql
   SELECT encryption_algorithm FROM encryption_vault 
   WHERE dsar_id = 'your-dsar-id';
   ```
   - Should be: "AES-256-CBC"

5. **Regenerate password**
   - Contact compliance team
   - Approve request again
   - Sends new password

**If still failing:**
- Check n8n encryption node logs
- Verify AES-256 is supported
- Try online PDF decryption tool (for testing only)

---

## AI Risk Assessment Issues

### Issue: "OpenAI API Error"

**Symptoms:**
- Workflow fails at "Assess Risk Level"
- Error mentions OpenAI
- Auto-approval stuck

**Solutions:**

1. **Verify OpenAI API key**
   - Get from: https://platform.openai.com/api-keys
   - Check key hasn't expired
   - Verify correct key in n8n credential

2. **Check API quota**
   - Go to OpenAI Dashboard
   - Check remaining credits
   - Add payment method if needed

3. **Test OpenAI connection**
   - In n8n, find "Assess Risk Level" node
   - Click "Execute" on node
   - Check node logs for error details

4. **Verify model availability**
   - Check if `gpt-3.5-turbo` is still available
   - Or switch to `gpt-4` if available
   - Verify model name in node configuration

5. **Check rate limits**
   - OpenAI has rate limits per account type
   - Free accounts: 3 requests/minute
   - Paid accounts: Much higher
   - Wait 1 minute and retry

6. **Fallback to manual review**
   - If AI assessment fails, mark as HIGH RISK
   - Route to manual approval
   - Compliance team can review

**If still failing:**
- Check OpenAI status page
- Contact OpenAI support
- Implement manual review fallback

---

## Approval Dashboard Issues

### Issue: "Dashboard Not Loading"

**Symptoms:**
- Blank page
- 404 error
- "Cannot connect to database"

**Solutions:**

1. **Check Railway deployment**
   - Go to Railway Dashboard
   - Check deployment status
   - Should show "Deployed" (green)

2. **Verify dashboard URL**
   - Should be: `https://your-railway-app.up.railway.app/`
   - Check for typos

3. **Check Supabase connection in HTML**
   - Open frontend/static/index.html
   - Verify Supabase URL is correct
   - Verify API key is correct

4. **Test backend health**
   ```bash
   curl https://your-railway-app.up.railway.app/health
   ```
   - Should return: `{"status":"healthy"}`

5. **Check browser console**
   - Open DevTools (F12)
   - Check Console tab for errors
   - Common: CORS errors, connection errors

6. **Verify approval queue data**
   ```sql
   SELECT COUNT(*) FROM approval_queue WHERE status = 'pending';
   ```
   - If 0 results: Nothing to display

**If still failing:**
- Check Railway logs
- Restart Railway deployment
- Clear browser cache (Ctrl+Shift+Del)
- Try different browser

---

## Rate Limiting Issues

### Issue: "Rate Limit Exceeded" Too Early

**Symptoms:**
- Getting 429 errors after ~50 requests
- Not reaching 100/minute limit
- Other requests timing out

**Solutions:**

1. **Check rate limit configuration**
   - Verify limit is 100 req/minute
   - Check in "Rate Limit Check" node
   - Increase if needed (edit global.rateLimitStore)

2. **Verify IP is being detected**
   - Check logs for IP addresses
   - Different clients = different IPs
   - Load balancer might hide real IP

3. **Check for rate limit reset**
   - Should reset every 60 seconds (sliding window)
   - If not resetting: Check code logic
   - Verify timeout functions working

4. **Monitor actual request count**
   ```
   In n8n logs:
   - Look for rate limit check node
   - Should log request count
   - Verify counter is accurate
   ```

5. **Increase limit if needed**
   - For production with high volume
   - Edit "Rate Limit Check" node
   - Change 100 to higher number
   - Affects system load

---

## Data Loss / Missing Records

### Issue: "DSAR Record Not Found"

**Symptoms:**
- Webhook accepted (HTTP 200)
- n8n shows execution
- Data not in database

**Solutions:**

1. **Check if data is in database**
   ```sql
   SELECT * FROM dsar_requests WHERE email = 'your-email';
   ```
   - If no results: Data not saved

2. **Check n8n execution logs**
   - Find workflow execution
   - Click on "Store DSAR Request" node
   - Should show INSERT statement with results

3. **Verify table has correct schema**
   - Run: `\d dsar_requests` (in SQL)
   - Should show columns: id, email, name, identifier, etc.
   - If missing: Run schema.sql again

4. **Check for duplicate identifier**
   ```sql
   SELECT COUNT(*) FROM dsar_requests WHERE identifier = 'your-id';
   ```
   - identifier is UNIQUE
   - Cannot insert duplicate
   - Would fail silently in n8n

5. **Check database transaction**
   - Large data may cause transaction to roll back
   - Check table size: `SELECT pg_size_pretty(pg_total_relation_size('dsar_requests'));`

6. **Verify RLS isn't blocking inserts**
   - Check RLS status: `SELECT * FROM pg_policies WHERE tablename = 'dsar_requests';`
   - Should see "RLS disabled" for public table

**If still missing:**
- Check Supabase Activity > Queries for errors
- Review n8n execution logs in detail
- Verify table permissions

---

## Performance Issues

### Issue: "DSAR Processing is Slow"

**Symptoms:**
- Takes 20+ minutes instead of 5
- n8n workflows timing out
- High response times

**Solutions:**

1. **Check n8n performance**
   - Click n8n settings
   - Check CPU/memory usage
   - Increase worker count if needed

2. **Monitor Supabase queries**
   - Supabase Dashboard > SQL Editor
   - Run: `SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC;`
   - Look for slow queries

3. **Add database indexes**
   - Already done in schema.sql
   - If missing: Run schema.sql again
   - Check: `SELECT * FROM pg_indexes WHERE tablename = 'dsar_requests';`

4. **Check external API calls**
   - Email: Should take <2 seconds
   - OpenAI: Can take 5-30 seconds (normal)
   - CRM APIs: Can be slow if many records

5. **Verify network latency**
   - Test: `ping your-supabase-url`
   - Should be <100ms
   - High latency = use closer database region

6. **Check for workflow inefficiencies**
   - Unnecessary loops
   - Repeated queries
   - Large data transfers

**Optimizations:**
- Add caching
- Batch operations
- Use async operations

---

## Security Issues

### Issue: "Sensitive Data in Logs"

**Symptoms:**
- Passwords showing in n8n logs
- Email addresses not masked
- Credentials visible in audit trail

**Solutions:**

1. **Enable redaction**
   - n8n Settings > Execution Data
   - Enable "Redact Sensitive Data"
   - Restart n8n

2. **Check audit logs for sensitive data**
   ```sql
   SELECT * FROM audit_log 
   WHERE action_details::text ILIKE '%password%';
   ```
   - Should show masked data or no data

3. **Verify node output masking**
   - Each node should mask output
   - Check "Sanitize" nodes are working
   - Review node output in execution logs

4. **Secure environment variables**
   - Don't put secrets in n8n parameters
   - Use encrypted environment variables
   - Use credential system instead

---

## Support Resources

### Check These First
1. Review docs/TESTING.md for known issues
2. Check n8n execution logs
3. Review Supabase SQL Editor
4. Check Railway logs

### Contact Information
- **Email:** privacy@example.com
- **GitHub Issues:** https://github.com/bechir06012002/GDPR_DSAR_Automation/issues
- **n8n Support:** https://support.n8n.io

### Information to Include in Support Ticket
- Error message (exact text)
- Timestamp of error
- DSAR identifier (if applicable)
- Steps to reproduce
- Screenshot/log excerpt
- What you've already tried

---

**Still stuck? Create GitHub issue with all details above! 🆘**
