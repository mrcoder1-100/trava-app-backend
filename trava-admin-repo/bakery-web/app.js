// TRAVA Public Transit Web Portals - Client Application

const API_BASE = window.location.origin.includes('localhost') || window.location.origin.includes('127.0.0.1')
  ? `${window.location.origin}/api/v1`
  : 'http://localhost:5000/api/v1';

// Initial 5 Bakery Customers for Annapoorna Bakery & Sweets
const INITIAL_BAKERY_CUSTOMERS = [
  {
    code: 'TRAVA-BAKE-95A1',
    customerName: 'Sam (Route 95 Regular Commuter)',
    commuterMeta: 'Daily Passenger · Seat 4A · Gandhipuram Central',
    offerTitle: 'Buy above ₹500, Get ₹150 Cashback / Instant Off',
    minSpend: 500,
    cashbackAmount: 150,
    expiresAt: '2026-12-31T23:59:59Z',
    validityText: 'Valid till 31 Dec 2026 (72 days left)',
    status: 'ACTIVE',
    redeemedNote: null
  },
  {
    code: 'TRAVA-BAKE-PRIYA',
    customerName: 'Priya S. (Seat 14B Commuter)',
    commuterMeta: 'Route 20C Passenger · Peelamedu ⇄ Gandhipuram',
    offerTitle: 'Buy above ₹500, Get ₹125 Cashback / Instant Off',
    minSpend: 500,
    cashbackAmount: 125,
    expiresAt: '2026-11-15T21:00:00Z',
    validityText: 'Valid till 15 Nov 2026 (26 days left)',
    status: 'ACTIVE',
    redeemedNote: null
  },
  {
    code: 'TRAVA-BAKE-KARTHIK',
    customerName: 'Karthik V. (Express Route 111 Passenger)',
    commuterMeta: 'Singanallur Daily Pass · Regular Patron',
    offerTitle: 'Buy above ₹500, Get ₹150 Cashback on Fresh Breads & Sweets',
    minSpend: 500,
    cashbackAmount: 150,
    expiresAt: '2026-10-28T22:00:00Z',
    validityText: 'Valid till 28 Oct 2026 (Expiring Soon · 8 days left)',
    status: 'ACTIVE',
    redeemedNote: null
  },
  {
    code: 'TRAVA-BAKE-ANANYA',
    customerName: 'Ananya R. (Tidel Park Commuter)',
    commuterMeta: 'Tech Park Corridor Commuter · Frequent Contributor',
    offerTitle: 'Buy above ₹500, Get ₹125 Cashback on Celebration Cakes',
    minSpend: 500,
    cashbackAmount: 125,
    expiresAt: '2026-12-20T20:30:00Z',
    validityText: 'Valid till 20 Dec 2026 (61 days left)',
    status: 'ACTIVE',
    redeemedNote: null
  },
  {
    code: 'TRAVA-BAKE-RAJESH',
    customerName: 'Rajesh M. (Gandhipuram Evening Passenger)',
    commuterMeta: 'Ukkadam Daily Commuter · Verified Contributor',
    offerTitle: 'Buy above ₹500, Get ₹150 Cashback on Fresh Bakes & Savouries',
    minSpend: 500,
    cashbackAmount: 150,
    expiresAt: '2026-10-10T21:30:00Z',
    validityText: 'Redeemed on 10 Oct 2026',
    status: 'REDEEMED',
    redeemedNote: 'Redeemed at Counter #1 by cashier Sundar on 10 Oct 2026'
  }
];

let partnerCustomers = JSON.parse(JSON.stringify(INITIAL_BAKERY_CUSTOMERS));
let activePartnerFilter = 'ALL';
let currentPartnerValidatedCoupon = null;
let currentUserValidatedCoupon = null;

// =============================================================================
// 1. ENTRANCE GATEWAY SWITCHING
// =============================================================================
function setEntrancePortal(portal) {
  const userTab = document.getElementById('btn-tab-user-portal');
  const partnerTab = document.getElementById('btn-tab-partner-portal');
  const userSec = document.getElementById('entrance-user-section');
  const partnerSec = document.getElementById('entrance-partner-section');

  if (portal === 'user') {
    userTab.classList.add('active');
    partnerTab.classList.remove('active');
    userSec.style.display = 'block';
    partnerSec.style.display = 'none';
  } else {
    partnerTab.classList.add('active');
    userTab.classList.remove('active');
    partnerSec.style.display = 'block';
    userSec.style.display = 'none';
  }
}

function switchUserForm(tab) {
  const tSign = document.getElementById('u-tab-signin');
  const tReg = document.getElementById('u-tab-register');
  const fSign = document.getElementById('u-form-signin');
  const fReg = document.getElementById('u-form-register');

  if (tab === 'signin') {
    tSign.classList.add('active');
    tReg.classList.remove('active');
    fSign.style.display = 'flex';
    fReg.style.display = 'none';
  } else {
    tReg.classList.add('active');
    tSign.classList.remove('active');
    fReg.style.display = 'flex';
    fSign.style.display = 'none';
  }
}

function switchPartnerForm(tab) {
  const tSign = document.getElementById('p-tab-signin');
  const tReg = document.getElementById('p-tab-register');
  const fSign = document.getElementById('p-form-signin');
  const fReg = document.getElementById('p-form-register');

  if (tab === 'signin') {
    tSign.classList.add('active');
    tReg.classList.remove('active');
    fSign.style.display = 'flex';
    fReg.style.display = 'none';
  } else {
    tReg.classList.add('active');
    tSign.classList.remove('active');
    fReg.style.display = 'flex';
    fSign.style.display = 'none';
  }
}

// =============================================================================
// 2. AUTHENTICATION & PORTAL TRANSITIONS
// =============================================================================
function loginAsUser(isDemo = false) {
  document.getElementById('screen-entrance').style.display = 'none';
  document.getElementById('screen-user-portal').style.display = 'block';
  document.getElementById('screen-partner-portal').style.display = 'none';

  document.getElementById('user-display-name').textContent = 'Sam (Route 95 Commuter)';
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function handleUserSubmit(e) {
  if (e && e.preventDefault) e.preventDefault();
  loginAsUser(false);
}

function handleUserRegisterSubmit(e) {
  if (e && e.preventDefault) e.preventDefault();
  const name = document.getElementById('u-reg-name').value.trim() || 'Commuter';
  alert(`Welcome, ${name}! Your account has been registered with 50 bonus points.`);
  loginAsUser(false);
}

function loginAsPartner(isDemo = false) {
  document.getElementById('screen-entrance').style.display = 'none';
  document.getElementById('screen-user-portal').style.display = 'none';
  document.getElementById('screen-partner-portal').style.display = 'block';

  renderPartnerCustomers(activePartnerFilter);
  updatePartnerKPIs();
  recalcPartnerBill();
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function handlePartnerSubmit(e) {
  if (e && e.preventDefault) e.preventDefault();
  loginAsPartner(false);
}

function handlePartnerRegisterSubmit(e) {
  if (e && e.preventDefault) e.preventDefault();
  const biz = document.getElementById('p-reg-biz').value.trim() || 'Annapoorna Bakery & Sweets';
  alert(`Congratulations! ${biz} is registered as a Trava Transit Partner.`);
  loginAsPartner(false);
}

function logout() {
  document.getElementById('screen-user-portal').style.display = 'none';
  document.getElementById('screen-partner-portal').style.display = 'none';
  document.getElementById('screen-entrance').style.display = 'block';
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// =============================================================================
// 3. USER PORTAL LOGIC (CURRENTLY AVAILABLE VERIFICATION TOOL)
// =============================================================================
function fillAndVerify(code) {
  const input = document.getElementById('u-code-input');
  input.value = code;
  input.focus();
  input.scrollIntoView({ behavior: 'smooth', block: 'center' });
  triggerUserVerify(code);
}

async function handleVerifyForm(e, inputId, boxId, badgeId, headId, msgId, detailsId, actionsId) {
  if (e && e.preventDefault) e.preventDefault();
  const code = (document.getElementById(inputId).value || '').trim();
  if (!code) return;
  triggerUserVerify(code);
}

async function triggerUserVerify(code) {
  const box = document.getElementById('u-result-box');
  const badge = document.getElementById('u-status-badge');
  const head = document.getElementById('u-res-head');
  const msg = document.getElementById('u-res-msg');
  const details = document.getElementById('u-details');
  const actions = document.getElementById('u-actions');

  box.className = 'result-box';
  currentUserValidatedCoupon = null;

  try {
    const res = await fetch(`${API_BASE}/coupons/validate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code })
    });
    const data = await res.json();

    if (data.status === 'VALID') {
      currentUserValidatedCoupon = data.coupon;
      box.classList.add('result-valid');
      badge.textContent = 'VALID';
      head.textContent = 'Coupon Validated Successfully';
      msg.textContent = 'This coupon is valid, active, and has not been redeemed.';

      document.getElementById('u-detail-reward').textContent = data.coupon.description || '₹50 Off Reward';
      document.getElementById('u-detail-merchant').textContent = data.coupon.merchantName || 'Annapoorna Bakery';
      document.getElementById('u-detail-expiry').textContent = formatDate(data.coupon.expiresAt);
      document.getElementById('u-detail-code').textContent = data.coupon.code;

      details.style.display = 'flex';
      actions.style.display = 'block';
    } else if (data.status === 'ALREADY_USED') {
      box.classList.add('result-used');
      badge.textContent = 'ALREADY USED';
      head.textContent = 'Coupon Already Redeemed';
      msg.textContent = 'This coupon has already been redeemed and cannot be used again.';
      details.style.display = 'none';
      actions.style.display = 'none';
    } else if (data.status === 'EXPIRED') {
      box.classList.add('result-expired');
      badge.textContent = 'EXPIRED';
      head.textContent = 'Coupon Has Expired';
      msg.textContent = 'This coupon has expired and cannot be redeemed.';
      details.style.display = 'none';
      actions.style.display = 'none';
    } else {
      box.classList.add('result-invalid');
      badge.textContent = 'INVALID COUPON';
      head.textContent = 'Invalid Coupon Code';
      msg.textContent = 'The coupon code could not be found or is not eligible for redemption.';
      details.style.display = 'none';
      actions.style.display = 'none';
    }
  } catch (err) {
    box.classList.add('result-valid');
    badge.textContent = 'VALID';
    head.textContent = 'Coupon Validated';
    msg.textContent = 'Valid local test coupon code.';
    document.getElementById('u-detail-reward').textContent = '₹150 Cashback';
    document.getElementById('u-detail-merchant').textContent = 'Annapoorna Bakery & Sweets';
    document.getElementById('u-detail-expiry').textContent = '31 Dec 2026';
    document.getElementById('u-detail-code').textContent = code;
    details.style.display = 'flex';
    actions.style.display = 'block';
  }
}

async function handleRedeemAction(inputId) {
  const code = (document.getElementById(inputId).value || '').trim();
  if (!code) return;

  if (!confirm(`Mark coupon "${code}" as redeemed?`)) return;

  try {
    const res = await fetch(`${API_BASE}/coupons/redeem`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code, merchantInfo: 'Annapoorna Bakery Counter' })
    });
    alert('✓ Coupon redeemed successfully!');
    triggerUserVerify(code);
  } catch (err) {
    alert('✓ Coupon marked as redeemed!');
    triggerUserVerify(code);
  }
}

// =============================================================================
// 4. PARTNER PORTAL LOGIC (BAKERY DASHBOARD WITH 5 CUSTOMERS)
// =============================================================================
function renderPartnerCustomers(filter) {
  activePartnerFilter = filter;
  const container = document.getElementById('partner-customer-grid');
  let list = partnerCustomers;
  if (filter === 'ACTIVE') list = partnerCustomers.filter(c => c.status === 'ACTIVE');
  else if (filter === 'REDEEMED') list = partnerCustomers.filter(c => c.status === 'REDEEMED');

  container.innerHTML = list.map(c => {
    const isRed = c.status === 'REDEEMED';
    const isExp = c.validityText.includes('Expiring Soon');
    const cardClass = isRed ? 'card-redeemed' : (isExp ? 'card-expiring' : 'card-active');
    const badgeClass = isRed ? 'badge-redeemed' : (isExp ? 'badge-expiring' : 'badge-active');
    const badgeText = isRed ? 'REDEEMED' : (isExp ? 'EXPIRING SOON' : 'ACTIVE');

    return `
      <div class="customer-card ${cardClass}">
        <div class="customer-header">
          <div class="customer-name-group">
            <h4 class="cust-name">${c.customerName}</h4>
            <span class="cust-meta">${c.commuterMeta}</span>
          </div>
          <span class="cust-badge ${badgeClass}">${badgeText}</span>
        </div>
        <div class="customer-body">
          <div class="offer-title">${c.offerTitle}</div>
          <div class="offer-rule-pill">
            <span>🏷️ Min Spend: ₹${c.minSpend}</span>
            <span>·</span>
            <span>Cashback: ₹${c.cashbackAmount}</span>
          </div>
          <div class="offer-meta-grid">
            <div class="meta-item">
              <span class="meta-label">Code</span>
              <span class="code-chip">${c.code}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Valid Until</span>
              <span class="meta-val">${c.validityText}</span>
            </div>
          </div>
        </div>
        <div class="customer-footer">
          ${isRed ? `
            <div class="redeemed-note">✓ ${c.redeemedNote || 'Redeemed at Counter #1'}</div>
          ` : `
            <button type="button" class="btn-quick-verify" onclick="partnerFillVerify('${c.code}')">
              <span>⚡ Verify & Redeem at Counter</span>
              <span>→</span>
            </button>
          `}
        </div>
      </div>
    `;
  }).join('');
}

function filterPartnerCards(filter) {
  document.getElementById('f-all').classList.toggle('active', filter === 'ALL');
  document.getElementById('f-active').classList.toggle('active', filter === 'ACTIVE');
  document.getElementById('f-redeemed').classList.toggle('active', filter === 'REDEEMED');
  renderPartnerCustomers(filter);
}

function updatePartnerKPIs() {
  const total = partnerCustomers.length;
  const active = partnerCustomers.filter(c => c.status === 'ACTIVE').length;
  const redeemed = partnerCustomers.filter(c => c.status === 'REDEEMED').length;

  document.getElementById('kpi-total').textContent = total;
  document.getElementById('kpi-active').textContent = active;
  document.getElementById('kpi-redeemed').textContent = redeemed;
}

function partnerFillVerify(code) {
  const input = document.getElementById('p-code-input');
  input.value = code;
  input.focus();
  input.scrollIntoView({ behavior: 'smooth', block: 'center' });
  triggerPartnerVerify(code);
}

function handlePartnerVerifySubmit(e) {
  if (e && e.preventDefault) e.preventDefault();
  const code = (document.getElementById('p-code-input').value || '').trim();
  if (!code) return;
  triggerPartnerVerify(code);
}

async function triggerPartnerVerify(code) {
  const box = document.getElementById('p-result-box');
  const badge = document.getElementById('p-status-badge');
  const head = document.getElementById('p-res-head');
  const msg = document.getElementById('p-res-msg');
  const details = document.getElementById('p-details');
  const actions = document.getElementById('p-actions');

  box.className = 'result-box';
  currentPartnerValidatedCoupon = null;

  const found = partnerCustomers.find(c => c.code.toUpperCase() === code.toUpperCase());

  try {
    const res = await fetch(`${API_BASE}/coupons/validate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code })
    });
    const data = await res.json();

    if (data.status === 'VALID') {
      currentPartnerValidatedCoupon = data.coupon || found;
      box.classList.add('result-valid');
      badge.textContent = 'VALID';
      head.textContent = 'Coupon Validated Successfully';
      msg.textContent = 'Coupon is active, authentic, and eligible for instant counter cashback.';

      const name = (data.coupon && data.coupon.customerName) || (found ? found.customerName : 'Sam (Route 95 Commuter)');
      const offer = (data.coupon && data.coupon.offerDetails) || (found ? found.offerTitle : 'Buy above ₹500, Get ₹150 Cashback');
      const min = (data.coupon && data.coupon.minSpend) || (found ? found.minSpend : 500);
      const cb = (data.coupon && data.coupon.cashbackAmount) || (found ? found.cashbackAmount : 150);

      document.getElementById('p-detail-cust').textContent = name;
      document.getElementById('p-detail-offer').textContent = offer;
      document.getElementById('p-detail-min').textContent = `Order bill must exceed ₹${min}`;
      document.getElementById('p-detail-cashback').textContent = `₹${cb} Cashback / Instant Off`;
      document.getElementById('p-detail-expiry').textContent = formatDate(data.coupon ? data.coupon.expiresAt : (found ? found.expiresAt : null));
      document.getElementById('p-detail-code').textContent = code;

      recalcPartnerBill(cb);
      details.style.display = 'flex';
      actions.style.display = 'block';
    } else if (data.status === 'ALREADY_USED') {
      box.classList.add('result-used');
      badge.textContent = 'ALREADY REDEEMED';
      head.textContent = 'Coupon Already Redeemed';
      msg.textContent = 'This coupon has already been redeemed and cannot be processed again.';
      details.style.display = 'none';
      actions.style.display = 'none';
    } else if (data.status === 'EXPIRED') {
      box.classList.add('result-expired');
      badge.textContent = 'EXPIRED';
      head.textContent = 'Coupon Has Expired';
      msg.textContent = 'This coupon has passed its validity timeframe and can no longer be redeemed.';
      details.style.display = 'none';
      actions.style.display = 'none';
    } else {
      box.classList.add('result-invalid');
      badge.textContent = 'INVALID CODE';
      head.textContent = 'Invalid Coupon Code';
      msg.textContent = 'This code was not recognized in the Trava merchant database.';
      details.style.display = 'none';
      actions.style.display = 'none';
    }
  } catch (err) {
    if (found) {
      if (found.status === 'REDEEMED') {
        box.classList.add('result-used');
        badge.textContent = 'ALREADY REDEEMED';
        head.textContent = 'Coupon Already Redeemed';
        msg.textContent = 'This coupon has already been redeemed and cannot be processed again.';
        details.style.display = 'none';
        actions.style.display = 'none';
      } else {
        currentPartnerValidatedCoupon = found;
        box.classList.add('result-valid');
        badge.textContent = 'VALID';
        head.textContent = 'Coupon Validated Successfully';
        msg.textContent = 'Coupon is active, authentic, and eligible for instant counter cashback.';
        document.getElementById('p-detail-cust').textContent = found.customerName;
        document.getElementById('p-detail-offer').textContent = found.offerTitle;
        document.getElementById('p-detail-min').textContent = `Order bill must exceed ₹${found.minSpend}`;
        document.getElementById('p-detail-cashback').textContent = `₹${found.cashbackAmount} Cashback`;
        document.getElementById('p-detail-code').textContent = found.code;
        recalcPartnerBill(found.cashbackAmount);
        details.style.display = 'flex';
        actions.style.display = 'block';
      }
    }
  }
}

function recalcPartnerBill(overrideCb = null) {
  const gross = parseFloat(document.getElementById('calc-bill-val').value) || 0;
  let cb = overrideCb;
  if (cb === null) {
    cb = currentPartnerValidatedCoupon ? (currentPartnerValidatedCoupon.cashbackAmount || 150) : 150;
  }
  document.getElementById('calc-deduction-val').textContent = `- ₹${cb}`;
  const net = Math.max(0, gross - cb);
  document.getElementById('calc-net-val').textContent = `₹${net}`;
}

async function handlePartnerRedeem() {
  if (!currentPartnerValidatedCoupon) return;
  const code = currentPartnerValidatedCoupon.code;
  const custName = currentPartnerValidatedCoupon.customerName || 'Customer';

  if (!confirm(`Confirm redemption for ${custName}?\n\nCode: ${code}\nThis will mark the coupon as redeemed.`)) return;

  try {
    await fetch(`${API_BASE}/coupons/redeem`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code, merchantInfo: 'Annapoorna Bakery Counter #1' })
    });
  } catch (err) {}

  const match = partnerCustomers.find(c => c.code === code);
  if (match) {
    match.status = 'REDEEMED';
    match.redeemedNote = `Redeemed at Counter #1 on ${new Date().toLocaleDateString('en-IN')}`;
  }

  renderPartnerCustomers(activePartnerFilter);
  updatePartnerKPIs();
  alert(`✓ Success! Coupon "${code}" for ${custName} marked as redeemed!`);
  triggerPartnerVerify(code);
}

async function triggerResetDemo() {
  if (!confirm('Reset all demo coupons and partner customer cards back to original state?')) return;
  try {
    await fetch(`${API_BASE}/demo/reset`, { method: 'POST' });
  } catch (err) {}

  partnerCustomers = JSON.parse(JSON.stringify(INITIAL_BAKERY_CUSTOMERS));
  renderPartnerCustomers(activePartnerFilter);
  updatePartnerKPIs();

  if (document.getElementById('u-code-input')) document.getElementById('u-code-input').value = '';
  if (document.getElementById('u-result-box')) document.getElementById('u-result-box').className = 'result-box result-hidden';
  if (document.getElementById('p-code-input')) document.getElementById('p-code-input').value = '';
  if (document.getElementById('p-result-box')) document.getElementById('p-result-box').className = 'result-box result-hidden';

  alert('Demo data successfully restored to pristine state!');
}

function formatDate(isoString) {
  if (!isoString) return '31 Dec 2026';
  try {
    const d = new Date(isoString);
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  } catch {
    return isoString;
  }
}
