# Mobile App UI/UX Handoff Document

**App name (internal):** Voice Calling App / `flutter_voice_calling_app_2026`  
**Platform:** Android (Flutter)  
**Business model:** Coin-based voice/video calling — users buy coins, spend per minute on calls with listeners/creators.

Use this document for UI/UX audit, redesign, and Figma planning.

---

## 1. App navigation map

```
App Launch
    │
    ├─ Loading spinner (session restore)
    │
    ├─ NOT logged in ──► Login (phone)
    │                        └─► OTP (6 digits)
    │                                ├─► Create Profile (onboarding)
    │                                └─► Home
    │
    ├─ Logged in, no profile ──► Create Profile
    │                                └─► Language Selection (optional step)
    │
    └─ Logged in + onboarded ──► Home (tab shell)
            │
            ├─ [Regular user: 3 tabs]
            │     Home | Wallet | Profile
            │
            └─ [Listener: 5 tabs]
                  Home | Calls | Wallet | Listener Dashboard | Profile

Modal / pushed screens (from anywhere):
    • Coin Recharge (full screen OR wallet tab)
    • Calling (active call)
    • Incoming Call (overlay)
    • Call Details
    • Listener Application
    • Agora Debug (dev only, from Profile)
    • Language Selection
```

---

## 2. Design system (current state)

### 2.1 Two visual themes (inconsistent)

| Theme | Used on | Background | Accent |
|--------|---------|------------|--------|
| **Dark** | Login, OTP, Create Profile, Profile tab, Listener Dashboard, Calls, Incoming/Active call | `#080E1A` | Purple `#BA9EFF` / `#8455EF` |
| **Light** | Home tab, Wallet/Recharge | `#F8F8F8` / white cards | Hot pink `#FF1493` / `#FF4DA6` |

**UX note:** Auth flow feels like a different product than Home/Recharge. A unified design system is recommended.

### 2.2 Color palette reference

| Token | Hex | Usage |
|--------|-----|--------|
| Surface dark | `#080E1A` | Auth, profile, calls |
| Surface card dark | `#1E2637`, `#131A28`, `#0D1320` | Cards, nav bar (dark mode) |
| Primary purple | `#BA9EFF` | Auth buttons, listener UI |
| Primary purple dim | `#8455EF` | Gradients |
| Hot pink | `#FF1493` | Home header, wallet pill, CTAs, Razorpay theme |
| Pink gradient end | `#FF4DA6` | Buttons, avatar rings |
| Voice CTA gradient | `#C85CFF` → `#8A2BE2` | Call buttons on cards |
| Success green | `#2ECC71` | Online status, earnings |
| Text dark | `#333333` | Light screens headings |
| Text muted | `#777777`, `#707584`, `#A6ABBB` | Subtitles |
| Text on dark | `#E0E5F6` | Auth screens |
| Error | `#FF8A8A` | Form errors |
| Coin gold | `Colors.amber` | Coin icon circles |

### 2.3 Typography

| Font | Where |
|------|--------|
| **Poppins** (Google Fonts) | Home, Recharge, Calls, Profile, Listener — primary UI font |
| **Manrope** | Login headline + phone input |
| **Inter** | Login subtitle |

**UX note:** No global `ThemeData` typography — fonts are set per widget. `main.dart` only sets `primarySwatch: Colors.blue` (mostly unused).

### 2.4 Shared components (duplicated in code)

| Component | Description | Files |
|-----------|-------------|--------|
| `ScalePressedButton` | Tap scale animation | `home_screen`, `recharge_screen`, `listener_dashboard` |
| `PulsingOnlineDot` | Green pulse on avatar | `home_screen` |
| `CallHistoryCard` | Dark card for call rows | `widgets/call_history_card.dart` |
| Coin wallet pill | Pink gradient capsule + amber "H" + balance | Home header, Recharge app bar |

### 2.5 Spacing & shapes

- Card corner radius: **20–24px**
- Bottom nav top radius: **30px**
- Bottom nav height: **90px**
- Header height: **90px**
- Package grid: **2 columns**, aspect ratio **0.85**
- Standard horizontal padding: **20–24px**

---

## 3. Screen-by-screen inventory

### 3.1 Splash / bootstrap

| Item | Detail |
|------|--------|
| **File** | `lib/main.dart` |
| **UI** | White scaffold, centered `CircularProgressIndicator` |
| **Duration** | Until Firebase session + JWT restore |

---

### 3.2 Login

| Item | Detail |
|------|--------|
| **File** | `lib/screens/login_screen.dart` |
| **Layout** | Dark full-screen, radial purple glow blobs |
| **Hero** | 80×80 icon box, `graphic_eq` icon |
| **Copy** | "Welcome back." / "Enter your phone number to continue." |
| **Input** | 🇮🇳 +91 prefix + phone `TextField` |
| **CTA** | Purple gradient "Send OTP" button |
| **States** | Loading disables input; SnackBar errors |

---

### 3.3 OTP verification

| Item | Detail |
|------|--------|
| **File** | `lib/screens/otp_screen.dart` |
| **Layout** | Dark theme (same palette as login) |
| **Input** | 6 individual digit boxes |
| **Timer** | 60s resend countdown |
| **CTA** | Verify + Resend OTP |
| **Success** | → Create Profile or Home |

---

### 3.4 Create profile (onboarding)

| Item | Detail |
|------|--------|
| **File** | `lib/screens/create_profile_screen.dart` |
| **Layout** | Dark, fade+slide entrance animation |
| **Fields** | Full name, date of birth (date picker), gender (male/female) |
| **Avatar** | Auto from gender (local assets: default/male/female PNG) |
| **CTA** | "Complete Profile" gradient button |
| **Validation** | Inline error messages per field |

---

### 3.5 Language selection

| Item | Detail |
|------|--------|
| **File** | `lib/screens/language_selection_screen.dart` |
| **Layout** | Dark + ambient glow |
| **Options** | Malayalam, Tamil, Kannada, Hindi (native script shown) |
| **CTA** | Select language → saves to profile |

---

### 3.6 Home shell (main app)

| Item | Detail |
|------|--------|
| **File** | `lib/screens/home_screen.dart` (~2100 lines) |
| **Structure** | `Scaffold` + tab content + fixed bottom nav overlay |

#### Tab: Home (regular + listener)

| Element | Detail |
|---------|--------|
| **Background** | Light `#F8F8F8` |
| **Header** | White bar 90px — logo gradient square + **"HI ma"** title + tagline "Where Feelings Connect" |
| **Wallet pill** | Pink gradient, amber circle with **"H"**, live coin balance |
| **Filters** | Horizontal chips: "Chats · FREE", "All", "New" |
| **Creator list** | White cards, pull-to-refresh |
| **Empty state** | "No listeners available right now." |

#### Creator card (list item)

| Element | Detail |
|---------|--------|
| Avatar | 70px, pink gradient ring, online dot (green pulse or gray) |
| Name | Poppins 22 bold |
| Badge | "NEW" pink pill (optional) |
| Favorite | Heart icon (local state only, not persisted) |
| Status | "Online" / last seen label |
| CTAs | **Voice** purple gradient "10/min" · **Chat** green gradient "60 coins" |
| Gating | Min 50 coins for voice; 60 for chat; SnackBar if insufficient |

#### Tab: Calls (listeners only)

| Element | Detail |
|---------|--------|
| **Content** | Call history list (`CallHistoryCard`) |
| **Source** | API call history |

#### Tab: Wallet

| Element | Detail |
|---------|--------|
| **Content** | Embedded `CoinRechargeScreen(isTab: true)` |

#### Tab: Listener dashboard (listeners only)

| Element | Detail |
|---------|--------|
| **Content** | Embedded `ListenerDashboardScreen(isTab: true)` |

#### Tab: Profile

| Element | Detail |
|---------|--------|
| **Background** | Dark `#080E1A` |
| **Banners** | Pending / Rejected / Suspended listener application status |
| **Avatar card** | Dark card, UID display, edit pencil (placeholder) |
| **Menu items** | Wallet, Listener Dashboard, Call Statistics, Switch to Listener, Language, Logout, Agora Debug |
| **Refresh** | Pull-to-refresh on profile |

#### Bottom navigation

| User type | Tabs |
|-----------|------|
| Regular | Home · Wallet · Profile (3) |
| Listener | Home · Calls · Wallet · Listener · Profile (5) |
| **Style** | White (light tabs) or dark `#0D1320` (profile/listener tabs), 90px height, rounded top corners |

---

### 3.7 Coin recharge / wallet

| Item | Detail |
|------|--------|
| **File** | `lib/screens/recharge_screen.dart` |
| **Modes** | Full screen (push from header) or bottom-nav tab |
| **App bar** | "Recharge Coins" + wallet balance pill (same as home) |
| **Banner** | "Instantly Connect" info card |
| **Packages** | 2-column grid: coins, price ₹, talk time, optional "BEST VALUE" badge |

**Packages (from API):** Starter 100, Value 550, Popular 1150, Pro 3000, Mega 6500 coins.

#### Payment bottom sheet (`_PaymentFlowSheet`)

| Step | UI |
|------|-----|
| 1 Confirm | Package summary, price, "Pay with Razorpay" |
| 2 Processing | Spinner + "Processing payment…" |
| 3 Success | Green check animation, auto-close ~2.2s |
| **Razorpay** | Native SDK overlay; theme color `#FF1493` |

---

### 3.8 Active call

| Item | Detail |
|------|--------|
| **File** | `lib/screens/calling_screen.dart` |
| **Background** | Dark `#080E1A` + subtle pink/purple glows |
| **Video** | Agora remote/local views; draggable local preview card |
| **Voice** | Large avatar, pulsing rings while ringing |
| **Header** | Name + status ("Ringing…", timer when connected) |
| **Controls** | Mute, speaker, video toggle, flip camera, end call (red) |
| **Extra** | Quick text messages overlay (5 presets) |
| **Ring timeout** | ~24s countdown while ringing |

---

### 3.9 Incoming call

| Item | Detail |
|------|--------|
| **File** | `lib/screens/incoming_call_screen.dart` |
| **Background** | Dark radial gradient `#1A0A2E` → `#080E1A` |
| **Avatar** | 140px, pink ring ripples (3 animated rings) |
| **Label** | "Incoming Voice/Video Call" |
| **Actions** | Decline (red) · Accept (green) — slide-up animation |
| **Audio** | Ringtone via `flutter_ringtone_player` |
| **Back** | Disabled (`PopScope canPop: false`) |

---

### 3.10 Call details

| Item | Detail |
|------|--------|
| **File** | `lib/screens/call_details_screen.dart` |
| **Background** | Light `#F8F9FA` |
| **Sections** | Session (status, type, duration, coins), Timing, Reference ID |
| **Header card** | Avatar + name |

---

### 3.11 Listener application

| Item | Detail |
|------|--------|
| **File** | `lib/screens/listener_application_screen.dart` |
| **Theme** | Dark purple |
| **Form** | Name, bio, avatar picker (6 placeholder URLs), language multi-select chips |
| **Languages** | English, Malayalam, Tamil, Telugu, Hindi, Kannada |
| **CTA** | Submit application |

---

### 3.12 Listener dashboard

| Item | Detail |
|------|--------|
| **File** | `lib/screens/listener_dashboard_screen.dart` (~2000 lines) |
| **Header** | Online/offline toggle (green switch) |
| **Sub-tabs** | Earnings · Payout · History · Reports |

| Sub-tab | Content |
|---------|---------|
| **Earnings** | Weekly bar chart, total coins earned, talk minutes, pickup rate |
| **Payout** | ₹ withdrawable balance, withdraw CTA (min ₹100), bank/UPI form dialog |
| **History** | `CallHistoryCard` list → Call Details |
| **Reports** | Placeholder / reviews section |

**Incoming call handling:** Polls for pending calls when online, shows accept dialog.

---

### 3.13 Agora debug (dev only)

| Item | Detail |
|------|--------|
| **File** | `lib/screens/agora_debug_screen.dart` |
| **Access** | Profile menu |
| **Purpose** | Test Agora token/channel |

---

## 4. User flows

### 4.1 New user

```
Login → OTP → Create Profile → [Language] → Home
```

### 4.2 Buy coins

```
Home header wallet pill OR Wallet tab
  → Package grid → Bottom sheet confirm
  → Razorpay payment → Verify API → Success animation
  → Balance updates in header pill
```

### 4.3 Call a listener

```
Home → Creator card → Voice CTA
  → (if balance ≥ 50) Call type dialog Voice/Video
  → Calling screen (ringing → connected)
  → End call → coins deducted → balance refresh
```

### 4.4 Become a listener

```
Profile → Switch to Listener → Application form → Pending banner on Profile
```

### 4.5 Listener earns & withdraws

```
Listener tab → Online ON → Accept calls
  → Earnings tab → Payout tab → Withdraw (≥ ₹100)
```

---

## 5. Key UI patterns & behaviors

| Pattern | Behavior |
|---------|----------|
| Coin balance display | Pink pill top-right (Home + Recharge only) |
| Minimum call balance | 50 coins (SnackBar if lower) |
| Chat cost | 60 coins (local deduct, no dedicated chat screen) |
| Voice rate display | "10/min" on creator cards |
| Video rate | "20 coins/m" in call-type dialog |
| Errors | Red `SnackBar` (most screens) |
| Loading | `CircularProgressIndicator` (pink on recharge) |
| Avatars | Network URLs from API + `pravatar.cc` placeholders |
| Onboarding avatars | Local PNGs by gender |

---

## 6. Known UX issues (improvement backlog)

| # | Issue | Impact | Priority |
|---|--------|--------|----------|
| 1 | Two visual themes (dark auth vs light home) | Feels like two apps | High |
| 2 | Placeholder branding "HI ma" in header | Not production-ready | High |
| 3 | Coin icon shows letter "H" not a coin asset | Weak monetization branding | Medium |
| 4 | No centralized design tokens — colors/fonts per screen | Hard to maintain | High |
| 5 | `ScalePressedButton` duplicated 3× | Inconsistent press animation | Low |
| 6 | Profile shows raw truncated UUID | Confusing for users | Medium |
| 7 | Favorites heart — local only, not saved | Misleading UX | Medium |
| 8 | Chat CTA deducts coins without real chat UI | Incomplete feature | High |
| 9 | Listener 5-tab nav is crowded on small phones | IA / usability | Medium |
| 10 | No skeleton loaders on creator list | Perceived slowness | Medium |
| 11 | Payment success auto-closes before user sees new balance | Trust issue | Medium |
| 12 | No coin transaction history for regular users | Can't audit spend | High |
| 13 | Some gray-on-dark text fails contrast | Accessibility | Medium |
| 14 | Android-first; no iOS layout considerations | Future platform | Low |

---

## 7. Assets

| Asset | Path |
|--------|------|
| Default avatar | `assets/avatars/default.png` |
| Male avatar | `assets/avatars/male.png` |
| Female avatar | `assets/avatars/female.png` |

---

## 8. Screen file reference (designer ↔ developer)

| Screen | Dart file |
|--------|-----------|
| App root / routing | `lib/main.dart` |
| Login | `lib/screens/login_screen.dart` |
| OTP | `lib/screens/otp_screen.dart` |
| Create profile | `lib/screens/create_profile_screen.dart` |
| Language | `lib/screens/language_selection_screen.dart` |
| Home + tabs + nav | `lib/screens/home_screen.dart` |
| Recharge / wallet | `lib/screens/recharge_screen.dart` |
| Active call | `lib/screens/calling_screen.dart` |
| Incoming call | `lib/screens/incoming_call_screen.dart` |
| Call details | `lib/screens/call_details_screen.dart` |
| Listener application | `lib/screens/listener_application_screen.dart` |
| Listener dashboard | `lib/screens/listener_dashboard_screen.dart` |
| Call history card widget | `lib/widgets/call_history_card.dart` |
| Agora debug | `lib/screens/agora_debug_screen.dart` |

---

## 9. Figma screen checklist

Use this checklist when building frames in Figma.

### Auth & onboarding
- [ ] Splash / loading
- [ ] Login (empty, filled, error, loading)
- [ ] OTP (empty, partial, complete, resend active)
- [ ] Create profile (empty, validation errors, complete)
- [ ] Language selection

### Main app — regular user (3 tabs)
- [ ] Home — with creators list
- [ ] Home — empty state
- [ ] Home — low balance / insufficient coins SnackBar
- [ ] Home — call type dialog (voice / video)
- [ ] Wallet / Recharge — package grid
- [ ] Recharge — confirm bottom sheet
- [ ] Recharge — processing
- [ ] Recharge — success
- [ ] Profile — default
- [ ] Profile — listener pending banner
- [ ] Profile — listener rejected banner

### Main app — listener (5 tabs)
- [ ] All regular user screens above
- [ ] Calls tab — history list
- [ ] Listener dashboard — Earnings
- [ ] Listener dashboard — Payout
- [ ] Listener dashboard — History
- [ ] Listener dashboard — Reports
- [ ] Listener dashboard — online toggle on/off
- [ ] Incoming call dialog (listener)

### Calls
- [ ] Incoming call (voice)
- [ ] Incoming call (video)
- [ ] Active call — ringing (voice)
- [ ] Active call — connected with timer
- [ ] Active call — video layout
- [ ] Call details

### Other
- [ ] Listener application form
- [ ] Bottom nav — 3 tab variant
- [ ] Bottom nav — 5 tab variant
- [ ] Bottom nav — dark variant (profile/listener tabs)

---

## 10. Recommended designer deliverables

1. **Unified design system** — single theme or proper light/dark mode
2. **Figma component library** — buttons, cards, nav, wallet pill, creator card, call controls
3. **Brand identity** — app name, logo, coin icon (replace "H")
4. **Information architecture** — simplify listener vs user navigation
5. **Recharge flow** — clearer success state + transaction receipt screen
6. **Call flow** — ringing, connected, low-balance warning, end-call summary
7. **Empty / error / loading states** for all lists
8. **Accessibility pass** — 48dp touch targets, contrast ratios, font scaling

---

## 11. Technical notes for handoff

- **State management:** Provider (`AuthProvider`, `WalletProvider`, `CreatorProvider`, etc.)
- **API base:** Production `https://api.creomine.com`
- **Payments:** Razorpay native SDK (India / INR)
- **Calls:** Agora RTC (voice + video)
- **Auth:** Firebase phone OTP + backend JWT

---

*Document generated for UI/UX review. Update this file when screens or flows change.*
