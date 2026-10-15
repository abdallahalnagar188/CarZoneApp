# 02 - Complete Database Schema Reference

This document provides the definitive table-by-table reference for the CarZone platform database. Each table is marked as **[EXISTING]** (live in production), **[MODIFIED]** (existing table with proposed non-destructive adjustments), or **[NEW]** (proposed table required for the Car Wash Dashboard and Platform Admin Web Panels).

---

## 1. Schema Legend & Tagging

- **[EXISTING]**: Present in the active Supabase PostgreSQL database. Existing column names, datatypes, and data are preserved intact to guarantee 100% backward compatibility with the Flutter app.
- **[MODIFIED]**: Existing table requiring additional non-destructive columns (nullable or with defaults) or foreign key constraint additions.
- **[NEW]**: New table introduced to support multi-tenancy, partner staff management, financial commissions, payouts, push notifications, and administrative audit logging.

---

## 2. Table Index by Domain

| Domain | Table Name | Status | Primary Purpose |
|---|---|---|---|
| **Identity & Access** | `user_roles` | **[NEW]** | Maps `auth.users` to platform roles (`customer`, `carwash_owner`, `carwash_staff`, `admin`). |
| | `customers` | **[EXISTING / MODIFIED]** | Customer profile info linked to auth users. |
| | `businesses` | **[NEW]** | Legal entity / organization owning one or more car wash branches. |
| | `branch_staff` | **[NEW]** | Maps staff users to specific branches with branch-level roles. |
| **Catalog & Branches**| `areas` | **[EXISTING]** | Geographical districts in Egypt (e.g., Nasr City, New Cairo, Maadi, Dokki). |
| | `branches` | **[EXISTING / MODIFIED]** | Car wash physical locations, working hours, bay capacity, and settings. |
| | `services` | **[EXISTING / MODIFIED]** | Wash packages (primary) and add-on services per branch. |
| | `offers` | **[EXISTING / MODIFIED]** | Promotional campaigns, discounts, and vouchers (platform or branch level). |
| | `branch_shares` | **[EXISTING]** | Analytics tracking for viral link sharing of branch cards. |
| **Vehicles & Booking**| `vehicles` | **[EXISTING / MODIFIED]** | Customer registered vehicles (make, model, color, license plate). |
| | `orders` | **[EXISTING / MODIFIED]** | Booking lifecycle records, reserved slots, totals, and verification code. |
| | `favorites` | **[EXISTING]** | Customer bookmarked favorite car wash branches. |
| **Feedback & Support**| `reviews` | **[EXISTING / MODIFIED]** | Customer ratings, reviews, tags, and branch replies. |
| | `complaints` | **[EXISTING / MODIFIED]** | Support tickets and dispute records tied to orders. |
| **Finance & Settling** | `commissions` | **[NEW]** | Platform commission cuts tracked per completed order. |
| | `business_bank_accounts`| **[NEW]** | Partner car wash bank accounts for settlement payouts. |
| | `payouts` | **[NEW]** | Batch payout ledger records from CarZone to car wash owners. |
| **System & Messaging** | `notifications` | **[EXISTING / MODIFIED]** | In-app user notifications. |
| | `user_push_tokens`| **[NEW]** | Firebase Cloud Messaging (FCM) device registration tokens. |
| | `platform_settings`| **[NEW]** | Global system configuration, default commission %, VAT, rules. |
| | `audit_logs` | **[NEW]** | Security and action logs for administrative and manager events. |
| | `app_health` | **[EXISTING]** | Uptime and health monitor heartbeat table. |

---

## 3. Domain: Identity, Tenancy & Roles

### `user_roles` [NEW]
- **Purpose**: Defines system-wide role assignments for authenticated users. Evaluated in PostgreSQL RLS policies to grant or restrict access across the customer app, car wash dashboard, and admin panel.
- **Client Access**:
  - Customer App: Read own role.
  - Car Wash Panel: Read staff roles within own business.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Unique identifier |
| `user_id` | `uuid` | NO | - | FK `auth.users(id)` ON DELETE CASCADE, UNIQUE | Authenticated user reference |
| `role` | `text` | NO | `'customer'` | CHECK (`role` IN ('customer', 'carwash_owner', 'carwash_staff', 'admin')) | System role |
| `created_at` | `timestamptz` | NO | `now()` | - | Record timestamp |

- **Indexes**:
  - `idx_user_roles_user_id` ON (`user_id`)
  - `idx_user_roles_role` ON (`role`)
- **RLS Policies**:
  - `SELECT`: `(select auth.uid()) = user_id OR auth.user_role() = 'admin'`
  - `INSERT/UPDATE/DELETE`: `auth.user_role() = 'admin'`

---

### `customers` [EXISTING / MODIFIED]
- **Purpose**: Stores profile attributes for registered customers.
- **Modifications**:
  1. Add `status` column (`active`, `blocked`) for admin suspension controls.
  2. Deprecate and discontinue saving plaintext JWT tokens in `access_token` for security hardening.
- **Client Access**:
  - Customer App: Read/Write own record.
  - Car Wash Panel: Read customer name and phone for confirmed orders.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (maps to `auth.users.id` as string) | Customer ID / Auth UID |
| `name` | `text` | NO | - | - | Customer full name |
| `phone` | `text` | NO | - | - | E.164 phone number |
| `created_at` | `timestamptz` | NO | `now()` | - | Registration timestamp |
| `status` | `text` | NO | `'active'` | `[NEW]` CHECK (`status` IN ('active', 'suspended')) | Customer account state |
| `avatar_url` | `text` | YES | `NULL` | `[NEW]` | Profile picture URL in storage |
| `access_token` | `text` | YES | `NULL` | `[DEPRECATED]` | Legacy plaintext token storage (to be retired) |
| `token_updated_at` | `timestamptz` | YES | `NULL` | `[DEPRECATED]` | Timestamp of token update |

- **Indexes**:
  - `customers_pkey` ON (`id`)
  - `idx_customers_phone` ON (`phone`)
- **RLS Policies**:
  - `SELECT`: Public for staff on associated order; owner for own record; admin for all.
  - `UPDATE`: Owner (`(select auth.uid())::text = id`) OR admin.
  - `INSERT`: Public (allows registration during OTP verification).

---

### `businesses` [NEW]
- **Purpose**: Represents a car wash company/entity that owns one or multiple branches. Car wash dashboard users sign in to administer their business.
- **Client Access**:
  - Customer App: Read business name if needed.
  - Car Wash Panel: Read/Write own business details.
  - Admin Panel: Full Read / Write (Approval, verification, commission override).

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | `'biz_' || gen_random_uuid()` | PK | Business identifier |
| `owner_id` | `uuid` | NO | - | FK `auth.users(id)` ON DELETE RESTRICT | Account of the registered business owner |
| `name` | `jsonb` | NO | `'{"ar": "", "en": ""}'` | - | Bilingual business name |
| `legal_name` | `text` | YES | `NULL` | - | Commercial registration name |
| `tax_number` | `text` | YES | `NULL` | - | Egyptian Tax Registration Number |
| `commercial_reg_no`| `text` | YES | `NULL` | - | Egyptian Commercial Register No. |
| `phone` | `text` | NO | - | - | Primary business contact phone |
| `email` | `text` | YES | `NULL` | - | Business contact email |
| `status` | `text` | NO | `'pending'` | CHECK (`status` IN ('pending', 'approved', 'rejected', 'suspended')) | Onboarding verification status |
| `commission_rate` | `numeric(5,2)` | YES | `NULL` | CHECK (`commission_rate` >= 0) | Custom commission % override (NULL uses platform default) |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |
| `updated_at` | `timestamptz` | NO | `now()` | - | Last modification timestamp |

- **Indexes**:
  - `idx_businesses_owner_id` ON (`owner_id`)
  - `idx_businesses_status` ON (`status`)
- **RLS Policies**:
  - `SELECT`: `owner_id = (select auth.uid()) OR auth.user_role() = 'admin'`
  - `UPDATE`: `(owner_id = (select auth.uid()) AND status = 'approved') OR auth.user_role() = 'admin'`
  - `INSERT`: Authenticated users registering as partners; admin.

---

### `branch_staff` [NEW]
- **Purpose**: Associates employees (managers, receptionists, detailers) with specific car wash branches, enabling branch-level dashboard login.
- **Client Access**:
  - Customer App: None.
  - Car Wash Panel: Read/Write staff within own branches.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Unique staff record ID |
| `branch_id` | `text` | NO | - | FK `branches(id)` ON DELETE CASCADE | Associated branch |
| `user_id` | `uuid` | NO | - | FK `auth.users(id)` ON DELETE CASCADE | Staff member user account |
| `role` | `text` | NO | `'receptionist'` | CHECK (`role` IN ('manager', 'receptionist', 'technician')) | Role within the branch |
| `active` | `boolean` | NO | `true` | - | Whether employee is active |
| `created_at` | `timestamptz` | NO | `now()` | - | Record timestamp |

- **Constraints**:
  - UNIQUE (`branch_id`, `user_id`)
- **Indexes**:
  - `idx_branch_staff_branch_id` ON (`branch_id`)
  - `idx_branch_staff_user_id` ON (`user_id`)
- **RLS Policies**:
  - `SELECT`: `user_id = (select auth.uid()) OR branch_id IN (select auth.user_branch_ids()) OR auth.user_role() = 'admin'`
  - `INSERT/UPDATE/DELETE`: Branch owner OR admin.

---

## 4. Domain: Branches & Services Catalog

### `areas` [EXISTING]
- **Purpose**: Geographic service areas in Egypt.
- **Client Access**:
  - All clients: Read-only.
  - Admin Panel: Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'nasr'`, `'tagamoa'`) | Unique slug ID |
| `name` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Area name |
| `lat` | `float8`| NO | - | - | Center latitude |
| `lng` | `float8`| NO | - | - | Center longitude |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |

---

### `branches` [EXISTING / MODIFIED]
- **Purpose**: Physical car wash branch locations. Contains operating schedules, capacity, coordinates, and operating parameters.
- **Modifications**:
  1. Add `approval_status` (`pending`, `approved`, `rejected`) for admin onboarding governance.
  2. Add foreign key linking `business_id` to `businesses(id)`.
  3. Add `logo_url` and `cover_image_url` for custom branding.
- **Client Access**:
  - Customer App: Read active & approved branches.
  - Car Wash Panel: Read / Write branches belonging to own business.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g., `'br_oasis_nasr'`) | Branch slug / identifier |
| `business_id` | `text` | NO | - | FK `businesses(id)` `[NEW FK]` | Parent business company |
| `area_id` | `text` | NO | - | FK `areas(id)` ON DELETE RESTRICT | Geographic district |
| `name` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Branch public name |
| `address` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Physical street address |
| `lat` | `float8`| NO | - | - | GPS latitude |
| `lng` | `float8`| NO | - | - | GPS longitude |
| `phone` | `text` | NO | - | - | Branch contact phone number |
| `capacity` | `integer`| NO | `4` | CHECK (`capacity` > 0) | Simultaneous wash bays count |
| `featured` | `boolean`| NO | `false`| - | Promoted banner indicator |
| `photo_seed` | `integer`| NO | `0` | - | Seed index for cover image |
| `active` | `boolean`| NO | `true` | - | Owner manual toggle (open/closed) |
| `business_active`| `boolean`| NO | `true` | - | Business entity active status |
| `approval_status`| `text` | NO | `'approved'`| `[NEW]` CHECK (`approval_status` IN ('pending', 'approved', 'rejected')) | Platform approval state |
| `logo_url` | `text` | YES | `NULL` | `[NEW]` | Brand logo image in storage |
| `cover_image_url`| `text` | YES | `NULL` | `[NEW]` | High-res cover image URL in storage |
| `working_hours` | `jsonb` | NO | `'[]'` | JSONB array of 7 `WorkingDay` objects | Weekly schedule (open, close, closed) |
| `amenities` | `jsonb` | NO | `'[]'` | Array of strings (`cafe`, `wifi`, `card`, `ac_lounge`) | Available facility perks |
| `settings` | `jsonb` | NO | `'{}'` | JSONB: `auto_confirm`, `slot_interval_min`, `lead_time_min`, `max_advance_days`, `free_cancel_min`, `no_show_grace_min` | Reservation rules |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |

- **Indexes**:
  - `branches_pkey` ON (`id`)
  - `idx_branches_area_id` ON (`area_id`)
  - `idx_branches_business_id` ON (`business_id`)
  - `idx_branches_approval_status` ON (`approval_status`) `[NEW]`

---

### `services` [EXISTING / MODIFIED]
- **Purpose**: Menu of wash services and detailing packages offered by a branch.
- **Client Access**:
  - Customer App: Read active services.
  - Car Wash Panel: Read / Write services for own branches.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'srv_basic_oasis'`) | Unique service identifier |
| `branch_id` | `text` | NO | - | FK `branches(id)` ON DELETE CASCADE | Associated branch |
| `type` | `text` | NO | - | CHECK (`type` IN ('primary', 'addon')) | Service role (base wash vs extra add-on) |
| `category` | `text` | NO | - | E.g. `'wash'`, `'detailing'`, `'polish'`, `'engine'` | Category grouping |
| `name` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Service display name |
| `description` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Detailed description of service steps |
| `price` | `integer`| NO | - | CHECK (`price` >= 0) | Service price in Egyptian Pounds (EGP) |
| `duration_min` | `integer`| NO | - | CHECK (`duration_min` > 0) | Execution time in minutes (used for bay allocation) |
| `active` | `boolean`| NO | `true` | - | Active for customer booking |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |

- **Indexes**:
  - `services_pkey` ON (`id`)
  - `idx_services_branch_id` ON (`branch_id`)
  - `idx_services_type_active` ON (`type`, `active`) `[NEW]`

---

### `offers` [EXISTING / MODIFIED]
- **Purpose**: Promotional discounts, coupon codes, and special campaigns.
- **Client Access**:
  - Customer App: Read active offers.
  - Car Wash Panel: Read / Write offers scoped to own branches.
  - Admin Panel: Full Read / Write (including platform-wide offers).

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'off_weekend_50'`) | Unique offer identifier |
| `platform` | `boolean`| NO | `false`| - | True = platform funded; False = branch funded |
| `branch_ids` | `jsonb` | NO | `'[]'` | JSONB array of branch IDs | Targeted branches |
| `service_ids`| `jsonb` | NO | `'[]'` | JSONB array of service IDs | Targeted services |
| `title` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Offer headline |
| `description`| `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Offer conditions & details |
| `discount_type`| `text` | NO | - | CHECK (`discount_type` IN ('percent', 'fixed')) | Discount calculation mode |
| `discount_value`| `integer`| NO | - | CHECK (`discount_value` > 0) | Discount percentage (e.g. 20) or fixed EGP (e.g. 50) |
| `start_at` | `timestamptz` | NO | - | - | Campaign start datetime |
| `end_at` | `timestamptz` | NO | - | - | Campaign expiration datetime |
| `status` | `text` | NO | `'active'` | CHECK (`status` IN ('active', 'inactive', 'expired')) | Operational status |
| `featured` | `boolean`| NO | `false`| - | Featured on home screen banner |
| `photo_index`| `integer`| NO | `0` | - | Promo graphic index |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |

---

## 5. Domain: Vehicles & Bookings

### `vehicles` [EXISTING / MODIFIED]
- **Purpose**: Customer registered vehicles.
- **Modifications**:
  1. Add formal FK constraint to `customers(id)`.
  2. Add `vehicle_size` (`sedan`, `suv`, `van`, `motorcycle`) for future size-differentiated pricing.
- **Client Access**:
  - Customer App: Full Read / Write for own cars.
  - Car Wash Panel: Read vehicle info on booked orders.
  - Admin Panel: Read all.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'veh_...'`) | Vehicle ID |
| `customer_id` | `text` | NO | - | FK `customers(id)` ON DELETE CASCADE | Vehicle owner |
| `make` | `text` | NO | - | - | Manufacturer (e.g. Toyota, Mercedes) |
| `model` | `text` | NO | - | - | Model (e.g. Corolla, C200) |
| `year` | `integer`| YES | `NULL` | - | Production year |
| `color` | `text` | NO | - | - | Vehicle color |
| `plate` | `text` | NO | - | - | License plate number (e.g. أ ب ج 1 2 3) |
| `is_default` | `boolean`| NO | `false`| - | Default car for rapid checkout |
| `vehicle_size`| `text` | NO | `'sedan'`| `[NEW]` CHECK (`vehicle_size` IN ('sedan', 'suv', 'truck', 'van', 'motorcycle')) | Size class |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |

- **Indexes**:
  - `vehicles_pkey` ON (`id`)
  - `idx_vehicles_customer_id` ON (`customer_id`)

---

### `orders` [EXISTING / MODIFIED]
- **Purpose**: Central transaction entity representing a customer booking.
- **Modifications**:
  1. Add formal FK constraints to `branches(id)`, `customers(id)`, `vehicles(id)`, `offers(id)`.
  2. Add `payment_method` (`cash`, `card_machine`, `online_paymob`).
  3. Add `commission_amount` (computed platform commission in EGP).
  4. Add `payout_id` linking order settlement to `payouts(id)`.
- **Client Access**:
  - Customer App: Read own orders; create booking; cancel within policy.
  - Car Wash Panel: Read branch orders; advance status (`confirmed` -> `waiting` -> `in_service` -> `completed`); verify QR/code; update payment status.
  - Admin Panel: Full Read / Write; emergency status override; refund marking.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'ord_179182390'`) | Unique order identifier |
| `number` | `text` | NO | - | UNIQUE | Customer-facing sequence (e.g. `'CZ-10042'`) |
| `code` | `text` | NO | - | - | 5-character check-in code (e.g. `'B7X9Q'`) |
| `customer_id` | `text` | NO | - | FK `customers(id)` ON DELETE RESTRICT | Booking customer |
| `branch_id` | `text` | NO | - | FK `branches(id)` ON DELETE RESTRICT | Assigned car wash branch |
| `vehicle_id` | `text` | YES | `NULL` | FK `vehicles(id)` `[NEW FK]` | Selected vehicle |
| `items` | `jsonb` | NO | `'[]'` | JSONB array of `OrderItem` objects | Snapshot of booked services, names, prices |
| `subtotal` | `integer`| NO | - | CHECK (`subtotal` >= 0) | Sum of service prices (EGP) |
| `discount` | `integer`| NO | `0` | CHECK (`discount` >= 0) | Total discount applied (EGP) |
| `offer_id` | `text` | YES | `NULL` | FK `offers(id)` `[NEW FK]` | Applied promotion coupon |
| `total` | `integer`| NO | - | CHECK (`total` >= 0) | Net payable amount = subtotal - discount |
| `duration_min` | `integer`| NO | `30` | CHECK (`duration_min` > 0) | Total estimated duration in minutes |
| `scheduled_at` | `timestamptz` | NO | - | - | Reserved slot starting timestamp |
| `status` | `text` | NO | `'pending'` | CHECK (`status` IN ('pending', 'confirmed', 'waiting', 'in_service', 'completed', 'cancelled', 'no_show')) | Order lifecycle state |
| `payment_status`| `text` | NO | `'pending'` | CHECK (`payment_status` IN ('pending', 'paid', 'refunded')) | Payment state |
| `payment_method`| `text` | NO | `'cash'` | `[NEW]` CHECK (`payment_method` IN ('cash', 'card_machine', 'online')) | Payment channel |
| `commission_amount`| `integer`| NO | `0` | `[NEW]` | Platform commission fee (EGP) |
| `payout_id` | `uuid` | YES | `NULL` | `[NEW]` FK `payouts(id)` | Payout batch ID once settled to wash |
| `note` | `text` | YES | `NULL` | - | Customer special instructions |
| `timeline` | `jsonb` | NO | `'[]'` | JSONB array of `{"key": "...", "at": "..."}` | History of state changes |
| `cancel_reason`| `text` | YES | `NULL` | - | Reason provided upon cancellation |
| `late_cancel` | `boolean`| NO | `false`| - | Cancelled inside branch free cancellation window |
| `complaint_id` | `text` | YES | `NULL` | - | Reference ticket number if reported |
| `created_at` | `timestamptz` | NO | `now()` | - | Creation timestamp |

- **Indexes**:
  - `orders_pkey` ON (`id`)
  - `idx_orders_number` ON (`number`) UNIQUE `[NEW]`
  - `idx_orders_customer_id` ON (`customer_id`)
  - `idx_orders_branch_id` ON (`branch_id`)
  - `idx_orders_status` ON (`status`)
  - `idx_orders_scheduled_at` ON (`scheduled_at`) `[NEW]`
  - `idx_orders_created_at` ON (`created_at`) `[NEW]`

---

### `favorites` [EXISTING]
- **Purpose**: Saved car wash branches per user.
- **Client Access**:
  - Customer App: Read / Write own favorites.
  - Car Wash / Admin: Analytics aggregate only.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `user_id` | `text` | NO | - | PK (composite) | User ID |
| `branch_id` | `text` | NO | - | PK (composite), FK `branches(id)` ON DELETE CASCADE | Bookmarked branch |
| `created_at` | `timestamptz` | NO | `now()` | - | Timestamp |

- **Indexes**:
  - `favorites_pkey` ON (`user_id`, `branch_id`)
  - `idx_favorites_branch_id` ON (`branch_id`) `[NEW: recommended by Supabase advisors]`

---

## 6. Domain: Reviews & Complaints

### `reviews` [EXISTING / MODIFIED]
- **Purpose**: Customer feedback, star ratings, and branch management replies.
- **Modifications**:
  1. Add FK linking `order_id` to `orders(id)`.
  2. Add `status` (`published`, `hidden`) for moderation.
- **Client Access**:
  - Customer App: Read published reviews; create review for completed order.
  - Car Wash Panel: Read branch reviews; update `reply`.
  - Admin Panel: Full Read / Write (moderate inappropriate content).

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'rv_...'`) | Review ID |
| `order_id` | `text` | YES | `NULL` | FK `orders(id)` `[NEW FK]` | Completed order reference |
| `customer_name`| `text` | NO | - | - | Display name of reviewer |
| `branch_id` | `text` | NO | - | FK `branches(id)` ON DELETE CASCADE | Rated branch |
| `service_name` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Name of service received |
| `stars` | `integer`| NO | - | CHECK (`stars` BETWEEN 1 AND 5) | Star rating 1 to 5 |
| `comment` | `text` | NO | - | - | Customer textual review |
| `tags` | `jsonb` | NO | `'[]'` | JSONB array of strings | Highlight tags (e.g. 'Fast', 'Clean') |
| `reply` | `text` | YES | `NULL` | - | Car wash management public response |
| `status` | `text` | NO | `'published'`| `[NEW]` CHECK (`status` IN ('published', 'hidden')) | Moderation status |
| `created_at` | `timestamptz` | NO | `now()` | - | Review timestamp |

- **Indexes**:
  - `reviews_pkey` ON (`id`)
  - `idx_reviews_branch_id` ON (`branch_id`)
  - `idx_reviews_order_id` ON (`order_id`) `[NEW]`

---

### `complaints` [EXISTING / MODIFIED]
- **Purpose**: Dispute tickets submitted by customers regarding orders.
- **Modifications**:
  1. Add formal FKs to `customers(id)` and `orders(id)`.
  2. Add `resolution_notes`, `resolved_by`, and `resolved_at`.
- **Client Access**:
  - Customer App: Create ticket; view status of own tickets.
  - Car Wash Panel: View complaints associated with own branch orders.
  - Admin Panel: Full Read / Write; investigate and close tickets.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'cp_...'`) | Unique complaint ID |
| `ticket_number`| `text` | NO | - | UNIQUE | Customer-facing ticket (e.g. `'TK-501'`) |
| `customer_id` | `text` | YES | `NULL` | FK `customers(id)` ON DELETE SET NULL | Complainant customer |
| `order_id` | `text` | YES | `NULL` | FK `orders(id)` ON DELETE SET NULL | Associated order |
| `reason` | `text` | YES | `NULL` | - | Category (e.g. 'Quality', 'Delay', 'Payment') |
| `details` | `text` | YES | `NULL` | - | Description of the issue |
| `status` | `text` | NO | `'open'` | CHECK (`status` IN ('open', 'in_progress', 'resolved', 'dismissed')) | Ticket state |
| `resolution_notes`| `text`| YES | `NULL` | `[NEW]` | Internal/public resolution comment |
| `resolved_by` | `uuid` | YES | `NULL` | `[NEW]` FK `auth.users(id)` | Admin user who resolved ticket |
| `resolved_at` | `timestamptz`| YES| `NULL` | `[NEW]` | Resolution timestamp |
| `created_at` | `timestamptz`| NO | `now()` | - | Creation timestamp |

- **Indexes**:
  - `complaints_pkey` ON (`id`)
  - `idx_complaints_ticket_number` ON (`ticket_number`) UNIQUE `[NEW]`
  - `idx_complaints_order_id` ON (`order_id`) `[NEW]`
  - `idx_complaints_status` ON (`status`) `[NEW]`

---

## 7. Domain: Finance, Commissions & Settlements

### `commissions` [NEW]
- **Purpose**: Ledger record generated automatically upon order completion to calculate platform fees.
- **Client Access**:
  - Customer App: None.
  - Car Wash Panel: Read-only summary of commission deductions for own business.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Commission record ID |
| `order_id` | `text` | NO | - | FK `orders(id)` ON DELETE CASCADE, UNIQUE | Associated completed order |
| `business_id` | `text` | NO | - | FK `businesses(id)` ON DELETE RESTRICT | Responsible business |
| `order_total` | `integer`| NO | - | - | Gross booking price in EGP |
| `rate_applied`| `numeric(5,2)`| NO | - | - | Effective commission percentage applied (e.g. 15.00) |
| `amount` | `integer`| NO | - | - | Platform fee in EGP = `ROUND(order_total * rate / 100)` |
| `net_payout` | `integer`| NO | - | - | Net payable to wash = `order_total - amount` |
| `status` | `text` | NO | `'pending'` | CHECK (`status` IN ('pending', 'settled', 'cancelled')) | Financial settlement status |
| `created_at` | `timestamptz`| NO | `now()` | - | Creation timestamp |

- **Indexes**:
  - `idx_commissions_business_id` ON (`business_id`)
  - `idx_commissions_order_id` ON (`order_id`)
  - `idx_commissions_status` ON (`status`)

---

### `business_bank_accounts` [NEW]
- **Purpose**: Official Egyptian bank accounts registered by partner businesses to receive electronic settlement payouts.
- **Client Access**:
  - Customer App: None.
  - Car Wash Panel: Read / Write bank account for own business.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Bank account ID |
| `business_id` | `text` | NO | - | FK `businesses(id)` ON DELETE CASCADE | Associated business |
| `bank_name` | `text` | NO | - | - | E.g. National Bank of Egypt (NBE), CIB, QNB |
| `account_holder`| `text` | NO | - | - | Legal beneficiary name |
| `account_number`| `text` | NO | - | - | Bank account number |
| `iban` | `text` | NO | - | - | Egyptian IBAN (e.g. EG...) |
| `swift_code` | `text` | YES | `NULL` | - | Bank SWIFT/BIC |
| `is_primary` | `boolean`| NO | `true` | - | Primary disbursement account |
| `created_at` | `timestamptz`| NO | `now()` | - | Creation timestamp |

---

### `payouts` [NEW]
- **Purpose**: Records financial payouts and batch bank transfers executed by CarZone platform administration to car wash partners.
- **Client Access**:
  - Customer App: None.
  - Car Wash Panel: Read payout records for own business.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Payout reference |
| `business_id` | `text` | NO | - | FK `businesses(id)` ON DELETE RESTRICT | Target partner business |
| `amount` | `integer`| NO | - | CHECK (`amount` > 0) | Disbursed amount in EGP |
| `bank_account_id`| `uuid` | NO | - | FK `business_bank_accounts(id)` | Receiving bank account |
| `status` | `text` | NO | `'pending'` | CHECK (`status` IN ('pending', 'processing', 'completed', 'failed')) | Transfer state |
| `reference_number`| `text`| YES | `NULL` | - | Bank transaction / wire transfer reference |
| `period_start` | `date` | NO | - | - | Start of settled orders period |
| `period_end` | `date` | NO | - | - | End of settled orders period |
| `created_by` | `uuid` | NO | - | FK `auth.users(id)` | Admin initiator |
| `completed_at` | `timestamptz`| YES| `NULL` | - | Bank confirmation timestamp |
| `created_at` | `timestamptz`| NO | `now()` | - | Record timestamp |

- **Indexes**:
  - `idx_payouts_business_id` ON (`business_id`)
  - `idx_payouts_status` ON (`status`)

---

## 8. Domain: System, Settings & Notifications

### `platform_settings` [NEW]
- **Purpose**: Key-value platform configuration store (single-row or keyed parameter store).
- **Client Access**:
  - Customer / Car Wash: Read public config.
  - Admin Panel: Full Read / Write.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `key` | `text` | NO | - | PK | Configuration key (e.g. `'default_commission_rate'`) |
| `value` | `jsonb` | NO | - | - | Structured parameter payload |
| `description`| `text` | YES | `NULL` | - | Contextual explanation for admins |
| `is_public` | `boolean`| NO | `false`| - | Whether readable without admin privileges |
| `updated_at` | `timestamptz`| NO | `now()` | - | Last modification timestamp |

---

### `user_push_tokens` [NEW]
- **Purpose**: Stores active Firebase Cloud Messaging (FCM) device registration tokens for push notifications to mobile and web browsers.
- **Client Access**:
  - All clients: Upsert own token upon login.
  - Admin Panel: Read-only.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Token record ID |
| `user_id` | `uuid` | NO | - | FK `auth.users(id)` ON DELETE CASCADE | Associated user |
| `token` | `text` | NO | - | - | FCM registration token string |
| `platform` | `text` | NO | `'android'` | CHECK (`platform` IN ('ios', 'android', 'web')) | Client device environment |
| `updated_at` | `timestamptz`| NO | `now()` | - | Last refresh timestamp |

- **Constraints**:
  - UNIQUE (`user_id`, `token`)
- **Indexes**:
  - `idx_push_tokens_user_id` ON (`user_id`)

---

### `audit_logs` [NEW]
- **Purpose**: Tamper-evident ledger of administrative and sensitive operations (e.g. branch approval, status overrides, fee changes, payout creation).
- **Client Access**:
  - Customer / Car Wash: None.
  - Admin Panel: Read-only.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK | Audit record ID |
| `actor_id` | `uuid` | YES | `NULL` | FK `auth.users(id)` | User who executed the action |
| `actor_role` | `text` | NO | - | - | Role of actor at time of action |
| `action` | `text` | NO | - | - | Operation name (e.g. `'branch.approve'`, `'payout.execute'`) |
| `target_entity`| `text` | NO | - | - | Target table (e.g. `'branches'`, `'payouts'`) |
| `target_id` | `text` | YES | `NULL` | - | Target record primary key |
| `payload` | `jsonb` | YES | `'{}'` | - | Before / after snapshot or parameters |
| `ip_address` | `text` | YES | `NULL` | - | Client IP |
| `created_at` | `timestamptz`| NO | `now()` | - | Action timestamp |

- **Indexes**:
  - `idx_audit_logs_action` ON (`action`)
  - `idx_audit_logs_created_at` ON (`created_at`)

---

### `notifications` [EXISTING / MODIFIED]
- **Purpose**: In-app notifications for order status, updates, and promotions.
- **Client Access**:
  - All clients: Read and mark read own notifications.
  - System / Edge Functions: Insert notifications.

| Column | Type | Nullable | Default | Constraints | Description |
|---|---|---|---|---|---|
| `id` | `text` | NO | - | PK (e.g. `'nt_...'`) | Notification ID |
| `user_id` | `text` | NO | - | - | Target user ID |
| `type` | `text` | NO | - | - | Category (e.g. `'created'`, `'confirmed'`, `'completed'`) |
| `title` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Notification headline |
| `body` | `jsonb` | NO | - | Bilingual `{"ar": "...", "en": "..."}` | Notification text |
| `order_id` | `text` | YES | `NULL` | - | Associated order ID |
| `read` | `boolean`| NO | `false`| - | Read state toggle |
| `created_at` | `timestamptz`| NO | `now()` | - | Timestamp |

- **Indexes**:
  - `notifications_pkey` ON (`id`)
  - `idx_notifications_user_id` ON (`user_id`)
