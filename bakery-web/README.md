# TRAVA Dual Web Portals
**Official Tagline:** *People Solving People's Problem.*  
**Live URL:** `http://localhost:5000/bakery`

---

## Architecture Overview
The web application hosts two distinct portals with a top switcher pill:

### 👤 Portal 1: User / Commuter Portal (`#user-portal`)
- **Authentication**:
  - Sign In with Email & Password.
  - Register as a new commuter with starting 50 bonus points.
  - **⚡ 1-Click Commuter Demo Login**: Instantly signs in as **Sam** (`demo@trava.org` / `Password123!`).
- **Commuter Dashboard**:
  - Displays user profile, route metadata (Route 95 Regular Commuter), and points balance.
  - Displays unlocked scratch cards and active reward coupons:
    - **Annapoorna Bakery & Sweets**: *"Buy above ₹500, Get ₹150 Cashback / Instant Off"* (`TRAVA-BAKE-95A1`).
    - Sree Annapoorna Restaurant: ₹75 Off Dosa & Thali (`TRAVA-REST-75ROAST`).
    - Nilgiris 1905 Supermarket: ₹60 Off Groceries (`TRAVA-MART-60NILGIRI`).
    - Slam Fitness Studio: 3-Day Pass + ₹500 Off (`TRAVA-GYM-SLAMFIT`).
  - Copy coupon code action.

---

### 🏪 Portal 2: Trava Partners Portal (`#partner-portal`)
- **Merchant Authentication**:
  - Sign in with Business Email & Password.
  - Register new store (Business Name, Category: Bakery / Restaurant / Supermarket / Gym, Owner Name, Location).
  - **🥐 1-Click Bakery Demo Login**: Instantly logs in as **Annapoorna Bakery & Sweets** (Owner: Sundar Raman · Gandhipuram Central Bus Stand Terminal).
- **Bakery Partner Dashboard**:
  - Store profile header with verified partner badge and terminal info.
  - Live KPI cards: Total Issued (5), Active (4), Redeemed Today (1), Customer Value (₹700 Cashback driving ₹2,500+ spend).
- **Issued Customer Coupon Cards (5 Commuters)**:
  1. **Sam (Daily Commuter)**:
     - Offer: *"Buy above ₹500, Get ₹150 Cashback / Instant Off"*
     - Code: `TRAVA-BAKE-95A1` · Min spend: ₹500 · Valid till 31 Dec 2026 · Status: `ACTIVE`
  2. **Priya S. (Seat 14B Commuter)**:
     - Offer: *"Buy above ₹500, Get ₹125 Cashback / Instant Off"*
     - Code: `TRAVA-BAKE-PRIYA` · Min spend: ₹500 · Valid till 15 Nov 2026 · Status: `ACTIVE`
  3. **Karthik V. (Express Route 111 Passenger)**:
     - Offer: *"Buy above ₹500, Get ₹150 Cashback on Fresh Breads & Sweets"*
     - Code: `TRAVA-BAKE-KARTHIK` · Min spend: ₹500 · Valid till 28 Oct 2026 · Status: `ACTIVE (EXPIRING SOON)`
  4. **Ananya R. (Tidel Park Commuter)**:
     - Offer: *"Buy above ₹500, Get ₹125 Cashback on Celebration Cakes"*
     - Code: `TRAVA-BAKE-ANANYA` · Min spend: ₹500 · Valid till 20 Dec 2026 · Status: `ACTIVE`
  5. **Rajesh M. (Gandhipuram Evening Passenger)**:
     - Offer: *"Buy above ₹500, Get ₹150 Cashback on Fresh Bakes & Savouries"*
     - Code: `TRAVA-BAKE-RAJESH` · Min spend: ₹500 · Status: `REDEEMED` (*Marked Redeemed at Counter #1 on 10 Oct 2026*)
- **Cashier Counter Verification & Redemption Tool**:
  - Quick test buttons for demo presentation.
  - Live validation engine showing Customer Name, Offer Terms, Minimum Spend Verification (`Must spend >₹500`), and expiry date.
  - **Bill Calculation Simulator**: (e.g. Gross Bill ₹650 - ₹150 Cashback = ₹500 Net to Collect).
  - **"✓ Confirm & Mark as Redeemed"**: Atomic backend sync with race-condition protection.
- **Demo Reset**: Restores initial clean presentation state with one click.
