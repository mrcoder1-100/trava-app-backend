# Trava — Vision AI Integration & Mock Fallback Specification

Trava incorporates camera verification to ensure that passenger GPS contributions originate from commuters actively travelling on public transit.

---

## 1. Core Principles

1. **Modular Architecture**: Vision processing is exclusively contained on the backend. No secret keys or heavy inference runtimes exist on the Flutter client.
2. **Deterministic Mock Fallback**: When no Vision API key is supplied, Trava runs a clearly labelled mock verification mode (`DEMO MODE · MOCK VERIFICATION`).
3. **No False Claims**: Trava never claims that AI analysis occurred when mock verification was utilized.
4. **Resilience**: Basic bus tracking, dynamic ETA calculation, points awarding, and coupon validation are decoupled from external vision APIs and never fail due to vision timeouts or quotas.

---

## 2. Verification Architecture

```
+-------------------------------------------------------------------+
|                        FLUTTER CLIENT                             |
|  - Live Viewfinder Simulation with Guide Bounds                   |
|  - Fresh Camera Snapshot Capture                                  |
|  - Encodes image (Base64 JPEG)                                    |
+---------------------------------+---------------------------------+
                                  |
               POST /api/v1/verification/submit
                                  |
                                  v
+-------------------------------------------------------------------+
|                     NODE.JS BACKEND SERVICE                       |
|  Does process.env.VISION_API_KEY exist?                           |
|       /                                  \                        |
|   [ YES ]                                [ NO ]                   |
|      v                                      v                     |
|  Call IBM watsonx.ai Vision /          Activate Mock Verification |
|  Google Cloud Vision Endpoint           Mode with explicit badge   |
|  - Classify: bus interior / seats      - Status: VERIFIED         |
|  - Validate confidence > 0.85          - Mode: DEMO_MOCK          |
|  - Return verification token           - Badge: DEMO MODE         |
+---------------------------------+---------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                 VERIFICATION RECORD STORED                        |
|  - Saved in verification_records.json                             |
|  - Journey begins with verified contributor status                |
+-------------------------------------------------------------------+
```

---

## 3. Configuration

To configure a production Vision API:
```env
# In backend/.env
VISION_API_KEY=your_vision_api_key_here
```

When left empty, Trava logs:
`[VerificationService] No VISION_API_KEY detected. Running in DEMO_MOCK_VERIFICATION mode.`
