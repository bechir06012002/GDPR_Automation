# 🔐 GDPR DSAR Automation Platform

**Fully automated GDPR Data Subject Access Request (DSAR) processing system**

![Status](https://img.shields.io/badge/Status-Production%20Ready-green)
![License](https://img.shields.io/badge/License-MIT-blue)
![Phase](https://img.shields.io/badge/Phase-12%2F12%20Complete-brightgreen)

## 📋 Overview

Transform manual GDPR DSAR processing from **4-8 hours to 5 minutes per request**.

This enterprise-grade automation platform:
- ✅ Automatically extracts data from multiple systems (Email, CRM, Support)
- ✅ Uses AI to assess risk and auto-approve low-risk requests
- ✅ Routes high-risk requests for manual compliance review
- ✅ Encrypts & securely delivers data via separate emails
- ✅ Maintains complete audit trail for compliance
- ✅ Ensures GDPR Article 15 compliance

## 🚀 Key Features

### Automation
- 🔄 Webhook-based intake
- 🤖 AI risk assessment (OpenAI)
- ⚡ Auto-approval for low-risk requests
- 📋 Manual review dashboard for high-risk
- 🔐 AES-256 encryption
- 📧 Secure dual-email delivery

### Compliance & Security
- 📊 Complete audit logging (5-7 events per request)
- 📅 Automatic data retention (90/180/24 days)
- 🛡️ Rate limiting (100 req/min)
- 🔒 HTTPS enforcement
- 🎯 Request validation & sanitization
- 🔑 Credential masking & secure storage

### Monitoring & Tracking
- 📈 Real-time approval dashboard
- 📦 Delivery tracking per request
- 📝 Comprehensive audit logs
- 📊 System health monitoring

## 📊 Architecture

```
┌──────────────────┐
│  DSAR Request    │ (Webhook POST)
└────────┬─────────┘
         ▼
┌──────────────────────────────────┐
│  Security Checks                 │
│ • Rate Limiting                  │
│ • HTTPS Enforcement              │
│ • Request Validation             │
└────────┬─────────────────────────┘
         ▼
┌──────────────────────────────────┐
│  Data Extraction (Parallel)      │
│ • Email/IMAP                     │
│ • HubSpot CRM                    │
│ • Zendesk Support                │
└────────┬─────────────────────────┘
         ▼
┌──────────────────────────────────┐
│  Process Data                    │
│ • Deduplicate                    │
│ • Categorize                     │
│ • PII Summary                    │
└────────┬─────────────────────────┘
         ▼
┌──────────────────────────────────┐
│  AI Risk Assessment              │
│ (OpenAI GPT-3.5)                 │
└────────┬──────────┬──────────────┘
         ▼          ▼
    LOW RISK    HIGH RISK
         ▼          ▼
    ┌────┐      ┌──────────┐
    │Auto│      │Manual    │
    │Appr│      │Review    │
    └────┘      │Dashboard │
                └──────────┘
         ▼
┌──────────────────────────────────┐
│  Generate & Encrypt PDF          │
│ • AES-256 Encryption             │
│ • Secure Password Generation     │
└────────┬─────────────────────────┘
         ▼
┌──────────────────────────────────┐
│  Secure Delivery                 │
│ • Send Encrypted PDF             │
│ • Wait 5 Minutes                 │
│ • Send Password Separately       │
└────────┬─────────────────────────┘
         ▼
┌──────────────────────────────────┐
│  Audit & Logging                 │
│ • Request received               │
│ • Risk assessment                │
│ • Approval decision              │
│ • Delivery confirmation          │
└──────────────────────────────────┘
```

## 💻 Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Orchestration** | n8n | Workflow automation |
| **Backend** | FastAPI (Python) | Data processing |
| **Database** | Supabase (PostgreSQL) | Data storage & audit |
| **Cloud** | Railway | Production deployment |
| **AI/ML** | OpenAI GPT-3.5 | Risk assessment |
| **Security** | AES-256, HTTPS, Rate Limiting | Data protection |

## 📦 What's Included

```
├── n8n/
│   ├── workflow_export.json      # Complete n8n workflow (54 nodes)
│   └── setup_guide.md            # How to import workflow
│
├── backend/
│   ├── dsar_processor.py         # FastAPI application
│   ├── requirements.txt          # Python dependencies
│   ├── Dockerfile                # Container setup
│   └── README.md                 # Backend documentation
│
├── database/
│   ├── schema.sql                # Table structure & RLS
│   ├── retention_policies.sql    # Auto-deletion policies
│   └── README.md                 # Database guide
│
├── frontend/
│   └── static/index.html         # Approval dashboard
│
├── docs/
│   ├── GDPR_COMPLIANCE.md        # Compliance details
│   ├── SECURITY.md               # Security architecture
│   ├── API_DOCUMENTATION.md      # API reference
│   ├── TESTING.md                # Testing guide
│   └── TROUBLESHOOTING.md        # Common issues
│
├── scripts/
│   └── setup_supabase.sh         # Database setup script
│
├── DEPLOYMENT.md                 # Production setup
├── ARCHITECTURE.md               # System design
└── LICENSE                       # MIT License
```

## 🚀 Quick Start

### Prerequisites
- n8n account (self-hosted or cloud)
- Supabase account
- Railway account
- OpenAI API key
- Gmail SMTP credentials

### 1. Clone Repository
```bash
git clone https://github.com/bechir06012002/GDPR_DSAR_Automation.git
cd GDPR_DSAR_Automation
```

### 2. Setup Database
```bash
# Use Supabase SQL Editor to run:
cat database/schema.sql
cat database/retention_policies.sql
```

### 3. Import n8n Workflow
See `n8n/setup_guide.md`

### 4. Deploy Backend
See `DEPLOYMENT.md`

### 5. Test Production
```bash
# Run test DSAR request
$body = @{
    email = "test@example.com"
    name = "Test User"
    identifier = "test_001"
    request_type = "full_access"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://your-webhook-url/webhook/dsar-intake-test" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

## 📈 Performance Metrics

| Metric | Value |
|--------|-------|
| **DSAR Processing Time** | 5-10 minutes |
| **Auto-Approval Rate** | 60-80% (configurable) |
| **Audit Events** | 5-7 per request |
| **Data Retention** | 90 days (DSAR), 180 days (audit) |
| **Uptime** | 99.9% (Railway) |
| **Encryption** | AES-256-CBC |

## 🔐 Security Features

- ✅ **Rate Limiting:** 100 requests/minute per IP
- ✅ **HTTPS Enforcement:** All connections encrypted
- ✅ **Credential Masking:** No secrets in logs
- ✅ **AES-256 Encryption:** Industry-standard encryption
- ✅ **Separate Password Delivery:** PDF & password sent separately
- ✅ **Request Validation:** Input validation & sanitization
- ✅ **Audit Logging:** Complete event trail
- ✅ **Data Retention:** Automatic old data deletion

## 📚 Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Production setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design details
- [docs/GDPR_COMPLIANCE.md](docs/GDPR_COMPLIANCE.md) - GDPR requirements
- [docs/SECURITY.md](docs/SECURITY.md) - Security implementation
- [docs/API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md) - API reference
- [docs/TESTING.md](docs/TESTING.md) - Testing procedures
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues

## 🧪 Testing

Run complete integration test:
```bash
# See docs/TESTING.md for detailed testing procedures
```

## 📊 Monitoring

- n8n Execution Logs: `https://bechir2002.app.n8n.cloud/workflow/cPZtPvpMr041WQJ1`
- Approval Dashboard: `https://gdprdsarautomation-production.up.railway.app/`
- Supabase Dashboard: `https://supabase.co/dashboard`

## 🤝 Contributing

This is a production system. For changes:
1. Test thoroughly
2. Document changes
3. Update audit logs if needed
4. Deploy to staging first

## 📋 Compliance

- ✅ GDPR Article 15 (Data Access)
- ✅ GDPR Article 32 (Security)
- ✅ GDPR Article 33 (Breach Notification)
- ✅ Right to be Forgotten (90-day auto-delete)

## 📝 License

MIT License - See [LICENSE](LICENSE) file

## 👤 Author

**Bechir Labcheg**
- GitHub: [@bechir06012002](https://github.com/bechir06012002)
- Email: bechir.labcheg@supcom.tn

## 📞 Support

For issues, questions, or deployment help:
1. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review n8n workflow execution logs
3. Check Supabase audit logs
4. Open GitHub issue

## 🎉 Project Status

```
Phase 0-7:   ✅ Core Automation Complete
Phase 8-9:   ✅ Dashboard & Tracking Complete
Phase 10-11: ✅ Logging & Error Handling Complete
Phase 12:    ✅ Production Security Complete

STATUS: 🚀 PRODUCTION READY
```

---

**Built with ❤️ for GDPR Compliance**
