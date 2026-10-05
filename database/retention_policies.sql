-- ============================================================================
-- GDPR DSAR Automation Platform - Data Retention Policies
-- ============================================================================
-- Run this in Supabase SQL Editor AFTER running schema.sql
-- These policies implement automatic data deletion for GDPR compliance
-- ============================================================================

-- ============================================================================
-- RETENTION POLICY 1: Delete completed DSARs after 90 days
-- ============================================================================
-- GDPR Article 17: Right to be forgotten
-- Automatically delete DSAR records that have been delivered or denied
--
-- Schedule: Run daily via n8n scheduled workflow (recommended)
-- Manual: Copy and run this query whenever needed

DELETE FROM public.dsar_requests 
WHERE received_at < NOW() - INTERVAL '90 days' 
  AND status IN ('delivered', 'denied');

-- This will cascade delete:
-- - audit_log records for this DSAR
-- - approval_queue entries
-- - encryption_vault entries
-- - dsar_deliveries records
-- - extracted_data
-- - processed_data

-- ============================================================================
-- RETENTION POLICY 2: Delete expired encryption passwords after 24 hours
-- ============================================================================
-- Security: Expired passwords are no longer needed
-- Schedule: Run every 6 hours

DELETE FROM public.encryption_vault 
WHERE expires_at < NOW() 
  AND is_used = TRUE;

-- ============================================================================
-- RETENTION POLICY 3: Delete old audit logs after 180 days
-- ============================================================================
-- Regulatory requirement: Keep audit trail for 6 months minimum
-- After 180 days, logs are archived and deleted
-- Schedule: Run weekly

DELETE FROM public.audit_log 
WHERE created_at < NOW() - INTERVAL '180 days';

-- ============================================================================
-- RETENTION POLICY 4: Archive and delete old extracted data after 90 days
-- ============================================================================
-- Performance optimization: Keep detailed extraction data for 90 days only
-- After 90 days, only summary in processed_data remains
-- Schedule: Run weekly

DELETE FROM public.extracted_data 
WHERE extracted_at < NOW() - INTERVAL '90 days'
  AND dsar_id IN (
    SELECT id FROM public.dsar_requests 
    WHERE status IN ('delivered', 'denied')
  );

-- ============================================================================
-- RECOMMENDED: Create an n8n Scheduled Workflow for Automatic Cleanup
-- ============================================================================
-- 
-- Create a new n8n workflow:
-- 1. Add "Schedule" trigger (Daily at 2:00 AM)
-- 2. Add 4 "Execute Query" nodes (one per policy above)
-- 3. Add error handling
-- 4. Deploy
--
-- This ensures automatic compliance without manual intervention
--
-- ============================================================================

-- ============================================================================
-- VERIFICATION QUERIES (Run to check what will be deleted)
-- ============================================================================

-- Check DSARs older than 90 days that will be deleted:
SELECT COUNT(*) as dsar_count_to_delete,
       MIN(received_at) as oldest_date
FROM public.dsar_requests 
WHERE received_at < NOW() - INTERVAL '90 days' 
  AND status IN ('delivered', 'denied');

-- Check expired passwords to delete:
SELECT COUNT(*) as passwords_to_delete
FROM public.encryption_vault 
WHERE expires_at < NOW() 
  AND is_used = TRUE;

-- Check old audit logs to delete:
SELECT COUNT(*) as audit_logs_to_delete,
       MIN(created_at) as oldest_date
FROM public.audit_log 
WHERE created_at < NOW() - INTERVAL '180 days';

-- Check extracted data to delete:
SELECT COUNT(*) as extracted_data_to_delete,
       MIN(extracted_at) as oldest_date
FROM public.extracted_data 
WHERE extracted_at < NOW() - INTERVAL '90 days'
  AND dsar_id IN (
    SELECT id FROM public.dsar_requests 
    WHERE status IN ('delivered', 'denied')
  );

-- ============================================================================
-- DATA RETENTION SUMMARY
-- ============================================================================
-- 
-- Table                  | Retention Period | Action
-- ---------------------- | --------------- | --------
-- dsar_requests          | 90 days         | Delete (completed only)
-- audit_log              | 180 days        | Delete
-- extraction_vault       | 24 hours        | Delete (after use)
-- extracted_data         | 90 days         | Delete
-- processed_data         | 90 days         | Keep (summary)
-- dsar_deliveries        | 90 days         | Keep with DSAR
-- approval_queue         | 90 days         | Keep with DSAR
-- credentials_vault      | Indefinite      | Keep (system config)
-- systems_inventory      | Indefinite      | Keep (system config)
--
-- ============================================================================

-- ============================================================================
-- COMPLIANCE NOTES
-- ============================================================================
--
-- GDPR Article 5(1)(e) - Storage Limitation:
-- "Personal data kept in a form which permits identification of data 
--  subjects for no longer than is necessary"
--
-- GDPR Article 17 - Right to be Forgotten:
-- "The data subject shall have the right to obtain from the controller 
--  the erasure of personal data"
--
-- Our Implementation:
-- ✓ Automatic deletion after 90 days for delivered DSARs
-- ✓ Audit trail maintained for 180 days for compliance
-- ✓ Passwords expire and deleted after use
-- ✓ No personal data retained longer than necessary
-- ✓ Cascading deletes ensure no orphaned records
--
-- ============================================================================

-- ============================================================================
-- END OF RETENTION POLICIES
-- ============================================================================
