# Zomo Gold App — Developer Guide

A Flutter jewellery catalog app for Zomo Jewellers Pvt. Ltd. (Hyderabad, India). This guide is for engineers maintaining or extending the codebase. For an end-user feature walkthrough see `USER_GUIDE.md`; for a Firestore field-by-field reference see `DATA_MODEL.md`.

## 1. Tech stack

| Layer            | Technology                                                          |
| ---------------- | ------------------------------------------------------------------- |
| Client framework | Flutter (Dart SDK ^3.9.2)                                           |
| Target platforms | Android, iOS, Web (macOS/Linux/Windows scaffolds also present)      |
| Authentication   | Firebase Auth — phone number + OTP (country code hard-coded `+91`)  |
| Database         | Cloud Firestore                                                     |
| File storage     | Firebase Storage (product images)                                   |
| Live rate feed   | `https://statewisebcast.dpgold.in:7768/...` (external HTTP service) |
| Deep linking     | `app_links` package, scheme `https://zomogold.com/product/{id}`     |
| Order capture    | `tel:` + WhatsApp (`wa.me`) — no in-app checkout                    |
| Project ID       | `zomo-1f300` (Firebase project name)                                |

## 2. Repository layout

```
zomogoldapp/
├── android/                   # Android Gradle project (google-services.json committed)
├── ios/                       # iOS Xcode project (GoogleService-Info.plist NOT committed)
├── web/                       # PWA shell + icons
├── linux/, macos/, windows/   # Desktop scaffolds (not actively maintained)
├── assets/                    # PNGs for categories and people imagery
├── lib/                       # All Dart source — see section 3
├── test/                      # widget_test.dart (default counter test, currently broken)
├── analysis_options.yaml      # Lints from package:flutter_lints/flutter.yaml
├── pubspec.yaml               # Dependency manifest
├── README.md                  # Project overview
├── CLAUDE.md                  # Guidance for code agents (Claude Code, etc.)
├── DOCUMENTATION.md           # This file
├── DATA_MODEL.md              # Firestore reference
└── USER_GUIDE.md              # End-user feature guide
```

The `assets/` folder ships with category illustrations (`rings.png`, `necklaces.png`, `earrings.png`, `pendants.png`, `bracelets.png`, `anklets.png`, `noserings.png`, `silver_coin.png`), audience avatars (`men.png`, `women.png`, `boy.png`), and a hero banner (`home_image.png`). Add new assets here and re-run `flutter pub get`; the `assets:` block in `pubspec.yaml` already includes the entire folder.

## 3. `lib/` walkthrough

```
lib/
├── main.dart
├── theme/app_theme.dart
├── models/
│   ├── product_model.dart
│   ├── product_rate_model.dart
│   ├── wish_list_model.dart
│   ├── price_calculator.dart
│   └── product_sort.dart
├── dao/
│   ├── product_dao.dart
│   ├── product_rate_dao.dart
│   └── wish_list_dao.dart
└── screens/
    ├── phone_login_screen.dart
    ├── otp_verification_screen.dart
    ├── home_screen.dart
    ├── search_screen.dart
    ├── grid_screen.dart
    ├── filter_screen.dart
    ├── product_card.dart
    ├── product_view_page.dart
    ├── product_details.dart
    ├── full_screen_image.dart
    ├── wishlist_screen.dart
    ├── cart_screen.dart            (stub)
    ├── orders_screen.dart          (stub)
    ├── category_screen.dart        (stub)
    ├── category_service.dart
    ├── custom_buttons.dart
    ├── toast_helper.dart
    ├── gold_rate.dart              (admin)
    └── history_screen.dart
```

### 3.1 `main.dart`

Entry point. Responsibilities:

1. Initializes Firebase. On web, hard-coded `FirebaseOptions` are passed to `Firebase.initializeApp`; on native, the SDK reads `google-services.json` / `GoogleService-Info.plist`.
2. Sets up an `AppLinks` listener: any incoming URI with a `product` path segment pushes `ProductDetailsViewPage(productId: <last segment>)` onto the global navigator.
3. Defines `MaterialApp` with `theme: AppTheme.lightTheme`, English-only locales, and two named routes:
   - `/` → `PhoneLoginScreen` (current production landing)
   - `/history` → `PriceHistoryScreen` (expects `productType` as `String` route argument)

The `flutter_quill` localization delegate is registered globally so the rich text editor works in product creation and the product viewer.

### 3.2 `theme/app_theme.dart`

Centralized design tokens:

- `AppColors.purple` — `MaterialColor` swatch (50–900) anchored on `#6C4EE3`. This is the brand color.
- `AppColors.background` (`#F2EDF9`), `textColor` (`0xB26750A4`), `textPrimary`, `textSecondary`.
- `AppText` — font size constants: `heading` 28, `subHeading` 18, `body` 16, `small` 14.
- `AppTheme.lightTheme` — `ThemeData` with rounded `OutlineInputBorder` for inputs and an `ElevatedButton` style.

Several screens still hard-code their own purple shades (`#7F55B5` in product pages, `#6B52A1` in grid/filter, `#673AB7` in admin). Refactoring these to `AppColors` is a clean-up opportunity.

### 3.3 Models (`lib/models/`)

Plain Dart classes. Each has a `fromSnapshot(DocumentSnapshot)` factory and a `toJson()` for Firestore round-tripping. Defaults are applied liberally (`data["x"] ?? defaultValue`) so older docs without newer fields still load.

**`ProductModel`** (`product_model.dart`) — the catalog item. Fields: `productId`, `categoryId`, `productName` (+ `productNameLower` for prefix search), `userId` (creator), `images` (List<String> URLs from Firebase Storage), `metalName`, `carats`, `metalGrams`, `stoneWeight`, `stoneCost`, `stoneWeightUnit`, `purity`, `makingCharges`, `discount`, `tagId`, `productInformation` (Quill JSON delta as string), `specifications` (Quill JSON delta as string), `hallmark`, `createdTimestamp`, `modifiedTimestamp`, `gender`, `viewCount`. Note: `ProductModel` does **not** persist `makingChargeType` even though the admin form lets you choose `%` vs `Flat`.

**`ProductRateModel`** (`product_rate_model.dart`) — one entry per manual rate update. Fields: `id`, `productType` (`GOLD`/`SILVER`), `price` (manually entered), `livePrice` (snapshot of the API rate at the time), `unit` (`per 1g` or `per KG`), `userId`, `timestamp` (millis since epoch, int), `remarks`.

**`WishlistModel`** (`wish_list_model.dart`) — a (user, product) pair. Fields: `wishlistId`, `userId`, `productId`, `createdAt` (stored as ISO 8601 string).

**`PriceCalculator`** (`price_calculator.dart`) — pure static helpers:

- `calculateProductMRP({metalName, carats, metalGrams, metalRate, stoneWeight, stoneCost, makingChargeValue, makingChargeType})`
  - Gold: `(double.parse(carats) / 24) * metalRate * metalGrams`
  - Silver/other: `metalRate * metalGrams`
  - Plus stones: `+ stoneWeight * stoneCost`
  - Plus making: `+ makingChargeValue` (Flat) or `+ priceBeforeMaking * makingChargeValue / 100` (`%`)
- `calculateSellingPrice({mrp, discountPercent})` returns `mrp - discountPercent`. Despite the parameter name, this subtracts a flat rupee amount, not a percentage.

**`ProductSortType`** enum — `newArrivals`, `popular`, `priceLowToHigh`, `priceHighToLow`. Used only by `grid_screen.dart`.

### 3.4 DAOs (`lib/dao/`)

Thin Firestore wrappers. One DAO per top-level collection.

**`ProductDao`** (`product_dao.dart`) — collection `Products`.

| Method                         | Behavior                                                             |
| ------------------------------ | -------------------------------------------------------------------- |
| `addProduct(p)` / `updateProduct(p)` / `deleteProduct(id)` | CRUD on `Products/{productId}`.        |
| `getProductById(id)`           | One-shot fetch. Returns a `ProductModel`.                            |
| `getAllProducts()`             | `Stream<List<ProductModel>>` — all products.                         |
| `getProductsByCategory(id)`    | Live filter by `categoryId`.                                         |
| `getProductsByUser(id)`        | Live filter by `userId`.                                             |
| `getProductsByMetal(metal, excludeId)` | Limit 10, filter by `metalName`, exclude one. Used for "You may also like". |
| `generateNextProductId()`      | Reads/increments `sequences/product_sequence.nextId`. **Not transactional.** Falls back to `DateTime.now().millisecondsSinceEpoch` on error. |
| `getLatestRateByType(type)`    | Returns the most recent `price` from `product_rate` where `productType == type.toUpperCase()`. (Note: same logic exists in `ProductRateDao` — duplicated.) |
| `recordView(id)`               | Atomic `viewCount` increment via `FieldValue.increment(1)`.          |

**`ProductRateDao`** (`product_rate_dao.dart`) — collection `product_rate`.

| Method                                       | Behavior                                                  |
| -------------------------------------------- | --------------------------------------------------------- |
| `addRateEntry(rate)`                         | Writes to `product_rate/{rate.id}` (id format: `${type}_${timestamp}`). |
| `getFilteredRates(productType, startTs, endTs)` | Live stream of rates in a time window, sorted desc.    |
| `getLatestRateByType(metal)`                 | Same as `ProductDao.getLatestRateByType` — duplicated.    |

**`WishlistDao`** (`wish_list_dao.dart`) — collection `Wishlist`.

| Method                              | Behavior                                                      |
| ----------------------------------- | ------------------------------------------------------------- |
| `addProduct(item)`                  | Writes to `Wishlist/{wishlistId}`.                            |
| `removeProduct(userId, productId)`  | Queries by both fields and deletes every match.               |
| `isInWishlist(wishlistId)`          | Existence check by doc ID. Rarely useful — call sites use `isProductInWishlist`. |
| `isProductInWishlist(userId, productId)` | The actual existence check used across the app.          |
| `getWishlistForUser(userId)`        | Live stream sorted by `createdAt desc`.                       |
| `generateNextWishlistId()`          | Reads/increments `sequences/wishlist_sequence.nextId`. **Not transactional.** |

### 3.5 Screens (`lib/screens/`)

#### Auth flow

**`phone_login_screen.dart`** — landing screen. Displays a `+91` prefix and a 10-digit phone field. Validates length, then calls `FirebaseAuth.instance.signInWithPhoneNumber` (web) or `verifyPhoneNumber` (native). Web returns a `ConfirmationResult`; native uses `verificationCompleted` (auto-sign-in if SMS auto-fills) and `codeSent` (manual entry). Both routes push `OtpVerificationScreen`. The "Login as guest" outlined button has an empty `onPressed` — guest mode is not implemented.

**`otp_verification_screen.dart`** — six separate `TextField`s for OTP digits, with auto-advance focus and backspace-to-previous-box. A 30-second resend countdown. On verify, navigates with `pushReplacement` to `HomeScreen`.

#### Browsing flow

**`home_screen.dart`** — landing after auth. Sections:

- App bar with logo placeholder, search icon → `SearchScreen`, favorite + cart icon (`actionCircleIcon` from `custom_buttons.dart`).
- Hero banner (`assets/home_image.png`).
- "Shop By" pill buttons: Gold / Silver / Diamond → `GridScreen` filtered by `metals`.
- "Shop by category" 4-column grid of 8 hard-coded categories (Rings, Necklaces, Nose accessories, Silver coin, Pendants, Earrings, Bracelets, Anklets). Tapping resolves the category name to an ID via `_getCategoryIdByName` (using categories loaded from Firestore through `CategoryService`) and navigates to `GridScreen`.
- "Shop by" people row: Men / Women / Boy. Maps to gender enum: Men→Male, Women→Female, Boy→Children.
- About us footer.
- Bottom nav: Home / Category / Orders / Profile. **The Profile tab opens `GoldRatesScreen`** (admin view) — there's no role check.

Note: `home_screen.dart` defines a stray `main()` function at the top (lines 14-18) that was left in from a copy-paste; it is unreachable because `lib/main.dart` is the real entry point.

**`search_screen.dart`** — autocomplete search.
- Uses `flutter_typeahead` with a `suggestionsCallback` that prefix-searches the `Products` collection by `productNameLower`.
- Recent searches (max 5) persisted via `SharedPreferences` under key `recent_searches`.
- "Top recommendations" and "Trending searches" are hard-coded chips that route to filtered `GridScreen` views.

**`grid_screen.dart`** — main product list.
- Accepts `initialMetals`, `initialGenders`, `initialCategoryIds`, `initialSearchQuery`.
- Paginates via `query.startAfterDocument(_lastDoc).limit(20)` with infinite-scroll on a `ScrollController`.
- Sorts via `ProductSortType`. New Arrivals/Popular order at Firestore; price sorts pre-fetch rates and sort client-side.
- Filters that aren't expressible in a single Firestore query (combinations of metal+gender+category) are applied client-side after pagination.
- Caches metal rates per session in `_rateCache` to avoid refetching.
- Bottom bar: "Sort by" (modal) and "Filter" (pushes `FilterScreen`).

**`filter_screen.dart`** — left side-tab UI with Product type / Price / Metal / Gender. Price is a `RangeSlider` from 0 to ₹2,000,000. Apply pops with a result map; Reset clears everything. Returns `null` if the user backs out; the parent only re-fetches when a non-null result is returned.

**`product_card.dart`** — reusable card widget. Shows the first image, computed selling price + struck-through MRP, and the product name (or category name as fallback). Top-right favorite toggle calls `WishlistDao.addProduct`/`removeProduct`. When `isFromWishlist: true`, swaps the favorite for a delete icon (with confirm bottom-sheet) and shows an "Add to Bag" button (currently a no-op).

**`product_view_page.dart`** — full product detail.
- Image gallery with page indicators; tap opens `FullScreenImagePage` (zoomable via `photo_view`).
- Wishlist + share icons on header.
- "₹ MRP / ₹ selling price" row, info chips (carats, making charges %).
- Two `ExpansionTile`s for product info and specifications, rendered through `flutter_quill` from the stored Quill JSON deltas.
- "You May Also Like" horizontal list streamed from `ProductDao.getProductsByMetal`.
- Bottom bar: green "Order on WhatsApp" → `wa.me/918790343501` with prefilled message containing the product link, and purple "Call to Order" → `tel:+918790343501`.
- Increments `viewCount` on open.

**`full_screen_image.dart`** — `PhotoViewGallery` with hero-tag continuity from `product_view_page.dart`.

**`wishlist_screen.dart`** — grid of `ProductCard`s. Reads the user's wishlist (`WishlistDao.getWishlistForUser(uid).first`), then batch-fetches products via `whereIn` on `productId`. Note the 10-item limit on Firestore `whereIn` queries — this will silently truncate large wishlists.

**`cart_screen.dart`**, **`orders_screen.dart`**, **`category_screen.dart`** — placeholder screens. Empty-state text only.

#### Admin flow

**`gold_rate.dart` (`GoldRatesScreen`)** — entered via Profile tab.
- Two sub-tabs: "Rate update" and "Product update".
- Rate update: horizontally swipable cards for GOLD and SILVER showing the live API rate. A "Refresh" button refetches from `dpgold.in`. A form below lets the admin enter a manual rate + remarks, which `ProductRateDao.addRateEntry` writes to Firestore. The doc ID is `${selectedMetal}_${timestamp}`.
- Product update: embeds `ProductDetailsPage` (the product creation form).
- "View History" button on each rate card pushes `PriceHistoryScreen`.

The live rate is parsed from a tab-separated text response. The parser specifically looks for lines containing `GOLD`, `999`, and `/ 10 Gm` (gold per 10g, then column index 3) or `SILVER 30 KG PAN India` (silver per kg). This is very brittle to upstream format changes.

**`product_details.dart` (`ProductDetailsPage`)** — admin product creation form. Sections:
- Image picker (up to 10 images) with drag-to-reorder thumbnails (`reorderables.ReorderableListView`). Web uses `Uint8List`, native uses `File`.
- Text fields (product name, grams, stone weight, stone cost, making charges, discount).
- Dropdowns (metal, carats, gender, category, weight unit, making charge type).
- Hallmark checkbox.
- Two `flutter_quill` editors (product details, specifications) — saved as JSON delta strings.
- Validation, `_uploadImages` to `Firebase Storage` under `products/{productId}/image_$i.jpg`, then `ProductDao.addProduct`.
- Note: the chosen "% / Flat" making charge type is **not** saved to `ProductModel`. Read sites assume `Flat`.

**`history_screen.dart` (`PriceHistoryScreen`)** — line chart + list of historical rates.
- Time range dropdown: 1 Day / 1 Week / 1 Month / 3 Months / 6 Months / 1 Year.
- Two series on the chart: manual (purple) and live (cyan) — sourced from `ProductRateDao.getFilteredRates`.
- Below the chart, a list with date/time and ₹ price formatted via `intl`.

#### Helpers

**`category_service.dart`** — singleton with a memoized list loaded from the `Category` collection. Provides `getCategoryName(categoryId)` returning the name or "Jewellery" fallback.

**`custom_buttons.dart`** — `actionCircleIcon`. A round filled-icon button used in app bars. Hard-codes navigation: tapping `Icons.favorite_border` pushes `WishlistScreen`; `Icons.shopping_bag_outlined` pushes `CartScreen`. The optional `onTap` runs after navigation returns.

**`toast_helper.dart`** — `ToastHelper.showWishlistToast` shows a floating `SnackBar`. Used by `product_card.dart` and `product_view_page.dart`.

## 4. Build & run

### Prerequisites

- Flutter SDK ≥ 3.9.x
- For Android: Android Studio + Android SDK, JDK 11
- For iOS: macOS + Xcode + CocoaPods
- For Web: Chrome (or any modern browser for testing)
- A Firebase project (for production; the existing `zomo-1f300` project is configured)

### First-time setup

```bash
git clone <repo>
cd zomogoldapp
flutter pub get
```

For iOS, you must add `ios/Runner/GoogleService-Info.plist` from the Firebase console (it is **not** committed). The Android `google-services.json` is checked in.

For web, the Firebase config is hard-coded in `lib/main.dart` — change those values if you point at a different project.

### Running

```bash
flutter run                  # auto-detects connected device
flutter run -d chrome        # web
flutter run -d ios           # iOS simulator (macOS only)
flutter run -d android       # Android emulator/device
```

### Building for release

```bash
flutter build apk --release           # Android APK
flutter build appbundle --release     # Play Store AAB
flutter build ipa --release           # iOS (then sign in Xcode)
flutter build web --release           # static files in build/web
```

Before shipping, address the TODOs in `android/app/build.gradle.kts` (the application ID is still `com.example.zomogoldapp` and the release build is signed with the debug keys).

## 5. Firebase configuration checklist

Inside the Firebase console for project `zomo-1f300`:

- **Authentication** → Phone provider enabled. Add test phone numbers if developing without real SMS.
- **Firestore** → Native mode. Indexes are likely needed for compound queries (`product_rate` orderBy `timestamp` + where `productType`; `Products` orderBy `productNameLower` for prefix search; `Wishlist` `userId` + `createdAt`). Firestore will surface link errors when you first run the affected query — follow the link to auto-create.
- **Storage** → Default bucket `zomo-1f300.firebasestorage.app`. Path scheme: `products/{productId}/image_$i.jpg`.
- **App Check** → not yet configured.
- **Security rules** → not in this repo. Lock down `Wishlist` to `request.auth.uid == resource.data.userId`, restrict writes to `Products` / `product_rate` / `Category` / `sequences` to admin accounts. (This is currently absent — anyone with the API key can write.)

## 6. Known issues and improvement opportunities

- `test/widget_test.dart` is the default counter test and fails. Either delete it or write real tests.
- `home_screen.dart` has a stray `main()` function at the top.
- `cart_screen.dart`, `orders_screen.dart`, `category_screen.dart` are stubs.
- "Login as guest" button is a no-op.
- The "Profile" tab opens the admin screen with no auth-gated role check.
- `generateNextProductId` and `generateNextWishlistId` are not transactional — concurrent writes can collide.
- `PriceCalculator.calculateSellingPrice` subtracts `discountPercent` as a flat amount despite the parameter name.
- `ProductModel` does not persist `makingChargeType`; reads always assume `Flat`.
- The live-rate parser in `gold_rate.dart` is brittle (string matching on a TSV upstream).
- Several screens read Firestore directly instead of going through DAOs (`home_screen.dart`, `grid_screen.dart`, `search_screen.dart`, `filter_screen.dart`, `product_details.dart`).
- Hard-coded sales phone (`+918790343501`) in `product_view_page.dart`. Move to `Category` / settings doc if this varies by region.
- Wishlist fetch uses `whereIn` which Firestore caps at 10 (or 30 in newer SDK) — large wishlists will silently truncate.
- `ProductDao.getLatestRateByType` and `ProductRateDao.getLatestRateByType` are duplicates.
- No analytics or crash reporting (`firebase_analytics` / `firebase_crashlytics`) wired up.
- Strings are not localized; only `en_US` is supported despite `flutter_localizations` being included.

## 7. Conventions

- One DAO per top-level Firestore collection. Methods return `Future<T>` for one-shot reads/writes and `Stream<List<T>>` for live queries.
- Models own their own (de)serialization. No code generation (no `freezed` / `json_serializable`).
- No state-management library. Each screen is a `StatefulWidget` and owns its own data.
- Cross-screen shared state goes in singletons (`CategoryService`) or is passed through navigation.
- New screens go directly under `lib/screens/`; named routes are reserved for screens that need to be reachable from deep links or arguments-based navigation.
- Currency strings are formatted manually as `'₹ ${value.toStringAsFixed(0)}'` (or `.toStringAsFixed(2)` for the detail page) — not via `NumberFormat.currency`.
