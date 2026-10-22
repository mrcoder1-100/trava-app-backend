const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const apiRouter = require('./routes');
const config = require('./config');

const app = express();

// Security middleware
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' }
  })
);

app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
  })
);

// Logging
if (config.nodeEnv !== 'test') {
  app.use(morgan('dev'));
}

// JSON body parsing with support for photo check base64
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

const fs = require('fs');

// Serve Static Web Apps (Bakery, Commuter & Super Admin)
const bakeryWebDir = fs.existsSync(path.resolve(__dirname, '../../bakery-web'))
  ? path.resolve(__dirname, '../../bakery-web')
  : (fs.existsSync(path.resolve(__dirname, '../bakery-web')) ? path.resolve(__dirname, '../bakery-web') : path.resolve(__dirname, '../public'));

const websiteHtmlPath = path.join(bakeryWebDir, 'index.html');
const adminHtmlPath = path.join(bakeryWebDir, 'admin.html');
const partnerHtmlPath = path.join(bakeryWebDir, 'partner.html');

// Serve Trava Website directly at root /
app.get('/', (req, res) => {
  if (req.headers.accept && req.headers.accept.includes('text/html')) {
    if (fs.existsSync(websiteHtmlPath)) return res.sendFile(websiteHtmlPath);
    return res.sendFile(path.join(bakeryWebDir, 'index.html'));
  }
  res.json({
    app: 'Trava',
    tagline: "People Solving People's Problem.",
    subtitle: 'Know Where Your Bus Is, on Every Route.',
    status: 'ONLINE',
    city: 'Coimbatore, Tamil Nadu, India'
  });
});

// Admin Command Center Portal
app.get('/admin', (req, res) => res.sendFile(adminHtmlPath));
app.get('/admin.html', (req, res) => res.sendFile(adminHtmlPath));
app.get('/admin-portal', (req, res) => res.redirect('/admin'));

// Partner Merchant Portal
app.get('/partner', (req, res) => res.sendFile(partnerHtmlPath));
app.get('/partners', (req, res) => res.redirect('/partner'));
app.get('/partner.html', (req, res) => res.sendFile(partnerHtmlPath));

// Bakery portal alias
app.use('/bakery', express.static(bakeryWebDir));

// Serve static assets for Trava website and portals at root
app.use(express.static(bakeryWebDir));

// Static assets from project root
app.use(express.static(path.resolve(__dirname, '../')));

// Serve Trava IVR & Toll-Free Simulator at /ivr
const publicDir = path.resolve(__dirname, '../public');
app.use('/ivr', express.static(publicDir));
app.get('/ivr', (req, res) => res.sendFile(path.join(publicDir, 'ivr.html')));

app.get('/health', (req, res) => {
  res.json({ status: 'UP', timestamp: new Date().toISOString() });
});

app.use('/api/v1', apiRouter);
app.use('/api', apiRouter);

// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    error: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Centralized Error Handler
app.use((err, req, res, next) => {
  console.error('[Error Handler]', err);
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    error: err.message || 'Internal Server Error'
  });
});

module.exports = app;
