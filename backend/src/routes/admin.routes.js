const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');

// Dedicated Super Admin Authentication
router.post('/login', adminController.adminLogin);

// Executive Overview
router.get('/overview', adminController.getOverview);

// Commuter / User Management (CRUD)
router.get('/commuters', adminController.getCommuters);
router.get('/commuters/:id/rides', adminController.getCommuterRides);
router.post('/commuters', adminController.createCommuter);
router.put('/commuters/:id', adminController.updateCommuter);
router.delete('/commuters/:id', adminController.deleteCommuter);
router.post('/commuters/:id/points', adminController.updateCommuterPoints);

// Partner / Merchant Management (CRUD)
router.get('/partners', adminController.getPartners);
router.post('/partners', adminController.createPartner);
router.put('/partners/:id', adminController.updatePartner);
router.delete('/partners/:id', adminController.deletePartner);

// Coupons & Offers Management
router.get('/coupons', adminController.getCoupons);
router.post('/coupons', adminController.issueCoupon);

// Redemption Audit Log
router.get('/redemptions', adminController.getRedemptions);

// Fleet & Operations Control
router.get('/fleet', adminController.getFleet);
router.post('/fleet/:busId/crowd', adminController.updateBusCrowd);

// Reset Demo State
router.post('/reset-demo', adminController.resetDemo);

module.exports = router;
