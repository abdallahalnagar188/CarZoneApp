# 03 - Entity Relationship Diagrams (ERD)

This document contains visual Entity Relationship Diagrams rendered via **Mermaid**. It includes the high-level full system diagram as well as focused domain diagrams for clear readability in GitHub and markdown viewers.

---

## 1. Full Platform ERD Diagram

```mermaid
erDiagram
    AUTH_USERS ||--o| USER_ROLES : "assigned"
    AUTH_USERS ||--o| BUSINESSES : "owns"
    AUTH_USERS ||--o{ BRANCH_STAFF : "employed as"
    AUTH_USERS ||--o{ USER_PUSH_TOKENS : "registers"
    AUTH_USERS ||--o| CUSTOMERS : "profiles"

    BUSINESSES ||--|{ BRANCHES : "operates"
    BUSINESSES ||--o{ BUSINESS_BANK_ACCOUNTS : "maintains"
    BUSINESSES ||--o{ COMMISSIONS : "incurs"
    BUSINESSES ||--o{ PAYOUTS : "receives"

    AREAS ||--o{ BRANCHES : "locates"

    BRANCHES ||--|{ SERVICES : "offers"
    BRANCHES ||--o{ BRANCH_STAFF : "staffs"
    BRANCHES ||--o{ ORDERS : "executes"
    BRANCHES ||--o{ REVIEWS : "collects"
    BRANCHES ||--o{ FAVORITES : "favorited in"
    BRANCHES ||--o{ BRANCH_SHARES : "tracks shares"

    CUSTOMERS ||--o{ VEHICLES : "owns"
    CUSTOMERS ||--o{ ORDERS : "places"
    CUSTOMERS ||--o{ FAVORITES : "saves"
    CUSTOMERS ||--o{ COMPLAINTS : "files"

    OFFERS ||--o{ ORDERS : "discounts"

    VEHICLES ||--o{ ORDERS : "serviced in"

    ORDERS ||--o| REVIEWS : "rated in"
    ORDERS ||--o| COMPLAINTS : "disputed in"
    ORDERS ||--o| COMMISSIONS : "generates"

    PAYOUTS ||--o{ ORDERS : "settles"
    BUSINESS_BANK_ACCOUNTS ||--o{ PAYOUTS : "credited in"

    USER_ROLES {
        uuid id PK
        uuid user_id FK
        text role
        timestamptz created_at
    }

    BUSINESSES {
        text id PK
        uuid owner_id FK
        jsonb name
        text phone
        text status
        numeric commission_rate
    }

    BRANCHES {
        text id PK
        text business_id FK
        text area_id FK
        jsonb name
        jsonb address
        float8 lat
        float8 lng
        int capacity
        text approval_status
        jsonb working_hours
        jsonb settings
    }

    BRANCH_STAFF {
        uuid id PK
        text branch_id FK
        uuid user_id FK
        text role
        bool active
    }

    CUSTOMERS {
        text id PK
        text name
        text phone
        text status
        timestamptz created_at
    }

    VEHICLES {
        text id PK
        text customer_id FK
        text make
        text model
        text plate
        text color
        text vehicle_size
    }

    SERVICES {
        text id PK
        text branch_id FK
        text type
        text category
        jsonb name
        int price
        int duration_min
        bool active
    }

    OFFERS {
        text id PK
        bool platform
        jsonb branch_ids
        jsonb service_ids
        text discount_type
        int discount_value
        text status
    }

    ORDERS {
        text id PK
        text number UK
        text code
        text customer_id FK
        text branch_id FK
        text vehicle_id FK
        text offer_id FK
        jsonb items
        int subtotal
        int discount
        int total
        int duration_min
        timestamptz scheduled_at
        text status
        text payment_status
        text payment_method
        int commission_amount
    }

    REVIEWS {
        text id PK
        text order_id FK
        text branch_id FK
        text customer_name
        int stars
        text comment
        text reply
    }

    COMPLAINTS {
        text id PK
        text ticket_number UK
        text order_id FK
        text customer_id FK
        text reason
        text status
    }

    COMMISSIONS {
        uuid id PK
        text order_id FK
        text business_id FK
        int order_total
        numeric rate_applied
        int amount
        int net_payout
        text status
    }

    PAYOUTS {
        uuid id PK
        text business_id FK
        uuid bank_account_id FK
        int amount
        text status
        text reference_number
    }
```

---

## 2. Domain Diagram: Identity, Roles & Multi-Tenancy

Shows how users, businesses, branch employees, and customer accounts relate across the tenant structure.

```mermaid
erDiagram
    auth_users ||--|| user_roles : "has role"
    auth_users ||--o| businesses : "owns company"
    auth_users ||--o{ branch_staff : "assigned staff"
    auth_users ||--o| customers : "links customer profile"
    auth_users ||--o{ user_push_tokens : "owns device tokens"

    businesses ||--|{ branches : "owns branches"
    branches ||--o{ branch_staff : "has staff members"

    user_roles {
        uuid id PK
        uuid user_id FK
        text role "customer | carwash_owner | carwash_staff | admin"
    }

    businesses {
        text id PK "biz_..."
        uuid owner_id FK "auth.users.id"
        jsonb name "Bilingual"
        text status "pending | approved | suspended"
        numeric commission_rate "NULL for default %"
    }

    branch_staff {
        uuid id PK
        text branch_id FK "branches.id"
        uuid user_id FK "auth.users.id"
        text role "manager | receptionist | technician"
        bool active
    }

    customers {
        text id PK "auth.users.id string"
        text name
        text phone
        text status "active | suspended"
    }
```

---

## 3. Domain Diagram: Wash Operations, Services & Schedules

Illustrates branch layout, operating capacity, hours, and catalog configuration.

```mermaid
erDiagram
    areas ||--o{ branches : "encloses"
    branches ||--|{ services : "configures catalog"
    branches ||--o{ offers : "associates via branch_ids"

    branches {
        text id PK "br_..."
        text business_id FK "businesses.id"
        text area_id FK "areas.id"
        jsonb name
        jsonb address
        float8 lat
        float8 lng
        int capacity "Bay concurrency (e.g. 4)"
        text approval_status "pending | approved"
        jsonb working_hours "Array of 7 day schedules"
        jsonb settings "slotInterval, leadTime, cancelWindow"
    }

    services {
        text id PK "srv_..."
        text branch_id FK "branches.id"
        text type "primary | addon"
        text category "wash | detailing | polish"
        jsonb name "Bilingual"
        int price "EGP integer"
        int duration_min "Allocates bay duration"
        bool active
    }

    offers {
        text id PK "off_..."
        bool platform "Platform vs Partner funded"
        jsonb branch_ids "Array of branch strings"
        jsonb service_ids "Array of service strings"
        text discount_type "percent | fixed"
        int discount_value
        timestamptz start_at
        timestamptz end_at
        text status "active | inactive"
    }
```

---

## 4. Domain Diagram: Booking Lifecycle, Vehicles & Customer Support

Models the transaction lifecycle from vehicle registration to check-in, review, and issue dispute.

```mermaid
erDiagram
    customers ||--|{ vehicles : "registers"
    customers ||--o{ orders : "books"
    vehicles ||--o{ orders : "assigned car"
    branches ||--o{ orders : "fulfills"

    orders ||--o| reviews : "receives rating"
    orders ||--o| complaints : "disputed via ticket"

    vehicles {
        text id PK "veh_..."
        text customer_id FK "customers.id"
        text make "Toyota, Hyundai..."
        text model "Corolla, Tucson..."
        text color
        text plate "License Plate"
        text vehicle_size "sedan | suv | truck"
    }

    orders {
        text id PK "ord_..."
        text number UK "CZ-10042"
        text code "5-char PIN"
        text customer_id FK "customers.id"
        text branch_id FK "branches.id"
        text vehicle_id FK "vehicles.id"
        jsonb items "Snapshot of services & prices"
        int subtotal "EGP"
        int discount "EGP"
        int total "EGP"
        int duration_min "Sum duration"
        timestamptz scheduled_at "Slot time"
        text status "pending -> confirmed -> waiting -> in_service -> completed"
        text payment_status "pending | paid | refunded"
        text payment_method "cash | card_machine | online"
        jsonb timeline "Timestamped event log"
    }

    reviews {
        text id PK "rv_..."
        text order_id FK "orders.id"
        text branch_id FK "branches.id"
        int stars "1 to 5"
        text comment
        text reply "Management response"
    }

    complaints {
        text id PK "cp_..."
        text ticket_number UK "TK-501"
        text order_id FK "orders.id"
        text customer_id FK "customers.id"
        text reason
        text status "open | in_progress | resolved"
        text resolution_notes
    }
```

---

## 5. Domain Diagram: Financial Commissions & Settlements

Illustrates the flow of money, platform commission ledger entries, and batch bank payouts to partner car washes.

```mermaid
erDiagram
    businesses ||--|{ business_bank_accounts : "configures"
    businesses ||--o{ commissions : "incurs fee"
    businesses ||--o{ payouts : "receives disbursement"

    orders ||--|| commissions : "generates fee upon completion"
    payouts ||--o{ orders : "marks orders settled via payout_id"
    business_bank_accounts ||--o{ payouts : "receiving IBAN"

    commissions {
        uuid id PK
        text order_id FK "orders.id"
        text business_id FK "businesses.id"
        int order_total "Gross EGP"
        numeric rate_applied "e.g. 15.00%"
        int amount "Platform fee in EGP"
        int net_payout "Wash share in EGP"
        text status "pending | settled"
    }

    business_bank_accounts {
        uuid id PK
        text business_id FK "businesses.id"
        text bank_name "e.g. NBE, CIB"
        text account_holder
        text account_number
        text iban "EG..."
        bool is_primary
    }

    payouts {
        uuid id PK
        text business_id FK "businesses.id"
        uuid bank_account_id FK "business_bank_accounts.id"
        int amount "Disbursed EGP sum"
        text status "pending | completed"
        text reference_number "Bank transfer reference"
        date period_start
        date period_end
        timestamptz completed_at
    }
```
