# CarZone Platform - Developer Handoff Package

Welcome to the CarZone Backend & Integration Handoff Package. This documentation package is prepared for the external engineering team building the **Car Wash Dashboard Web Panel** and the **Platform Admin Web Panel**, integrating with the existing **Supabase Backend** and the live **Flutter Customer App**.

---

## 📌 Document Index

| # | Document | Target Audience | Description |
|---|---|---|---|
| **01** | [01_PROJECT_OVERVIEW.md](file:///docs/backend-handoff/01_PROJECT_OVERVIEW.md) | All Developers, PMs | Product description, user personas, three-client architecture, multi-tenancy model. |
| **02** | [02_DATABASE_SCHEMA.md](file:///docs/backend-handoff/02_DATABASE_SCHEMA.md) | Database & Backend Devs | Table-by-table schema reference (`[EXISTING]`, `[MODIFIED]`, `[NEW]`), columns, types, FKs, RLS, indexes. |
| **03** | [03_ERD_DIAGRAM.md](file:///docs/backend-handoff/03_ERD_DIAGRAM.md) | All Developers | Mermaid ERDs for the entire platform and modular domain diagrams. |
| **04** | [04_SCHEMA.sql](file:///docs/backend-handoff/04_SCHEMA.sql) | DevOps, Backend Devs | Runnable, idempotent SQL script: extensions, enums, tables, functions, triggers, RLS, and seed data. |
| **05** | [05_AUTH_AND_ROLES.md](file:///docs/backend-handoff/05_AUTH_AND_ROLES.md) | Frontend & Security Devs | Authentication flows, role resolution (`public.user_roles` vs JWT claims), onboarding, initial Admin setup. |
| **06** | [06_API_INTEGRATION_GUIDE.md](file:///docs/backend-handoff/06_API_INTEGRATION_GUIDE.md) | Web Panel Developers | Ready-to-use TypeScript / `@supabase/supabase-js` code snippets, queries, mutations, and Realtime listeners. |
| **07** | [07_BUSINESS_FLOWS.md](file:///docs/backend-handoff/07_BUSINESS_FLOWS.md) | Frontend Devs, QA | Mermaid state & sequence diagrams: booking lifecycle, slots, commission, payout, approval, refunds. |
| **08** | [08_PANEL_REQUIREMENTS.md](file:///docs/backend-handoff/08_PANEL_REQUIREMENTS.md) | Frontend Devs, UI/UX | Feature checklist and page-by-page screen requirements for both web panels. |
| **09** | [09_GAPS_AND_RECOMMENDATIONS.md](file:///docs/backend-handoff/09_GAPS_AND_RECOMMENDATIONS.md) | Tech Leads, Architects | Audit findings, security vulnerabilities, performance fixes, prioritized roadmap, and Open Questions. |

---

## 🚀 Quick Start for Web Developers

### 1. Technology Baseline
- **Backend**: Supabase (PostgreSQL 17, PostgREST API, Supabase Auth, Storage, Edge Functions, Realtime WebSocket).
- **Recommended Web Stack**: Next.js 15+ (App Router), React 19, TypeScript, Tailwind CSS / Shadcn UI, TanStack Query, `@supabase/ssr` / `@supabase/supabase-js`.
- **Locale & Language**: Bilingual Arabic (`ar`, RTL) and English (`en`, LTR). Arabic is default in Egypt.
- **Currency**: Egyptian Pound (**EGP** / **ج.م**).
- **Timezone**: `Africa/Cairo` (UTC+2 or UTC+3 during Daylight Saving Time).

### 2. Environment Variables Configuration

Create a `.env.local` file in your web projects:

```bash
# Public URL & Anon Key (SAFE for browser clients)
NEXT_PUBLIC_SUPABASE_URL=https://tbcmgdwzarfdgzzmmele.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4

# Server-Side Only Service Role Key (NEVER expose to browser / client bundles)
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here
```

> [!CAUTION]
> **CRITICAL SECURITY RULE**: Never bundle `SUPABASE_SERVICE_ROLE_KEY` in frontend code. Public browsers must always connect using `NEXT_PUBLIC_SUPABASE_ANON_KEY` combined with the user's active Supabase Auth session token, relying on PostgreSQL Row-Level Security (RLS) for data protection.

---

## 👥 Roles & Client Access Summary

| Role | Client Application | Auth Mechanism | Primary Scope |
|---|---|---|---|
| **Customer** | Flutter Mobile App (iOS / Android) | Phone OTP via WhatsApp / SMS | Books car washes, manages vehicles, tracks active orders, writes reviews. |
| **Car Wash Owner** | Car Wash Dashboard (Web) | Email & Password (+ MFA) | Manages business branches, services, staff, bay capacity, schedules, and earnings. |
| **Car Wash Staff** | Car Wash Dashboard (Web) | Email & Password | Operates daily bay queue, verifies order codes/QR, advances order statuses. |
| **Platform Admin** | Platform Admin Panel (Web) | Email & Password (+ MFA) | Manages wash onboarding, commissions, disputes, payouts, platform settings, audits. |

---

## 📦 Supabase Project Details

- **Project ID**: `tbcmgdwzarfdgzzmmele`
- **Region**: `eu-west-1`
- **Postgres Engine**: PostgreSQL 17.11
- **API Base URL**: `https://tbcmgdwzarfdgzzmmele.supabase.co`
- **Storage Bucket**: `images` (Wash branch photos, service pictures, complaint attachments)
- **Edge Functions**:
  - `send-sms-whatsapp`: Auth SMS/WhatsApp OTP webhook handler.
  - `share-wash`: OpenGraph dynamic preview and mobile deep linking handler (`carzone://wash?id=...`).
