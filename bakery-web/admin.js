// Trava Master Admin Command Center Logic
const API_BASE = window.location.origin.includes('localhost') 
  ? 'http://localhost:5000/api/v1/admin' 
  : `${window.location.origin}/api/v1/admin`;

let state = {
  overview: null,
  commuters: [],
  partners: [],
  coupons: [],
  fleet: [],
  redemptions: [],
  selectedCommuterId: null
};

// Initialize Admin Dashboard on load
document.addEventListener('DOMContentLoaded', () => {
  initTabs();
  loadAllData();
  // Auto refresh every 20 seconds
  setInterval(loadAllData, 20000);
});

function initTabs() {
  const tabs = document.querySelectorAll('.tab-btn');
  tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
      
      btn.classList.add('active');
      const targetId = btn.getAttribute('data-tab');
      const targetContent = document.getElementById(targetId);
      if (targetContent) targetContent.classList.add('active');
    });
  });
}

async function loadAllData() {
  try {
    const [overviewRes, commutersRes, partnersRes, couponsRes, fleetRes, redemptionsRes] = await Promise.all([
      fetch(`${API_BASE}/overview`).then(r => r.json()),
      fetch(`${API_BASE}/commuters`).then(r => r.json()),
      fetch(`${API_BASE}/partners`).then(r => r.json()),
      fetch(`${API_BASE}/coupons`).then(r => r.json()),
      fetch(`${API_BASE}/fleet`).then(r => r.json()),
      fetch(`${API_BASE}/redemptions`).then(r => r.json())
    ]);

    if (overviewRes.success) {
      state.overview = overviewRes.data;
      renderKPIs(overviewRes.data);
    }
    if (commutersRes.success) {
      state.commuters = commutersRes.data;
      renderCommuters(commutersRes.data);
    }
    if (partnersRes.success) {
      state.partners = partnersRes.data;
      renderPartners(partnersRes.data);
    }
    if (couponsRes.success) {
      state.coupons = couponsRes.data;
      renderCoupons(couponsRes.data);
    }
    if (fleetRes.success) {
      state.fleet = fleetRes.data;
      renderFleet(fleetRes.data);
    }
    if (redemptionsRes.success) {
      state.redemptions = redemptionsRes.data;
      renderRedemptions(redemptionsRes.data);
    }

    const timeElem = document.getElementById('last-sync-time');
    if (timeElem) timeElem.innerText = `Synced: ${new Date().toLocaleTimeString()}`;
  } catch (err) {
    console.error('Error fetching admin data:', err);
    showToast('Failed to connect to backend API: ' + err.message, 'error');
  }
}

function renderKPIs(data) {
  document.getElementById('kpi-commuters').innerText = data.commutersCount;
  document.getElementById('kpi-partners').innerText = data.partnersCount;
  document.getElementById('kpi-buses').innerText = data.busesCount;
  document.getElementById('kpi-points').innerText = `${data.totalPointsAwarded} pts`;
  document.getElementById('kpi-coupons').innerText = `${data.activeCouponsCount} Active`;
  document.getElementById('kpi-cashback').innerText = `₹${data.totalCashbackDistributed}`;
  
  // Tab badges
  const badgeComm = document.getElementById('badge-commuters-count');
  if (badgeComm) badgeComm.innerText = data.commutersCount;
  const badgePart = document.getElementById('badge-partners-count');
  if (badgePart) badgePart.innerText = data.partnersCount;
  const badgeCoup = document.getElementById('badge-coupons-count');
  if (badgeCoup) badgeCoup.innerText = data.activeCouponsCount + data.redeemedCouponsCount;
  const badgeFleet = document.getElementById('badge-fleet-count');
  if (badgeFleet) badgeFleet.innerText = data.busesCount;
}

function renderCommuters(commuters) {
  const tbody = document.getElementById('commuters-table-body');
  if (!tbody) return;

  if (commuters.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding: 24px; color: #94A3B8;">No commuters registered yet</td></tr>`;
    return;
  }

  tbody.innerHTML = commuters.map(c => `
    <tr>
      <td>
        <div class="user-cell">
          <div class="avatar-circle">${c.fullName.substring(0, 2).toUpperCase()}</div>
          <div>
            <strong>${escapeHtml(c.fullName)}</strong>
            ${c.isDemoAccount ? '<span class="status-pill pill-govt" style="margin-left:4px;">Demo</span>' : ''}
            <div style="font-size:11px; color:#64748B;">ID: ${c.id}</div>
          </div>
        </div>
      </td>
      <td>
        <div>${escapeHtml(c.email)}</div>
        <div style="font-size:11px; color:#64748B;">${c.phone || '+91 98421 10095'}</div>
      </td>
      <td>
        <span class="status-pill pill-active">👤 ${c.role}</span>
      </td>
      <td>
        <strong style="color: #0F4C3A; font-size:14px;">${c.pointsBalance}</strong> pts
      </td>
      <td>
        <strong>${c.couponsCount}</strong> total (${c.activeCoupons} active)
      </td>
      <td>
        <span class="status-pill pill-govt">Coimbatore Regular</span>
      </td>
      <td>
        <button class="btn-action-sm btn-primary-sm" onclick="openGrantPointsModal('${c.id}', '${escapeHtml(c.fullName)}', ${c.pointsBalance})">
          🎁 + Points
        </button>
      </td>
    </tr>
  `).join('');
}

function renderPartners(partners) {
  const container = document.getElementById('partners-grid-container');
  if (!container) return;

  container.innerHTML = partners.map(p => `
    <div class="admin-card" style="margin-bottom:0;">
      <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:12px;">
        <div>
          <span class="status-pill pill-active" style="margin-bottom:6px;">🏪 ${p.category}</span>
          <h3 style="font-size:16px; font-weight:800; color: #0F172A;">${escapeHtml(p.name)}</h3>
          <p style="font-size:12px; color:#64748B;">Owner: ${escapeHtml(p.owner)} · ${escapeHtml(p.location)}</p>
        </div>
        <div style="text-align:right;">
          <span style="font-size:13px; font-weight:800; color:#D97706;">★ ${p.rating}</span>
        </div>
      </div>
      <div style="background:#F8FAFC; padding:10px 14px; border-radius:10px; border:1px solid #E2E8F0; margin-bottom:14px;">
        <div style="font-size:11px; font-weight:700; color:#64748B; margin-bottom:2px;">ACTIVE CAMPAIGN</div>
        <div style="font-size:12.5px; font-weight:700; color:#065F46;">${escapeHtml(p.activeOffer)}</div>
      </div>
      <div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; text-align:center; padding-top:8px; border-top:1px solid #E2E8F0;">
        <div>
          <div style="font-size:16px; font-weight:800; color:#0F172A;">${p.couponsIssued}</div>
          <div style="font-size:10px; color:#64748B; font-weight:700;">ISSUED</div>
        </div>
        <div>
          <div style="font-size:16px; font-weight:800; color:#065F46;">${p.couponsRedeemed}</div>
          <div style="font-size:10px; color:#64748B; font-weight:700;">REDEEMED</div>
        </div>
        <div>
          <div style="font-size:16px; font-weight:800; color:#D97706;">₹${p.totalCashbackPaid}</div>
          <div style="font-size:10px; color:#64748B; font-weight:700;">CASHBACK</div>
        </div>
      </div>
    </div>
  `).join('');
}

function renderCoupons(coupons) {
  const tbody = document.getElementById('coupons-table-body');
  if (!tbody) return;

  tbody.innerHTML = coupons.map(c => {
    let pillClass = 'pill-active';
    if (c.status === 'REDEEMED') pillClass = 'pill-redeemed';
    if (c.status === 'EXPIRED') pillClass = 'pill-expired';

    return `
      <tr>
        <td>
          <code style="background:#F1F5F9; padding:4px 8px; border-radius:6px; font-weight:800; color:#0F4C3A; border:1px solid #CBD5E1;">
            ${c.code}
          </code>
        </td>
        <td>
          <strong>${escapeHtml(c.customerName || 'Commuter')}</strong>
          <div style="font-size:11px; color:#64748B;">${c.customerPhone || ''}</div>
        </td>
        <td>
          <strong>${escapeHtml(c.merchantName || 'Annapoorna Bakery')}</strong>
          <div style="font-size:11px; color:#64748B;">${c.category || 'BAKERY'}</div>
        </td>
        <td>
          <span style="font-weight:700; color:#065F46;">₹${c.cashbackAmount || c.discountAmount || 150}</span>
          <div style="font-size:11px; color:#64748B;">Min: ₹${c.minSpend || 500}</div>
        </td>
        <td>
          <span class="status-pill ${pillClass}">● ${c.status}</span>
        </td>
        <td style="font-size:12px; color:#64748B;">
          ${c.expiresAt ? c.expiresAt.substring(0, 10) : '31 Dec 2026'}
        </td>
      </tr>
    `;
  }).join('');
}

function renderFleet(fleet) {
  const tbody = document.getElementById('fleet-table-body');
  if (!tbody) return;

  tbody.innerHTML = fleet.map(b => {
    const isGovt = b.operatorType === 'GOVERNMENT';
    return `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:8px;">
            <span style="font-size:20px;">🚌</span>
            <div>
              <strong>${escapeHtml(b.busNumber)}</strong>
              <div style="font-size:11px; color:#64748B;">${b.vehicleReg || ''}</div>
            </div>
          </div>
        </td>
        <td>
          <span class="status-pill ${isGovt ? 'pill-govt' : 'pill-pvt'}">
            ${isGovt ? '🏛️ TNSTC Govt' : '🏢 Private'}
          </span>
        </td>
        <td>
          <strong>${escapeHtml(b.routeName || b.routeId)}</strong>
          <div style="font-size:11px; color:#64748B;">${b.origin} → ${b.destination}</div>
        </td>
        <td>
          <span style="font-weight:800; color:#0F4C3A;">${b.speedKmH || 30} km/h</span>
        </td>
        <td>
          <select class="form-input" style="padding:4px 8px; font-size:11.5px; width:auto;" onchange="updateBusCrowd('${b.id}', this.value)">
            <option value="EMPTY" ${b.crowdStatus === 'EMPTY' ? 'selected' : ''}>🟢 Empty Seats</option>
            <option value="SEATS_AVAILABLE" ${b.crowdStatus === 'SEATS_AVAILABLE' ? 'selected' : ''}>🟡 Seats Available</option>
            <option value="STANDING_ONLY" ${b.crowdStatus === 'STANDING_ONLY' ? 'selected' : ''}>🟠 Standing Only</option>
            <option value="FULL" ${b.crowdStatus === 'FULL' ? 'selected' : ''}>🔴 Packed Full</option>
          </select>
        </td>
        <td>
          <span class="status-pill pill-active">
            <span class="live-pulse-dot" style="width:6px; height:6px;"></span> LIVE GPS
          </span>
        </td>
      </tr>
    `;
  }).join('');
}

function renderRedemptions(redemptions) {
  const tbody = document.getElementById('redemptions-table-body');
  if (!tbody) return;

  if (redemptions.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 24px; color: #94A3B8;">No redemptions logged yet today</td></tr>`;
    return;
  }

  tbody.innerHTML = redemptions.map(r => `
    <tr>
      <td>
        <code style="font-weight:800; color:#0F4C3A;">${r.couponCode}</code>
      </td>
      <td>
        <strong>${escapeHtml(r.customerName)}</strong>
      </td>
      <td>
        <strong>${escapeHtml(r.merchantInfo)}</strong>
      </td>
      <td>
        <span style="font-weight:800; color:#D97706;">₹${r.cashbackAmount} Cashback</span>
        <span style="font-size:11px; color:#64748B;">(Min Spend: ₹${r.minSpend})</span>
      </td>
      <td style="font-size:12px; color:#64748B;">
        ${new Date(r.redeemedAt).toLocaleString()}
      </td>
    </tr>
  `).join('');
}

// Action: Grant Points Modal
function openGrantPointsModal(userId, userName, currentPoints) {
  state.selectedCommuterId = userId;
  document.getElementById('modal-commuter-name').innerText = userName;
  document.getElementById('modal-current-points').innerText = `${currentPoints} pts`;
  document.getElementById('grant-points-amount').value = '50';
  document.getElementById('grant-points-reason').value = 'Regular Commuter Incentive (IBM Smart City Demo)';
  document.getElementById('grant-points-modal').classList.add('open');
}

function closeGrantPointsModal() {
  document.getElementById('grant-points-modal').classList.remove('open');
}

async function submitGrantPoints() {
  const delta = document.getElementById('grant-points-amount').value;
  const reason = document.getElementById('grant-points-reason').value;

  try {
    const res = await fetch(`${API_BASE}/commuters/${state.selectedCommuterId}/points`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pointsDelta: delta, reason })
    }).then(r => r.json());

    if (res.success) {
      showToast(`Granted +${delta} points to commuter!`, 'success');
      closeGrantPointsModal();
      loadAllData();
    } else {
      showToast('Error: ' + res.message, 'error');
    }
  } catch (err) {
    showToast('Failed to grant points: ' + err.message, 'error');
  }
}

// Action: Onboard Merchant Modal
function openOnboardPartnerModal() {
  document.getElementById('onboard-partner-modal').classList.add('open');
}
function closeOnboardPartnerModal() {
  document.getElementById('onboard-partner-modal').classList.remove('open');
}

async function submitOnboardPartner() {
  const name = document.getElementById('partner-name').value;
  const category = document.getElementById('partner-category').value;
  const owner = document.getElementById('partner-owner').value;
  const location = document.getElementById('partner-location').value;
  const offer = document.getElementById('partner-offer').value;

  if (!name || !owner || !location) {
    showToast('Please fill in Name, Owner, and Location', 'error');
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/partners`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, category, owner, location, activeOffer: offer })
    }).then(r => r.json());

    if (res.success) {
      showToast(`Merchant partner "${name}" registered!`, 'success');
      closeOnboardPartnerModal();
      loadAllData();
    }
  } catch (err) {
    showToast('Failed to register partner: ' + err.message, 'error');
  }
}

// Action: Issue Coupon Modal
function openIssueCouponModal() {
  document.getElementById('issue-coupon-modal').classList.add('open');
}
function closeIssueCouponModal() {
  document.getElementById('issue-coupon-modal').classList.remove('open');
}

async function submitIssueCoupon() {
  const customerName = document.getElementById('issue-customer-name').value;
  const merchantName = document.getElementById('issue-merchant-name').value;
  const cashback = document.getElementById('issue-cashback').value;
  const minSpend = document.getElementById('issue-min-spend').value;

  try {
    const res = await fetch(`${API_BASE}/coupons`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customerName, merchantName, cashbackAmount: cashback, minSpend })
    }).then(r => r.json());

    if (res.success) {
      showToast(`Coupon ${res.data.code} issued successfully!`, 'success');
      closeIssueCouponModal();
      loadAllData();
    }
  } catch (err) {
    showToast('Failed to issue coupon: ' + err.message, 'error');
  }
}

// Action: Update Bus Crowd
async function updateBusCrowd(busId, crowdStatus) {
  try {
    const res = await fetch(`${API_BASE}/fleet/${busId}/crowd`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ crowdStatus })
    }).then(r => r.json());

    if (res.success) {
      showToast(`Bus crowd updated to ${crowdStatus}`, 'success');
    }
  } catch (err) {
    showToast('Failed to update crowd: ' + err.message, 'error');
  }
}

// Action: Reset Demo
async function resetDemoData() {
  if (!confirm('Reset Trava demo state back to pristine presentation mode?')) return;

  try {
    const res = await fetch(`${API_BASE}/reset-demo`, { method: 'POST' }).then(r => r.json());
    if (res.success) {
      showToast('Demo data reset to pristine state!', 'success');
      loadAllData();
    }
  } catch (err) {
    showToast('Failed to reset demo: ' + err.message, 'error');
  }
}

function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = `<span>${type === 'error' ? '⚠️' : '✓'}</span><span>${escapeHtml(message)}</span>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>'"]/g, tag => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;'
  }[tag] || tag));
}
