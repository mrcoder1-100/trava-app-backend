const db = require('../repositories/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');

/**
 * Dedicated Trava Super Admin Authentication
 */
function adminLogin(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Admin email and password are required' });
    }

    const cleanEmail = email.toLowerCase().trim();
    const user = db.findOne('users', u => u.email.toLowerCase() === cleanEmail && u.role === 'SUPER_ADMIN');

    // Built-in check for dedicated Trava Admin account
    const isDirectMatch = (cleanEmail === 'trava.admin@trava.org' || cleanEmail === 'admin@trava.org') && password === 'TravaAdmin@2026';
    const isUserMatch = user && bcrypt.compareSync(password, user.passwordHash);

    if (!isDirectMatch && !isUserMatch) {
      return res.status(401).json({ success: false, message: 'Invalid Admin credentials' });
    }

    const adminProfile = user || {
      id: 'usr_trava_super_admin',
      fullName: 'Trava Operations Lead',
      email: 'trava.admin@trava.org',
      role: 'SUPER_ADMIN',
      phone: '+91 98420 12345'
    };

    const token = jwt.sign(
      { id: adminProfile.id, email: adminProfile.email, role: 'SUPER_ADMIN' },
      config.jwtSecret || 'trava_jwt_secret_coimbatore_2026',
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Trava Super Admin session authenticated successfully',
      data: {
        token,
        admin: {
          id: adminProfile.id,
          fullName: adminProfile.fullName,
          email: adminProfile.email,
          role: adminProfile.role
        }
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Executive Overview KPI Metrics
 */
function getOverview(req, res) {
  try {
    const users = db.getCollection('users').filter(u => u.role !== 'SUPER_ADMIN');
    const partners = db.getCollection('partners');
    const coupons = db.getCollection('coupons');
    const redemptions = db.getCollection('redemptions');
    const buses = db.getCollection('bus_services');
    const routes = db.getCollection('routes');
    const crowdReports = db.getCollection('crowd_reports');

    const totalPointsAwarded = users.reduce((sum, u) => sum + (u.pointsBalance || 0), 0);
    const activeCoupons = coupons.filter(c => c.status === 'ACTIVE').length;
    const redeemedCoupons = coupons.filter(c => c.status === 'REDEEMED').length;
    const totalCashbackValue = redemptions.reduce((sum, r) => {
      const coup = coupons.find(c => c.code === r.couponCode || c.id === r.couponId);
      return sum + (coup ? (coup.cashbackAmount || coup.discountAmount || 0) : 150);
    }, 0);

    res.json({
      success: true,
      data: {
        commutersCount: users.length,
        partnersCount: partners.length,
        busesCount: buses.length,
        routesCount: routes.length,
        totalPointsAwarded,
        activeCouponsCount: activeCoupons,
        redeemedCouponsCount: redeemedCoupons,
        totalCashbackDistributed: totalCashbackValue,
        crowdReportsCount: crowdReports.length,
        timestamp: new Date().toISOString()
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Commuters Management: List All
 */
function getCommuters(req, res) {
  try {
    const users = db.getCollection('users').filter(u => u.role !== 'SUPER_ADMIN');
    const coupons = db.getCollection('coupons');
    const journeys = db.getCollection('journeys');

    const result = users.map(u => {
      const userCoupons = coupons.filter(c => c.userId === u.id || (u.email && c.customerName && c.customerName.toLowerCase().includes(u.fullName.toLowerCase())));
      const userJourneys = journeys.filter(j => j.userId === u.id);
      return {
        id: u.id,
        fullName: u.fullName || 'Commuter',
        email: u.email || 'commuter@trava.org',
        phone: u.phone || '+91 98421 10095',
        role: u.role || 'PASSENGER',
        pointsBalance: u.pointsBalance ?? 50,
        isDemoAccount: !!u.isDemoAccount,
        couponsCount: userCoupons.length,
        activeCoupons: userCoupons.filter(c => c.status === 'ACTIVE').length,
        journeysCount: userJourneys.length,
        recentRides: userJourneys,
        createdAt: u.createdAt
      };
    });

    res.json({ success: true, count: result.length, data: result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Commuter Ride History: Get rides for specific commuter
 */
function getCommuterRides(req, res) {
  try {
    const { id } = req.params;
    const journeys = db.getCollection('journeys');
    const userRides = journeys.filter(j => j.userId === id);
    res.json({ success: true, count: userRides.length, data: userRides });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Commuters Management: Create New Commuter
 */
function createCommuter(req, res) {
  try {
    const { fullName, email, phone, role, pointsBalance } = req.body;
    if (!fullName || !email) {
      return res.status(400).json({ success: false, message: 'Name and Email are required' });
    }

    const existing = db.findOne('users', u => u.email.toLowerCase() === email.toLowerCase());
    if (existing) {
      return res.status(409).json({ success: false, message: 'A user with this email already exists' });
    }

    const newUser = {
      id: `usr_${uuidv4().substring(0, 8)}`,
      fullName,
      email,
      phone: phone || '+91 98421 00000',
      passwordHash: bcrypt.hashSync('Password123!', 10),
      role: role || 'PASSENGER',
      pointsBalance: parseInt(pointsBalance || 50, 10),
      isDemoAccount: false,
      createdAt: new Date().toISOString()
    };

    db.create('users', newUser);

    res.status(201).json({
      success: true,
      message: `Commuter ${fullName} created successfully`,
      data: newUser
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Commuters Management: Update / Edit Commuter
 */
function updateCommuter(req, res) {
  try {
    const { id } = req.params;
    const { fullName, email, phone, role, pointsBalance } = req.body;

    const user = db.findById('users', id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Commuter not found' });
    }

    const updates = {};
    if (fullName !== undefined) updates.fullName = fullName;
    if (email !== undefined) updates.email = email;
    if (phone !== undefined) updates.phone = phone;
    if (role !== undefined) updates.role = role;
    if (pointsBalance !== undefined) updates.pointsBalance = parseInt(pointsBalance, 10);

    const updated = db.update('users', id, updates);

    res.json({
      success: true,
      message: `Commuter ${updated.fullName} updated successfully`,
      data: updated
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Commuters Management: Delete Commuter
 */
function deleteCommuter(req, res) {
  try {
    const { id } = req.params;
    const user = db.findById('users', id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Commuter not found' });
    }

    if (user.role === 'SUPER_ADMIN') {
      return res.status(403).json({ success: false, message: 'Cannot delete Super Admin account' });
    }

    db.delete('users', id);

    res.json({
      success: true,
      message: `Commuter ${user.fullName} deleted successfully`,
      data: { id }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Adjust or Grant Bonus Reward Points to Commuter
 */
function updateCommuterPoints(req, res) {
  try {
    const { id } = req.params;
    const { pointsDelta, reason } = req.body;

    const user = db.findById('users', id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Commuter not found' });
    }

    const currentPoints = user.pointsBalance || 0;
    const newPoints = Math.max(0, currentPoints + parseInt(pointsDelta || 0, 10));

    db.update('users', id, {
      pointsBalance: newPoints,
      lastPointsAwardReason: reason || 'Admin Incentive',
      lastPointsAwardAt: new Date().toISOString()
    });

    res.json({
      success: true,
      message: `Points updated successfully for ${user.fullName}`,
      data: { id, fullName: user.fullName, previousPoints: currentPoints, newPoints }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Partners & Merchant Directory: List All
 */
function getPartners(req, res) {
  try {
    const partners = db.getCollection('partners');
    res.json({ success: true, count: partners.length, data: partners });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Onboard / Register New Partner Merchant
 */
function createPartner(req, res) {
  try {
    const { name, category, owner, location, phone, activeOffer } = req.body;
    if (!name || !owner || !location) {
      return res.status(400).json({ success: false, message: 'Name, owner, and location are required' });
    }

    const newPartner = {
      id: `partner_${uuidv4().substring(0, 8)}`,
      name,
      category: (category || 'RETAIL').toUpperCase(),
      owner,
      location,
      phone: phone || '+91 98420 00000',
      status: 'VERIFIED_ACTIVE',
      rating: 5.0,
      activeOffer: activeOffer || '10% Cashback for Trava Commuters',
      couponsIssued: 0,
      couponsRedeemed: 0,
      totalCashbackPaid: 0,
      createdAt: new Date().toISOString()
    };

    db.create('partners', newPartner);

    res.status(201).json({
      success: true,
      message: `Merchant partner ${name} registered successfully`,
      data: newPartner
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Edit / Update Existing Partner Merchant
 */
function updatePartner(req, res) {
  try {
    const { id } = req.params;
    const { name, category, owner, location, phone, activeOffer, rating } = req.body;

    const partner = db.findById('partners', id);
    if (!partner) {
      return res.status(404).json({ success: false, message: 'Partner merchant not found' });
    }

    const updates = {};
    if (name !== undefined) updates.name = name;
    if (category !== undefined) updates.category = category.toUpperCase();
    if (owner !== undefined) updates.owner = owner;
    if (location !== undefined) updates.location = location;
    if (phone !== undefined) updates.phone = phone;
    if (activeOffer !== undefined) updates.activeOffer = activeOffer;
    if (rating !== undefined) updates.rating = parseFloat(rating);

    const updated = db.update('partners', id, updates);

    res.json({
      success: true,
      message: `Partner ${updated.name} updated successfully`,
      data: updated
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Delete Partner Merchant
 */
function deletePartner(req, res) {
  try {
    const { id } = req.params;
    const partner = db.findById('partners', id);
    if (!partner) {
      return res.status(404).json({ success: false, message: 'Partner merchant not found' });
    }

    db.delete('partners', id);

    res.json({
      success: true,
      message: `Merchant partner ${partner.name} deleted successfully`,
      data: { id }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * All Coupons across system
 */
function getCoupons(req, res) {
  try {
    const coupons = db.getCollection('coupons');
    res.json({ success: true, count: coupons.length, data: coupons });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Issue / Assign a new coupon directly from Admin console
 */
function issueCoupon(req, res) {
  try {
    const { customerName, customerPhone, merchantName, offerTitle, cashbackAmount, minSpend, category } = req.body;

    const code = `TRAVA-${(category || 'BAKE').substring(0, 4).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const newCoupon = {
      id: `coup_adm_${uuidv4().substring(0, 8)}`,
      code,
      userId: 'usr_demo_coimbatore_01',
      customerName: customerName || 'Trava Passenger',
      customerPhone: customerPhone || '+91 98421 99999',
      category: (category || 'BAKERY').toUpperCase(),
      title: merchantName || 'Annapoorna Bakery & Sweets',
      description: offerTitle || `Buy above ₹${minSpend || 500}, Get ₹${cashbackAmount || 150} Cashback`,
      offerDetails: offerTitle || `Buy above ₹${minSpend || 500}, Get ₹${cashbackAmount || 150} Cashback`,
      minSpend: parseInt(minSpend || 500, 10),
      cashbackAmount: parseInt(cashbackAmount || 150, 10),
      discountAmount: parseInt(cashbackAmount || 150, 10),
      merchantName: merchantName || 'Annapoorna Bakery & Sweets',
      location: 'Gandhipuram Central, Coimbatore',
      status: 'ACTIVE',
      assignedAt: new Date().toISOString(),
      expiresAt: '2026-12-31T23:59:59Z',
      isGuaranteedReward: true
    };

    db.create('coupons', newCoupon);

    res.status(201).json({
      success: true,
      message: `Coupon ${code} successfully issued to ${newCoupon.customerName}`,
      data: newCoupon
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Redemption Audit Trail Log
 */
function getRedemptions(req, res) {
  try {
    const redemptions = db.getCollection('redemptions');
    const coupons = db.getCollection('coupons');

    const result = redemptions.map(r => {
      const coup = coupons.find(c => c.code === r.couponCode || c.id === r.couponId);
      return {
        id: r.id,
        couponCode: r.couponCode,
        customerName: coup ? coup.customerName : 'Commuter',
        merchantInfo: r.merchantInfo || (coup ? coup.merchantName : 'Partner Counter'),
        cashbackAmount: coup ? (coup.cashbackAmount || coup.discountAmount || 150) : 150,
        minSpend: coup ? (coup.minSpend || 500) : 500,
        redeemedAt: r.redeemedAt || r.createdAt
      };
    });

    res.json({ success: true, count: result.length, data: result.reverse() });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Fleet & Transit Operations
 */
function getFleet(req, res) {
  try {
    const buses = db.getCollection('bus_services');
    const routes = db.getCollection('routes');

    const result = buses.map(b => {
      const route = routes.find(r => r.id === b.routeId);
      return {
        ...b,
        routeName: route ? route.name : b.routeId,
        routeCode: route ? route.shortCode : '95',
        origin: route ? route.originName : 'Gandhipuram',
        destination: route ? route.destinationName : 'Singanallur'
      };
    });

    res.json({ success: true, count: result.length, data: result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Update Bus Crowd Status from Admin Console
 */
function updateBusCrowd(req, res) {
  try {
    const { busId } = req.params;
    const { crowdStatus } = req.body;

    const bus = db.findById('bus_services', busId);
    if (!bus) {
      return res.status(404).json({ success: false, message: 'Bus not found' });
    }

    const updated = db.update('bus_services', busId, {
      crowdStatus: crowdStatus || 'SEATS_AVAILABLE',
      lastUpdated: new Date().toISOString()
    });

    res.json({
      success: true,
      message: `Bus ${bus.busNumber} crowd updated to ${crowdStatus}`,
      data: updated
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Reset Demo Data to Pristine State
 */
function resetDemo(req, res) {
  try {
    const coupons = db.getCollection('coupons');
    coupons.forEach(c => {
      if (c.code === 'TRAVA-BAKE-95A1') {
        c.status = 'ACTIVE';
        delete c.redeemedAt;
        delete c.redeemedByMerchant;
      }
    });
    db.persistCollection('coupons');

    res.json({
      success: true,
      message: 'Demo state reset successfully. Platform data synchronized.'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

module.exports = {
  adminLogin,
  getOverview,
  getCommuters,
  getCommuterRides,
  createCommuter,
  updateCommuter,
  deleteCommuter,
  updateCommuterPoints,
  getPartners,
  createPartner,
  updatePartner,
  deletePartner,
  getCoupons,
  issueCoupon,
  getRedemptions,
  getFleet,
  updateBusCrowd,
  resetDemo
};
