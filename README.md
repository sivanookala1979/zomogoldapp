# Zomo Gold App

A Flutter jewellery catalog app for **Zomo Jewellers Pvt. Ltd.** (Hyderabad, India). Users browse a curated catalog of gold, silver, diamond, and platinum jewellery; interested buyers contact the shop directly via WhatsApp or phone call. There is no in-app checkout — this is a showcase app, not a marketplace.

## Features

- Phone-number authentication with OTP (Firebase Auth, hard-coded `+91` country code)
- Browse by category (Rings, Necklaces, Earrings, Bracelets, Anklets, Pendants, Nose accessories, Silver coins), by metal (Gold/Silver/Diamond/Platinum), or by audience (Men/Women/Boy)
- Search with type-ahead suggestions and recent-search history
- Sort and filter — sort by new arrivals, popularity, or price; filter by category, price range, metal, and gender
- Product detail page with image gallery (pinch-to-zoom), live-computed selling price, rich-text product info & specifications, and a "You may also like" carousel
- Wishlist (heart) per user, persisted across devices
- "Order on WhatsApp" with a pre-filled message linking back to the product, and "Call to Order" with the store's phone number ready to dial
- Deep linking — `https://zomogold.com/product/{id}` opens the product detail page directly
- Admin tools (currently not role-gated):
  - Update store gold/silver rates and view rate history with a chart
  - Add new products with up to 10 reorderable images, rich-text fields, and validation

## Tech stack

| Area              | Technology                                                  |
| ----------------- | ----------------------------------------------------------- |
| Client framework  | Flutter (Dart SDK ^3.9.2)                                   |
| Target platforms  | Android, iOS, Web                                           |
| Authentication    | Firebase Auth (phone OTP)                                   |
| Database          | Cloud Firestore                                             |
| File storage      | Firebase Storage                                            |
| Live rate feed    | External HTTP API (dpgold.in)                               |
| Charts            | `fl_chart`                                                  |
| Rich text         | `flutter_quill`                                             |
| Deep linking      | `app_links`                                                 |
| Order capture     | `url_launcher` (`tel:` and `wa.me/`)                        |

## Getting started

### Prerequisites

- Flutter SDK 3.9.x or newer
- For Android development: Android Studio + JDK 11
- For iOS development: macOS + Xcode + CocoaPods
- A Firebase project (the existing `zomo-1f300` project is wired up; to use your own, see the configuration section below)

### Setup

```bash
git clone <repo-url>
cd zomogoldapp
flutter pub get
```

For iOS, you must obtain `ios/Runner/GoogleService-Info.plist` from the Firebase console and place it in the `ios/Runner/` directory — it is not committed. The Android `google-services.json` is already in `android/app/`.

For web, the Firebase config is hard-coded in `lib/main.dart`. If you point at a different Firebase project, update the `FirebaseOptions` block there too.

### Run

```bash
flutter run                   # auto-detect connected device
flutter run -d chrome         # web
flutter run -d ios            # iOS simulator (macOS only)
flutter run -d android        # Android emulator/device
```

### Build

```bash
flutter build apk --release         # Android APK
flutter build appbundle --release   # Play Store bundle
flutter build ipa --release         # iOS archive (sign in Xcode)
flutter build web --release         # static files in build/web
```

Before shipping a release Android build, replace the placeholder `applicationId` (currently `com.example.zomogoldapp`) and configure a real signing key in `android/app/build.gradle.kts`.

### Tests

```bash
flutter test
```

Note: `test/widget_test.dart` is currently the default `flutter create` counter test and will fail. Replace it with real tests for this app's screens.

## Project structure

```
lib/
├── main.dart                  Firebase init, deep-link handling, MaterialApp
├── theme/                     Colors, typography, ThemeData
├── models/                    Domain models with Firestore (de)serialization
│   └── price_calculator.dart  Pure pricing math
├── dao/                       One DAO per top-level Firestore collection
└── screens/                   All UI; flat folder, no per-feature subfolders

assets/                        Category illustrations and banner images
android/, ios/, web/, ...      Per-platform projects
```

For a deeper walkthrough see [`DOCUMENTATION.md`](./DOCUMENTATION.md).

## Documentation

- [`DOCUMENTATION.md`](./DOCUMENTATION.md) — developer guide: architecture, file-by-file walkthrough, conventions, known issues
- [`DATA_MODEL.md`](./DATA_MODEL.md) — Firestore collections, document fields, and screen-to-data flows
- [`USER_GUIDE.md`](./USER_GUIDE.md) — end-user feature walkthrough (shoppers and store staff)
- [`CLAUDE.md`](./CLAUDE.md) — guidance for code agents (Claude Code, Cursor, etc.) working in this repo

## Status & roadmap

The catalog, browsing, search, wishlist, contact-to-order, rate management, and product administration flows are implemented and in production use. The following screens are placeholders awaiting implementation:

- **Cart** — currently shows "Your cart is empty"
- **My Orders** — currently shows "Your past orders will appear here"
- **Category landing page** (when reached via the bottom nav) — shows category name only

Other planned items: role-gated admin access, Firestore security rules, automated tests, localization beyond `en_US`, transactional ID generation, and migration of the working sales contact number to a configuration document so it can be edited without a release.

## License

Private — all rights reserved by Zomo Jewellers Pvt. Ltd.
