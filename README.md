# DerivAI Trader 🤖📈

AI-powered Flutter trading app for the Deriv market with real-time WebSocket connection, ML pattern analysis, and automated trading.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart     # All constants, markets, keys
│   │   └── app_routes.dart        # GetX named routes
│   └── theme/
│       └── app_theme.dart         # Dark theme + colors
│
├── data/
│   ├── datasources/
│   │   ├── deriv_websocket_service.dart   # Deriv WS connection & trading
│   │   └── ai_trading_engine.dart         # AI/ML pattern analysis
│   └── models/
│       └── trading_models.dart            # All data models
│
└── presentation/
    ├── controllers/
    │   ├── auth_controller.dart           # Sign in / sign out
    │   ├── settings_controller.dart       # API token + risk settings
    │   ├── trading_controller.dart        # Core trading logic
    │   └── report_controller.dart         # PDF report generation
    │
    ├── screens/
    │   ├── splash/splash_screen.dart
    │   ├── onboarding/onboarding_screen.dart
    │   ├── auth/
    │   │   ├── sign_in_screen.dart
    │   │   └── market_selection_screen.dart
    │   ├── home/home_screen.dart          # Responsive nav (bottom / drawer)
    │   ├── trade/trade_screen.dart        # Main trading screen
    │   ├── profile/profile_screen.dart
    │   └── settings/settings_screen.dart
    │
    └── widgets/
        ├── common/stat_card.dart
        └── trade/
            ├── confidence_gauge.dart
            └── digit_heatmap.dart
```

---

## 🚀 Setup Instructions

### 1. Create the Flutter project

```bash
flutter create deriv_ai_trader
cd deriv_ai_trader
```

### 2. Replace pubspec.yaml

Copy the provided `pubspec.yaml` then run:

```bash
flutter pub get
```

### 3. Copy all source files

Replace everything inside `lib/` with the provided files, maintaining the folder structure.

### 4. Add Assets

Create the assets folders:
```bash
mkdir -p assets/images assets/lottie assets/fonts
```

Add a font (optional but recommended):
- Download **Rajdhani** from Google Fonts → place all `.ttf` files in `assets/fonts/`
- Or remove `fontFamily: 'Rajdhani'` from `app_theme.dart` to use the system font.

### 5. Android Config

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 6. iOS Config

In `ios/Runner/Info.plist`, add:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 🔑 Admin Credentials
qmHPZGE851CQWNs
Default credentials (change in `app_constants.dart`):
- **Username:** `trader`
- **Password:** `deriv2024`

---

## 🔌 Deriv API Token

1. Go to [app.deriv.com](https://app.deriv.com)
2. Account Settings → API Token
3. Create a token with **Read + Trade** permissions
4. Paste it in the app's Settings screen → tap **Authorize & Connect**

The token is cached securely using `get_storage` — no re-entry needed until changed.

---

## 🤖 AI Engine Overview

The `AITradingEngine` uses three strategies based on the selected category:

| Category | Strategy |
|----------|----------|
| **Odd/Even** | Mean-reversion: detects bias in last 20 digits and counters it |
| **Match/Differ** | Frequency + volatility: matches dominant in stable market, differs in volatile |
| **Under/Over** | Trend analysis: detects dominance of high/low digits and predicts reversion |

**Market Health** is calculated from:
- Shannon entropy (randomness)
- Standard deviation of last digits
- Maximum consecutive same digit (streak detection)

**Pattern Learning** records wins/losses per 5-digit pattern and adjusts confidence accordingly.

---

## ⚙️ Key Features

- ✅ Real-time WebSocket to Deriv (`wss://ws.binaryws.com`)
- ✅ AI confidence gauging per prediction
- ✅ Digit heatmap (frequency visualization)
- ✅ Auto-trading with risk management
- ✅ Market optimizer (scans all markets for best conditions)
- ✅ Goal progress bar (P&L vs daily target)
- ✅ Stop-loss enforcement
- ✅ Cached API token + risk settings
- ✅ PDF session report download
- ✅ Responsive layout (bottom nav on mobile, side drawer on wide screens)

---

## ⚠️ Disclaimer

Trading involves significant risk. This app does not guarantee profits. Use virtual accounts for testing before live trading.
