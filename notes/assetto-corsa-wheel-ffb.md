# 02b — Assetto Corsa Wheel & FFB Optimization (PXN V10 Pro)

> **Goal:** Understand your current driving skill position, optimize wheel feel for realistic driving, and provide a structured beginner→pro progression path
> **Wheel:** PXN V10 Pro (900°, H-pattern shifter, 3 pedals)

---

## 📍 Where You Stand Right Now

### Current Assists (assists.ini)

| Assist | Setting | Beginner? | Pro? |
|--------|---------|-----------|------|
| Traction Control (TC) | **OFF** | ✅ | ✅ |
| ABS | **OFF** | ✅ | ✅ |
| Stability Control | **OFF** | ✅ | ✅ |
| Auto Shifter | **OFF** (H-pattern) | ✅ | ✅ |
| Auto Clutch | **OFF** (using clutch pedal) | ✅ | ✅ |
| Auto Brake | **OFF** | ✅ | ✅ |
| Auto Blip | **OFF** | ✅ | ✅ |
| Ideal Line | **OFF** | ✅ | ✅ |
| Damage | **OFF** | ✅ (visual only) | ❌ (full damage for pro) |

> **Verdict: ALL assists are already off.** You're already at ~85-90% of the way to full pro settings.

### Current Wheel Settings (controls.ini → PXN V10 Proj-amar.ini)

| Setting | Your Value | What It Means |
|---------|-----------|---------------|
| **FF_GAIN** | **0.8 (80%)** | ✅ Good — below clipping threshold, clean detail |
| **Steer Lock** | 900° | Default — realistic for road cars |
| **Steer Gamma** | 1.0 (linear) | ✅ Good — predictable steering response |
| **Speed Sensitivity** | 0 | ✅ Good — no artificial speed-sensitive steering |
| **Brake Gamma** | **1.0 (linear)** | ✅ Linear — consistent, predictable braking |
| **FF Enhance: CURBS** | **0.10 (10%)** | 🟡 Moderate — feel kerbs clearly but not overwhelming |
| **FF Enhance: ROAD** | **0.10 (10%)** | 🟡 Moderate — feel surface changes without drowning out grip |
| **FF Enhance: SLIPS** | **0.08 (8%)** | 🟡 Light — wheel vibrates on tire spin, still lets natural FFB through |
| **FF Enhance: ABS** | **0.10 (10%)** | 🟡 Moderate — lockup warning buzz while learning threshold braking |
| **FF_SKIP_STEPS** | **1** | 🟡 Good balance — smooth with slight detail loss |
| **MIN_FF** | **0.02 (2%)** | ✅ Good — light center feel so wheel isn't dead on straights |
| **Center Boost** | **0** | ✅ Good — no artificial centering |
| **FF Post-Process** | **Disabled** | 🟡 LUT not applied — could improve FFB feel |

---

## 📊 Beginner ↔ Pro Spectrum

```
  Beginner ───────────────────────────────────────────► Pro
  
  YOU ARE HERE → ●
  
  Assists:      ALL OFF ────┬─── you already crossed this bridge
  Shifter:      Auto ──► Paddle ──► H-pattern ──► you're here (H-pattern + clutch)
  Brake Gamma:  3.0 ──► 2.4 ──► 1.5 ──► 1.0 (linear)
  FFB Gain:     0.5 ──► 0.7 ──► 0.85 ──► 0.75 (optimal for your wheel)
  FFB Enhance:  High ──► Medium ──► Low ──► Minimal
  Damage:       OFF ──► Visual ──► Full ──► you could go further
```

### Why you're further along than you think

1. **H-pattern shifter + clutch pedal** = most beginners avoid this. You're already doing the hardest input method.
2. **All assists off** = you're already learning throttle control (no TC) and brake modulation (no ABS).
3. **No speed sensitivity, no center boost** = you're getting raw, unfiltered feedback.

Areas that still have room for improvement:
- FFB gain at 100% is **too high** — clipping loses detail (see below)
- Brake gamma can go linear for better consistency
- FFB enhancements can be lowered for more authentic feel
- Damage can be enabled for full realism

---

## 🔧 What "FFB Clipping" Means & Why It Matters

Your FF_GAIN is set to **1.0 (100%)**. This seems like it would give the strongest feedback, but in reality:

- Your PXN V10 Pro has a maximum force it can output
- When the game asks for more force than the wheel can deliver, the signal **clips** — essentially, the peaks get cut off
- This means **you lose detail**: you can't feel the difference between a slight slide and a major loss of grip
- The wheel just feels "vibrating loudly" rather than providing nuanced information about tire grip

**Recommended:** Lower FF_GAIN to **0.70–0.80** (70-80%). You'll actually feel MORE detail because nothing is clipping.

---

## 🎮 PXN V10 Pro Button Mapping (Your Current Setup)

| Wheel Button | Action | Notes |
|-------------|--------|-------|
| Paddle Right | Gear Up | Button 5 |
| Paddle Left | Gear Down | Button 4 |
| Button 0 | Headlights | |
| Button 1 | Headlights Flash | |
| Button 2 | Handbrake | For drifting |
| Button 3 | Horn | |
| Button 10 | Look Back | |
| Button 11 | Change Camera | |
| H-pattern | G1-G6, R | Gears 16-23 signals |
| Throttle | Axle 2 | |
| Brake | Axle 5 | Gamma 2.4 (nonlinear) |
| Clutch | Axle 6 | Gamma 1.0 (linear) |

### Missing button mappings you might want:

| Missing | Suggested Button | Why |
|---------|-----------------|-----|
| TC Adjust +/- | Unused button | Adjust TC on-the-fly per corner |
| ABS Adjust +/- | Unused button | Adjust ABS mid-race |
| Pit Limiter | Unused button | Useful in online races |
| Flash Headlights | Already mapped (Btn 1) | ✅ |
| Cycle Camera | Already mapped (Btn 11) | ✅ |

---

## 🏁 The 3-Stage Progression Plan

### Stage 1: Beginner Comfort (Assists ON)

**When to use:** Learning tracks, learning car behavior, building muscle memory
**Goal:** Get comfortable without crashing, understand the basics of racing lines

#### assists.ini
```
IDEAL_LINE=1         → ON (racing line helps learn tracks)
AUTO_BLIP=1          → ON (rev-matching automated)
STABILITY_CONTROL=1  → ON (saves you from spins)
AUTO_BRAKE=0         → OFF (you need to learn braking)
AUTO_SHIFTER=1       → ON (focus on steering & braking first)
ABS=1                → ON (forgives brake lockup)
TRACTION_CONTROL=1   → ON (forgives too much throttle)
AUTO_CLUTCH=1        → ON (one less thing to think about)
```

#### Wheel (Beginner)
```
FF_GAIN=0.60         → Lower to avoid surprises
BRAKE_GAMMA=2.4      → Nonlinear, easier to trail-brake gently
FF_ENHANCE_CURBS=0.5 → Higher = more noticeable curb feel
FF_ENHANCE_ROAD=0.5  → Higher = more road texture feel
FF_SKIP_STEPS=2      → Smoother, less noisy
MIN_FF=0.10          → Higher = always feel something
```

---

### Stage 2: Intermediate (Building Consistency)

**When to move here:** You can consistently keep the car on track at Stage 1
**Goal:** Learn manual shifting, start removing assists one at a time

#### assists.ini
```
IDEAL_LINE=1         → Only on tracks you don't know
AUTO_BLIP=1          → Keep for now (heel-toe is hard)
STABILITY_CONTROL=0  → OFF (learn to catch slides)
AUTO_SHIFTER=0       → OFF (use paddles or H-pattern)
ABS=1                → Keep for now
TRACTION_CONTROL=3   → Low setting
AUTO_CLUTCH=0        → OFF (use clutch pedal)
```

#### Wheel (Intermediate)
```
FF_GAIN=0.75         → Increased for more feel
BRAKE_GAMMA=1.5      → More linear, more precise
FF_ENHANCE_CURBS=0.3 → Reduced
FF_ENHANCE_ROAD=0.3  → Reduced
FF_ENHANCE_ABS=0.15  → Reduced
FF_SKIP_STEPS=1      → More detail, still smooth
MIN_FF=0.05          → Lower minimum
```

---

### Stage 3: Pro / Maximum Realism (Current + Optimized)

**When to move here:** You can complete 10 clean laps consistently, catching slides by feel
**Goal:** Maximum realism, no artificial help, raw FFB with no clipping

#### assists.ini (same as your current!)
```
IDEAL_LINE=0         → OFF
AUTO_BLIP=0          → OFF (learn heel-toe / auto-blip manually)
STABILITY_CONTROL=0  → OFF
AUTO_BRAKE=0         → OFF
AUTO_SHIFTER=0       → OFF
ABS=0                → OFF (learn brake threshold)
TRACTION_CONTROL=0   → OFF (learn throttle control)
AUTO_CLUTCH=0        → OFF
DAMAGE=1             → ON (full damage for realism)
TYRE_WEAR=1          → ON
TYRE_BLANKETS=1      → ON
```

#### Wheel (Pro Optimized)
```
FF_GAIN=0.75         → Optimal for PXN V10 Pro — no clipping, max detail
BRAKE_GAMMA=1.0      → LINEAR — consistent, predictable braking
FF_ENHANCE_CURBS=0.10→ Minimal (you'll feel real curbs through the wheel)
FF_ENHANCE_ROAD=0.10 → Minimal (real road feel comes through)
FF_ENHANCE_SLIPS=0   → OFF (let the game's natural FFB show slips)
FF_ENHANCE_ABS=0     → OFF (you're braking without ABS, no need)
FF_SKIP_STEPS=0      → Full detail (your wheel can handle it)
MIN_FF=0.02          → Lower minimum for more dynamic range
CENTER_BOOST_GAIN=0  → OFF (no artificial centering)
STEER_FILTER=0       → No smoothing
```

---

## ✅ Changes Applied (01 Jul 2026)

All recommended first-step changes have been applied and verified:

| Change | Before | After | Delta |
|--------|--------|-------|-------|
| **FFB Gain** | 100% (clipping) | **80%** | ✅ Clipping eliminated |
| **Brake Gamma** | 2.4 (nonlinear) | **1.0 (linear)** | ✅ Consistent braking |
| **CURBS** | 0.40 (40%) | **0.10 (10%)** | ✅ Cleaner feel |
| **ROAD** | 0.50 (50%) | **0.10 (10%)** | ✅ Cleaner feel |
| **SLIPS** | 0.12 (12%) | **0.08 (8%)** | ✅ More natural |
| **ABS** | 0.11 (11%) | **0.10 (10%)** | ✅ Fine-tuned |
| **FF_SKIP_STEPS** | 2 | **1** | ✅ More detail |
| **MIN_FF** | 0 (dead center) | **0.02 (2%)** | ✅ Light center feel |

### 📁 Live configs synced to repo
- `Assetto Corsa Settings/Documents_Assetto_Corsa_cfg/controls.ini` ← your current wheel settings
- `Assetto Corsa Settings/Documents_Assetto_Corsa_cfg/assists.ini` ← your current assist settings

---

## 📁 Preset Config Files

The following presets are available in `Assetto Corsa Settings/CM_Presets/`:

| File | Stage | Setting |
|------|-------|---------|
| `Wheel_Beginner.ini` | 1 | Assists ON, soft FFB, easier braking |
| `Wheel_Pro.ini` | 3 | No assists, optimized FFB, linear braking |

### How to apply a preset:
1. Close Content Manager
2. Copy the preset file to `%USERPROFILE%\Documents\Assetto Corsa\cfg\controls.ini` (for wheel) and `assists.ini` (for assists)
3. Launch Content Manager
4. The settings will be loaded automatically

Or import through CM:
- **Controls:** Settings → Controls → Presets → Load
- **Assists:** Settings → Assetto Corsa → Assists

---

## 🔍 Summary

| Aspect | Your Current | Pro Target | Impact |
|--------|-------------|------------|--------|
| **Assists** | ALL OFF ✅ | ALL OFF | You're already here |
| **FFB Gain** | **80%** ✅ | 75% | Close — no clipping, clean detail |
| **Brake Gamma** | **1.0 (linear)** ✅ | 1.0 (linear) | Done — consistent braking |
| **CURBS** | **10%** 🟡 | 3-5% | Fine for learning — feels kerbs clearly |
| **ROAD** | **10%** 🟡 | 3-5% | Fine for learning — feels surface changes |
| **SLIPS** | **8%** 🟡 | 0-5% | Fine for learning — tire spin warning |
| **ABS** | **10%** 🟡 | 0% (no ABS) | Fine for learning — lockup warning |
| **Shifter** | H-pattern + clutch ✅ | H-pattern + clutch | Already pro-level input |
| **Damage** | Visual only 🟡 | **Full** | Small remaining step |
| **FF Skip Steps** | **1** ✅ | 0 | Close — good balance |

> **Bottom line:** You're already driving at ~85% pro level in terms of skill (no assists, manual H-pattern, clutch). The remaining 15% is optimizing your FFB and brake settings to get cleaner, more detailed feedback — not adding difficulty, just improving the quality of information you receive from the wheel.
