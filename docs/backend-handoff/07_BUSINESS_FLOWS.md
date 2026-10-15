# 07 - Core Business Flows & Lifecycle State Machines

This document specifies the core operational flows of the CarZone platform using **Mermaid** state and sequence diagrams. External developers should refer to these diagrams as the authoritative logic for user workflows and status transitions.

---

## 1. Booking Status Lifecycle State Machine

The order lifecycle models a customer reservation from draft slot reservation to physical service delivery, payment capture, and feedback.

```mermaid
stateDiagram-v2
    [*] --> pending: Customer creates reservation

    pending --> confirmed: Auto-confirmed by branch setting\nOR Manually approved by wash staff
    pending --> cancelled: Cancelled by customer before confirmation

    confirmed --> waiting: Customer arrives at wash\nStaff verifies 5-char code or QR
    confirmed --> cancelled: Cancelled by customer (Checked for late cancel)
    confirmed --> no_show: Customer fails to arrive within no_show_grace_min

    waiting --> in_service: Vehicle moved into bay\nWash detailing commences
    waiting --> cancelled: Cancelled on-site (dispute or vehicle incompatible)

    in_service --> completed: Wash finished & inspected\nPayment captured (Cash/POS Card)

    completed --> [*]
    cancelled --> [*]
    no_show --> [*]
```

### Transition Matrix & Permitted Actors

| Transition | Permitted Role | Trigger Condition / Pre-requisite | Side Effects |
|---|---|---|---|
| `[*] -> pending` | `customer` | Customer selects active service, vehicle, and unallocated slot. | Generates 5-char code, initial timeline entry, notification to customer. |
| `pending -> confirmed` | System / `staff` | Immediate if branch `auto_confirm = true`, else manual staff click. | Timeline appended; QR code unlocked on customer screen. |
| `confirmed -> waiting` | `staff` | Physical vehicle arrival; staff verifies code or scans QR code. | Check-in timestamp recorded; bay queue counter incremented. |
| `waiting -> in_service`| `staff` | Bay becomes free; car moves into wash area. | Live countdown starts in mobile app. |
| `in_service -> completed`| `staff` | Service steps complete; payment collected at desk. | `payment_status` sets to `paid`; triggers `commissions` ledger calculation. |
| `* -> cancelled` | `customer` / `staff` | Permitted only from `pending` or `confirmed` states. | Checks `scheduled_at - now() < free_cancel_min`; marks `late_cancel` if true. |
| `confirmed -> no_show` | `staff` / System | Arrival delay exceeds `no_show_grace_min` (default: 15 min). | Frees bay slot for walk-in customers; logs customer reliability score. |

---

## 2. Complete Booking & Slot Reservation Flow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer (App)
    participant DB as PostgreSQL DB
    participant S as Staff (Dashboard)

    C->>DB: Query available slots for branch on date (duration = 45m)
    DB-->>C: Returns non-overlapping open bay slots (capacity check)
    C->>DB: INSERT INTO orders (branch_id, items, vehicle_id, slot, status: pending)
    
    alt Branch auto_confirm == true
        DB->>DB: UPDATE orders SET status = 'confirmed'
        DB-->>C: Order created & confirmed (Code: "B7X9Q", QR generated)
    else Branch auto_confirm == false
        DB-->>C: Order created (Status: pending confirmation)
        DB-->>S: Realtime event on Dashboard: "New Pending Booking"
        S->>DB: Staff clicks "Accept Booking" (status = 'confirmed')
        DB-->>C: Push Notification: "Your booking has been confirmed!"
    end
```

---

## 3. Pay-at-Wash & Completion Flow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer
    actor S as Branch Staff
    participant Dash as Car Wash Dashboard
    participant DB as PostgreSQL DB

    C->>S: Arrives at car wash reception desk
    S->>Dash: Scans customer QR or enters code ("B7X9Q")
    Dash->>DB: Query order by code and branch_id
    DB-->>Dash: Return order details & customer vehicle
    S->>Dash: Click "Check-In" (status = 'waiting')
    Dash->>DB: UPDATE orders SET status = 'waiting'

    S->>Dash: Vehicle enters bay -> Click "Start Service"
    Dash->>DB: UPDATE orders SET status = 'in_service'

    Note over S: Wash, interior vacuum, and detailing completed

    S->>C: "Your car is ready. Total: 250 EGP"
    C->>S: Pays via Cash or POS Credit Card Machine
    S->>Dash: Click "Complete & Paid" (payment_method: 'cash' | 'card_machine')
    Dash->>DB: UPDATE orders SET status = 'completed', payment_status = 'paid'
    
    Note over DB: PostgreSQL trigger executes:<br/>Calculates 15% platform commission (37.50 EGP)<br/>Inserts row into commissions ledger
    
    DB-->>C: Mobile app prompts: "How was your wash? Leave a review!"
```

---

## 4. Cancellation & Dispute Flow

```mermaid
sequenceDiagram
    autonumber
    actor C as Customer (App)
    participant DB as PostgreSQL DB
    actor Admin as CarZone Admin

    C->>DB: Customer clicks "Cancel Booking"
    DB->>DB: Calculate: (scheduled_at - now()) vs branch.settings.free_cancel_min
    
    alt Time to slot >= free_cancel_min (e.g. 2 hours before)
        DB->>DB: UPDATE orders SET status = 'cancelled', late_cancel = false
        DB-->>C: "Booking cancelled successfully with no fee."
    else Time to slot < free_cancel_min (e.g. 20 min before)
        DB->>DB: UPDATE orders SET status = 'cancelled', late_cancel = true
        DB-->>C: "Cancelled. Flagged as late cancellation under wash policy."
    end

    opt Customer files dispute
        C->>DB: INSERT INTO complaints (order_id, reason, details)
        DB-->>Admin: New ticket in Admin Dispute Desk ("TK-501")
        Admin->>DB: Review timeline & order history
        Admin->>DB: UPDATE complaints SET status = 'resolved', resolution_notes = '...'
    end
```

---

## 5. Platform Commission & Batch Settlement Payout Flow

```mermaid
sequenceDiagram
    autonumber
    participant DB as PostgreSQL DB
    actor Admin as CarZone Admin
    participant Bank as Partner Bank Account
    actor Owner as Car Wash Owner

    Note over DB: Over 7 days, 120 orders completed for "Oasis Nasr"<br/>Gross GMV: 30,000 EGP<br/>Commission (15%): 4,500 EGP<br/>Net Payable to Wash: 25,500 EGP

    Admin->>DB: Open "Settlement & Payouts" page in Admin Panel
    Admin->>DB: Filter commissions WHERE business_id = 'biz_oasis' AND status = 'pending'
    Admin->>DB: Click "Generate Weekly Payout Batch"
    DB->>DB: INSERT INTO payouts (business_id, amount: 25500, status: 'processing')
    DB->>DB: UPDATE commissions SET status = 'settled' WHERE business_id = 'biz_oasis'

    Admin->>Bank: Transfer 25,500 EGP to Partner IBAN (EG...) via Corporate Online Banking
    Admin->>DB: UPDATE payouts SET status = 'completed', reference_number = 'WIRE-20261015-89'
    
    DB-->>Owner: Car Wash Dashboard notification: "Payout of 25,500 EGP has been wired."
```
