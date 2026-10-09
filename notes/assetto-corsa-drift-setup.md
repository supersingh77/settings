# 07 — Assetto Corsa Drifting Setup (PXN V10 Pro)

> Per-user config at `%USERPROFILE%\Documents\Assetto Corsa\cfg\`

---

## Hardware Detected

| Device | VID:PID | Status |
|--------|---------|--------|
| **PXN V10 Pro** | VID_36E6, PID_400B | ✅ Configured in AC |
| 6-Speed H-Shifter | On wheel (buttons 16-23) | ✅ Active |
| Paddle Shifters | Button 5 (up) / Button 4 (down) | ✅ Active |
| Handbrake | Button 2 | ✅ Active |

### Current Button Map

| Control | Assignment |
|---------|-----------|
| Steering | AXLE 0 (900°) |
| Throttle | AXLE 2 |
| Brakes | AXLE 5 (Gamma 2.4) |
| Clutch | AXLE 6 |
| Paddle Up | Button 5 |
| Paddle Down | Button 4 |
| Handbrake | Button 2 |
| H-Shifter Gear 1-6 | Buttons 16-21 |
| Reverse | Button 23 |
| Headlights | Button 0 |
| Headlights Flash | Button 1 |
| Horn | Button 3 |
| Change Camera | Button 11 |
| Look Back | Button 10 |

---

## Applied Drift-Optimized Assists (assists.ini)

| Setting | Before | After | Why |
|---------|--------|-------|-----|
| STABILITY_CONTROL | 100 (MAX) | **0 (OFF)** | Kills ALL drift — must be off |
| AUTO_CLUTCH | ON | **OFF** | Need clutch for clutch-kicks & feints |
| AUTO_SHIFTER | ON | **OFF** | Manual control for drift gear selection |
| AUTO_BLIP | ON | **OFF** | Control rev-matching yourself |
| TRACTION_CONTROL | Factory (2) | **0 (OFF)** | Need wheelspin to slide |
| ABS | Factory (2) | **1 (ON)** | Keeps brakes from locking while learning |
| IDEAL_LINE | ON | **0 (OFF)** | No racing line |
| TYRE_WEAR | ON | ON | Realistic tire deg |

---

## Applied FFB Improvements (controls.ini)

| Setting | Before | After | Why |
|---------|--------|-------|-----|
| MIN_FF | 0.05 | **0.10** | Stronger minimum force — feel wheel when grip is low |
| SLIPS | 0 | **0.3** | ⭐ Critical for drift — feel when rear end slides |
| ROAD | 0.5 | 0.5 | Road surface feel (keep) |
| CURBS | 0.4 | 0.4 | Curb feedback (keep) |
| CENTER_BOOST | 0 | 0 | No artificial center spring (interferes with drifting) |

---

## Learning Drift Progression

### Phase 1 — Beginner (you are here)
1. **Car**: Toyota AE86 Drift Tuned (kunos) or BMW E30 Drift
2. **Track**: Magione or drift lot
3. **Goal**: Hold a slide, don't spin out
4. **Technique**: Clutch kick → steer into corner → countersteer → feather throttle
5. **ABS**: Leave ON (one less thing to worry about)

### Phase 2 — Linking
1. **Car**: Same or Nissan 180SX
2. **Track**: Any track with 2-3 consecutive corners
3. **Goal**: Transition from one slide into the next
4. **Technique**: Left foot brake / clutch kick to transfer weight

### Phase 3 — No ABS
1. Turn ABS to 0
2. Learn threshold braking while drifting
3. More delicate pedal control needed

---

## Quick Tips

- **900° rotation** is good for drift (more steering angle = more control)
- **Brake Gamma 2.4** means brakes are less sensitive at the top — good for preventing lockups
- Try **540° rotation** if you want quicker steering response (change LOCK=540 in controls.ini)
- For tandems (multiplayer drift): turn TYRE_WEAR to 0 so tires don't degrade mid-session
- Keep TYRE_BLANKETS=1 so tires start warm

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Spinning out immediately | Less throttle, earlier countersteer |
| Can't initiate slide | More speed + clutch kick |
| Car snaps around | Smoother throttle release |
| Understeer / won't slide | Less front grip (more tire pressure or softer front suspension) |
