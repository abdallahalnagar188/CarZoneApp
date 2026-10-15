# 08 - Web Panel Requirements & UI Screen Specifications

This document outlines the functional requirements, page structure, data mapping, and UI components for both the **Car Wash Dashboard** and the **Platform Admin Panel**.

---

## Part 1: Car Wash Dashboard (Web Panel)

The dashboard is designed for desktop and tablet screens (e.g., reception iPad/tablet in the car wash waiting room).

### 1. Navigation Structure
```
Car Wash Dashboard
├── /login (Email & Password)
├── /dashboard (Live Bay Overview & Daily KPIs)
├── /bookings (Dispatcher & Slot Calendar)
│    ├── /bookings/list (Tabular list with filters)
│    └── /bookings/check-in (QR Scanner & Verification Modal)
├── /services (Services & Add-ons Catalog)
├── /operating-hours (Weekly Schedule & Bay Capacity)
├── /staff (Branch Staff Management)
├── /earnings (Revenue, Commission Ledger & Payouts)
├── /reviews (Customer Feedback & Public Replies)
└── /settings (Branch Profile, Photos & Rules)
```

---

### 2. Page Specifications & Database Mappings

#### A. Dashboard Overview (`/dashboard`)
- **Key Metrics Cards**:
  - Today's Total Bookings (count of `orders` scheduled for today).
  - Active Bay Occupancy (e.g. "3 / 4 Bays Busy").
  - Gross Revenue Today (sum of `orders.total` where `payment_status = 'paid'`).
  - Pending Approval Bookings (`status = 'pending'`).
- **Live Bay Grid**:
  - Visual cards representing each physical wash bay (Bay 1, Bay 2, Bay 3, Bay 4).
  - Displays currently servicing car (Plate, Make/Model, Service Package, Elapsed Time).
  - Quick action buttons: "Advance to Next Stage", "Complete & Pay".
- **Database Tables**: `orders`, `branches`, `vehicles`.

---

#### B. Bookings Management & Dispatcher (`/bookings`)
- **Views**:
  - **Timeline / Slot Gantt Chart**: Visual slots (30-min intervals) matching branch working hours.
  - **List Table View**: Columns: Order #, Scheduled Time, Customer Name & Phone, Vehicle Plate, Services, Total (EGP), Status Badge, Action Menu.
- **Filters**:
  - Date picker (Today, Tomorrow, Custom Date Range).
  - Status filter pill buttons: All, Pending, Confirmed, Waiting, In Service, Completed, Cancelled.
- **Check-In Modal (`/bookings/check-in`)**:
  - Integrated webcam/camera QR code reader + manual 5-character alphanumeric text input.
  - On match, opens customer sheet: Customer name, phone, plate, items, payment status, and single-click "Check In (Mark Waiting)" button.
- **Database Tables**: `orders`, `customers`, `vehicles`, `services`.

---

#### C. Services & Add-ons Catalog (`/services`)
- **Sections**:
  - **Primary Packages**: Base wash services (e.g., "Fast Wash", "Full Steam Wash", "VIP Detailing").
  - **Add-on Services**: Optional add-ons (e.g., "Engine Degreasing", "Leather Conditioning", "Tire Shine").
- **Table Columns**:
  - Service Name (Bilingual Arabic / English).
  - Category tag.
  - Duration (minutes).
  - Price (EGP).
  - Status (Active / Inactive toggle switch).
  - Actions: Edit modal, Duplicate, Archive.
- **Add / Edit Modal**: Form inputs for Arabic name, English name, category dropdown, price in EGP, duration in minutes, and primary/addon radio selector.
- **Database Tables**: `services`.

---

#### D. Operating Hours & Capacity Settings (`/operating-hours`)
- **Day-by-Day Schedule Form**:
  - Monday to Sunday rows.
  - Open time picker (default `09:00`), Close time picker (default `22:00`).
  - "Closed Today" toggle switch.
- **Reservation Tuning**:
  - Simultaneous Wash Bay Capacity (number input, e.g. 4 bays).
  - Slot Interval (e.g. 15 min, 30 min, 45 min).
  - Lead Time (minimum notice before booking, e.g. 15 min).
  - Free Cancellation Cutoff (e.g. 60 min before slot).
  - Auto-Confirm Bookings (Toggle on/off).
- **Database Tables**: `branches.working_hours`, `branches.settings`, `branches.capacity`.

---

#### E. Earnings, Commission & Settlements (`/earnings`)
- **KPIs**: Total Settled Payouts, Pending Net Payout, Accumulated Commission Deducted.
- **Commission Breakdown Table**:
  - Order #, Date, Customer, Gross Amount (EGP), Commission % (e.g. 15%), Commission Fee (EGP), Net Wash Share (EGP), Status (`pending` / `settled`).
- **Payout History**: List of bank wire transfers received from CarZone platform with bank transfer reference number and settlement dates.
- **Bank Account Setup**: Form to enter Bank Name, Account Holder Name, Account Number, and IBAN.
- **Database Tables**: `commissions`, `payouts`, `business_bank_accounts`.

---

#### F. Reviews & Public Feedback (`/reviews`)
- **List of Customer Reviews**:
  - Star rating (1-5), Customer Name, Service Name, Comment text, Date, highlight tags.
  - Management Public Reply box: textarea to write a response that appears publicly in the customer mobile app.
- **Database Tables**: `reviews`.

---

## Part 2: Platform Admin Panel (Web Panel)

Designed for the CarZone executive team to oversee platform operations, onboard partners, manage commissions, handle complaints, and adjust platform settings.

### 1. Navigation Structure
```
CarZone Platform Admin
├── /login (Admin Email, Password & MFA)
├── /dashboard (Executive KPIs & Platform Health)
├── /partners (Car Wash Partners & Applications)
│    ├── /partners/pending (Review & Approval Queue)
│    └── /partners/all (Directory, Commissions & Overrides)
├── /branches (All Wash Stations, Bay Capacity & Statuses)
├── /bookings (Global Orders Monitor & Overrides)
├── /finance (Commissions, Payout Engine & Settlements)
├── /disputes (Complaints & Dispute Resolution Desk)
├── /users (Customers & Staff Management)
├── /marketing (Platform Offers & Coupons)
├── /audit-logs (Security & Action History)
└── /settings (Platform Settings & System Parameters)
```

---

### 2. Page Specifications & Database Mappings

#### A. Executive Dashboard (`/dashboard`)
- **Metrics**:
  - Total Platform GMV (Gross Merchandise Value in EGP).
  - Platform Commission Earned (EGP).
  - Active Certified Branches count.
  - Total Completed Washes count.
  - Open Dispute Complaints count.
- **Charts**:
  - Daily bookings volume (Bar chart).
  - Revenue by Area / District (Nasr City, Tagamoa, Maadi, etc.).
- **Database Tables**: `orders`, `commissions`, `branches`, `complaints`.

---

#### B. Partner Onboarding & Approval Queue (`/partners/pending`)
- **Application Review Card**:
  - Legal Business Name, Tax Registration Number, Commercial Registration Number.
  - Owner Name, Phone, and Email.
  - Branch location preview (Map pin, Area, Address).
  - Working Hours and Bay Capacity proposed.
- **Approval Actions**:
  - Set Commission Rate override (% input; defaults to 15.00%).
  - Approve Button (marks `businesses.status = 'approved'`, `branches.approval_status = 'approved'`).
  - Reject Button (prompts for rejection reason sent to partner).
- **Database Tables**: `businesses`, `branches`, `audit_logs`.

---

#### C. Financial Payout Engine (`/finance`)
- **Partner Balance Overview**: Table showing each car wash company, their pending unpaid balance, bank IBAN, and date of last settlement.
- **Batch Payout Generator**:
  - Select partner(s), choose date range, preview total EGP sum.
  - Click "Generate Payout": Inserts `payouts` record, updates `commissions.status = 'settled'`.
  - Input field for Bank Wire Transfer Reference Number once executed through corporate banking.
- **Database Tables**: `commissions`, `payouts`, `business_bank_accounts`.

---

#### D. Complaints & Dispute Desk (`/disputes`)
- **Ticket Queue**: Ticket # (`TK-501`), Customer, Branch, Reason (Delay, Quality, Overcharge), Status (`open`, `in_progress`, `resolved`).
- **Investigation Detail Drawer**:
  - Order breakdown, customer timeline, branch contact.
  - Resolution notes textarea.
  - Mark as Resolved button.
- **Database Tables**: `complaints`, `orders`, `customers`.

---

#### E. System Settings & Audit Logs (`/settings` & `/audit-logs`)
- **Config Form**: Default commission %, VAT % toggle, booking lead time limits.
- **Audit Table**: Timestamp, Actor (Admin name/email), Action name (`business.approved`, `branch.suspended`), Target Entity, IP Address.
- **Database Tables**: `platform_settings`, `audit_logs`.
