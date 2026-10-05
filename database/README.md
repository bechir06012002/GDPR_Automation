# Database Setup

## Files in this directory

- **schema.sql** - Main database schema and tables. Run this first!
- **retention_policies.sql** - Data retention/deletion policies. Run after schema.sql

## Quick Start

1. Go to Supabase Dashboard
2. Click **SQL Editor** → **New Query**
3. Copy and paste contents of `schema.sql`
4. Click **Run**
5. Repeat for `retention_policies.sql`

## Verification

After running schema.sql, verify all tables created:

```sql
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

Should show:
- approval_queue
- audit_log
- credentials_vault
- dsar_deliveries
- dsar_requests
- extracted_data
- processed_data
- systems_inventory

## Tables Summary

| Table | Purpose | Retention |
|-------|---------|-----------|
| dsar_requests | Main DSAR records | 90 days |
| audit_log | Complete event trail | 180 days |
| approval_queue | Manual review queue | With DSAR |
| encryption_vault | Secure passwords | 24 hours |
| dsar_deliveries | Email tracking | With DSAR |
| extracted_data | Raw extractions | 90 days |
| processed_data | Processed data | 90 days |
| credentials_vault | Integration secrets | Permanent |
| systems_inventory | Available systems | Permanent |

## Cleanup

To manually delete old data:

```sql
-- Delete DSARs older than 90 days (completed only)
DELETE FROM dsar_requests 
WHERE received_at < NOW() - INTERVAL '90 days'
  AND status IN ('delivered', 'denied');

-- Delete old audit logs (180+ days)
DELETE FROM audit_log 
WHERE created_at < NOW() - INTERVAL '180 days';

-- Delete expired passwords
DELETE FROM encryption_vault 
WHERE expires_at < NOW() AND is_used = TRUE;
```

See `retention_policies.sql` for automated cleanup.

## For Production

Enable Supabase backups:
1. Go to Supabase Dashboard
2. Click **Settings** → **Backups**
3. Enable daily backups
4. Set retention to 30 days

For automatic deletion in production, create n8n scheduled workflow that runs these queries daily at 2 AM.
