# Barcode Feature — Design & Task Breakdown

This document plans the work to add barcode generation, TSC label printing, and barcode-driven product lookup to the Zomo Gold app, plus a one-time migration of existing product IDs to a new 8-digit format.

**Status:** Design — not yet implemented. Code changes will follow after this plan is approved.

## 1. Goals

1. **New product ID format.** Every product is identified by an 8-digit number, each digit between 1 and 9 (no zeros). New IDs look "jumbled" — they are not sequential and not predictable from creation order.
2. **Barcode on every product.** The admin app generates a scannable barcode for each product based on its productId.
3. **Label printing via TSC.** From the admin app, a single tap prints a physical label on a TSC barcode printer. Labels include the barcode, productId, and key product info.
4. **Barcode scanning in the user app.** A "Scan" entry on the home screen captures input from a TSC barcode scanner and opens the matching product detail page.
5. **Migrate existing products.** All current sequential-ID products are backfilled to the new 8-digit format. Wishlist references are updated atomically. Old product images remain intact.

## 2. Non-goals

- Camera-based scanning (we may add it as a fallback later, but the primary input is a hardware HID scanner).
- Generating a barcode in any format other than what TSC printers natively support (Code 128 — see §4).
- Real-time bidirectional printer status (we accept fire-and-forget print jobs and surface failures asynchronously).
- Supporting non-TSC printers in v1.
- Maintaining backward compatibility for old deep links (`https://zomogold.com/product/1`) — these break when their product is migrated. Mitigation in §7 if needed.

## 3. Decisions already made

These were settled before this doc was written:

| Decision                             | Choice                                                           |
| ------------------------------------ | ---------------------------------------------------------------- |
| ID migration strategy                | Backfill all existing products to new 8-digit IDs (one-time).    |
| Printer transport(s) to support      | Plan for all three: USB, Bluetooth, Wi-Fi/Ethernet (network).    |
| Where the user app exposes scanning  | Dedicated "Scan" entry on the home screen.                       |

## 4. Product ID design

### 4.1 Format

- 8 characters, each one of `1 2 3 4 5 6 7 8 9` (no `0`).
- Stored as `String` (matches the existing `ProductModel.productId` type — no schema change in `Products`).
- Example: `47291638`, `92518473`, `13957864`.

### 4.2 Namespace size

`9^8 = 43,046,721` (≈43 million unique IDs). At even 100 new products per day, the chance of a collision after 10 years remains under 0.001%. Plenty of room.

### 4.3 Generation algorithm

1. Use a cryptographically-secure RNG (`dart:math` `Random.secure()`).
2. Pick 8 digits uniformly from `1..9`. Concatenate.
3. Check `Products/{candidateId}` for existence with a one-shot Firestore read.
4. If it exists, retry. Cap at 5 retries — beyond that, log and surface an error (this would only happen if the namespace becomes very full, which we won't reach).

### 4.4 Replaces

`ProductDao.generateNextProductId()` and the `sequences/product_sequence` document. The `sequences` collection can be dropped after migration (or kept for the wishlist sequence — which we should also replace, see §10 open questions).

### 4.5 Lookup characteristics

Product lookup by ID stays a single-document `get`: `FirebaseFirestore.instance.collection('Products').doc(scannedId).get()`. No change to query patterns. The deep-link handler in `main.dart` works unchanged.

## 5. Barcode generation

### 5.1 Symbology

**Code 128, subset C** (most efficient encoding for pairs of digits, exactly fits our 8-digit numeric IDs).

Rationale:
- Native TSPL `BARCODE` command supports it (`"128"`).
- Higher data density than Code 39 → smaller printed label or larger module size at the same width.
- All consumer-grade TSC scanners decode Code 128 by default.
- Numeric-only IDs in subset C use 4 digits per pattern → very compact.

Alternatives considered: Code 39 (simpler but uses ~50% more horizontal space), EAN-8 (numeric-only and fixed length but tied to the GS1 numbering authority — not appropriate for in-store IDs), QR code (overkill for 8 digits and scanners typically scan 1D faster).

### 5.2 Library

[`barcode`](https://pub.dev/packages/barcode) (pure Dart, MIT license). It generates SVG, drawable canvas instructions, or vector data — everything we need for on-screen preview. Importantly, **we do not use the `barcode` package output for the actual print**: TSC printers render the barcode themselves from the TSPL `BARCODE` command. The `barcode` package is only used to render a preview thumbnail in the admin UI.

### 5.3 Where it appears

- Admin product list / admin product detail: small preview thumbnail next to each product.
- Print preview dialog: full-size representation matching the printed label.
- Optional: on the user-facing product detail page (probably not — adds visual noise for shoppers).

## 6. Label printing (TSC)

### 6.1 TSPL command set

TSC printers speak [TSPL2](https://www.tscprinters.com/EN/manuals/TSPL2_TSPL_TSPL3) — a text command language sent over the printer's chosen transport. We will build TSPL commands directly rather than depend on a third-party Flutter package, because pub.dev coverage of TSPL on Flutter is sparse and inconsistent (`flutter_thermal_printer` and similar packages target ESC/POS, which is a different protocol used by receipt printers).

A minimal label looks like:

```
SIZE 50 mm, 30 mm
GAP 2 mm, 0 mm
DIRECTION 1
CLS
TEXT 20, 10, "3", 0, 1, 1, "Zomo Jewellers"
TEXT 20, 50, "2", 0, 1, 1, "<product name>"
TEXT 20, 80, "2", 0, 1, 1, "<grams>g <metal>"
TEXT 20, 110, "2", 0, 1, 1, "Rs. <price>"
BARCODE 20, 150, "128", 80, 1, 0, 2, 2, "<productId>"
PRINT 1, 1
```

Fields are configurable in `LabelTemplate` (§9.3). Label size in v1 is **50 × 30 mm**, the most common jewellery tag size. Different sizes can be added later by parameterising `LabelTemplate`.

### 6.2 Transport abstraction

```dart
abstract class TscTransport {
  Future<void> open();
  Future<void> sendBytes(Uint8List bytes);
  Future<void> close();
}
```

Three implementations:

| Transport | Plugin / API                                          | Platforms                       |
| --------- | ----------------------------------------------------- | ------------------------------- |
| Network   | `dart:io` `Socket` (raw TCP to printer IP, port 9100) | Android, iOS, desktop, **web (no — needs proxy)** |
| Bluetooth | `flutter_blue_plus` (well-maintained BLE/Classic)     | Android, iOS                    |
| USB       | `usb_serial` (Android USB-OTG); `flutter_usb_writer` for desktop. iOS USB requires MFi licensing — out of scope. | Android, desktop |

**v1 ships network transport only** (works everywhere except web, which needs a small proxy — also out of scope). Bluetooth and USB are added in subsequent phases. The abstraction is in place from day one so adding them doesn't ripple through the codebase.

### 6.3 PrinterService

A singleton coordinator above the transport:

```dart
class PrinterService {
  PrinterConfig config; // persisted in SharedPreferences
  TscTransport _transport;
  Future<PrintResult> print(LabelTemplate label, ProductModel product);
  Future<bool> testConnection();
}
```

`PrinterConfig` is stored locally (per-device, per-installation) in `SharedPreferences`:

```json
{
  "transport": "network",
  "host": "192.168.1.50",
  "port": 9100,
  "labelSizeMm": [50, 30],
  "darkness": 8,
  "speed": 4
}
```

A new admin screen (§9.5) lets the user pick the transport, enter address/IP/MAC, and run "Test print".

### 6.4 Where the print button lives

- **Admin product creation flow** (`product_details.dart`): after Save, show a "Print label" action in the success state.
- **Admin product list** (new screen — see §9.6): each row has a Print icon. Bulk select for batch printing.
- **Existing admin entry points** (`gold_rate.dart` Profile menu): add a "Print label" entry in the Product update tab.

## 7. Barcode scanning (user app)

### 7.1 Hardware behavior

TSC scanners are USB-HID or Bluetooth-HID devices that emit scanned text as keystrokes terminated by a configurable suffix (default: Enter / Carriage Return).

### 7.2 Implementation

A new screen `BarcodeScanScreen`:

- Auto-focuses an invisible (or near-invisible) `TextField`.
- Listens for `TextInputAction.done` / `onSubmitted` to capture the full scanned string.
- Validates the string is 8 digits, all 1–9.
- Calls `ProductDao.getProductById(scanned)`.
- On hit: `Navigator.pushReplacement` to `ProductDetailsViewPage`.
- On miss: shows "Product not found — check the barcode and try again" with a tappable Retry.

### 7.3 Entry point

A new icon next to the search icon on `home_screen.dart`. Material icon `Icons.qr_code_scanner` (works for 1D too despite the name).

### 7.4 Web considerations

On web, scanners generally work as USB-HID keyboards with no special permissions. The `TextField` listener pattern works without any plugin. On Android the same is true if the scanner is paired as a Bluetooth-HID device or connected via USB-OTG.

### 7.5 Out of scope (for now)

- Camera-based scanning via `mobile_scanner`. Easy to add later as an optional fallback if the user is on mobile and doesn't have a hardware scanner paired.
- Multi-scan ("scan 5 products in a row"). v1 is single-scan → product detail.

## 8. Migration plan

The existing app uses sequential string IDs (`"1"`, `"2"`, ...) tied to a `sequences/product_sequence` counter. Migration steps:

### 8.1 Pre-flight

1. Take a Firestore export (Console → Firestore → Import/Export → Export). Store off-Firebase.
2. Take a Firebase Storage backup of the `products/` prefix (gsutil cp -r).
3. Snapshot the `Wishlist` collection (export covers this too).

### 8.2 Plan generation (dry-run)

A one-off admin screen `MigrationScreen` (gated behind an explicit "Generate plan" button) does **not write anything**. It:

1. Reads every doc in `Products`.
2. Generates a new 8-digit ID for each, with collision checks against IDs generated so far in this run.
3. Outputs a JSON plan: `[{ oldId, newId, productName }, ...]`
4. Saves the plan to `migrations/{timestampedDocId}` in Firestore for audit.

The admin reviews the plan, optionally exports it.

### 8.3 Execute

A second button "Execute migration" reads the saved plan and, **for each entry**, runs in a `runTransaction`:

1. Read the old product doc.
2. Write a new doc at `Products/{newId}` with the same fields, except `productId = newId` and a new `legacyProductId = oldId` field for traceability.
3. Find every `Wishlist` doc with `productId == oldId` and update it to `productId = newId`. (Outside the transaction if the count exceeds the per-transaction document limit; in that case use a batched write.)
4. Delete the old `Products/{oldId}` doc.

Storage objects (`products/{oldId}/image_$i.jpg`) are **not moved**. The image URLs stored in `ProductModel.images` are full Firebase Storage download URLs that survive doc deletion — they remain valid. New uploads (post-migration) write to `products/{newId}/...` as before. This leaves orphan paths under the old IDs, which we can sweep later or ignore (Storage costs are negligible at this scale).

### 8.4 Post-migration

1. Verify `Products` count matches plan, `Wishlist` references all resolve, no doc has both old and new style IDs.
2. Print updated labels for all in-stock products (use the new batch-print flow from §6.4).
3. Drop the `sequences/product_sequence` doc (kept for now in case rollback is needed — delete after a 2-week stable period).

### 8.5 Rollback

If something goes wrong mid-migration, restore the Firestore export taken in §8.1. The migration plan in `migrations/{...}` records exactly what changed, enabling targeted manual rollback if a full restore is too disruptive.

### 8.6 Existing deep links

Old links of the form `https://zomogold.com/product/1` will break unless we add a redirect. Two options, decide before migrating:

- **Accept the breakage.** Old shared WhatsApp messages stop working. Acceptable if shared product links are short-lived.
- **Add a `legacyProductId` lookup.** `main.dart` deep-link handler tries the literal ID first; if not found and the ID looks legacy (purely numeric, < 8 digits), queries `Products` for `legacyProductId == scanned`. Adds one read per old-link tap. Minor.

Recommendation: implement the `legacyProductId` lookup. It's a 10-line change and protects existing customers.

## 9. Code structure changes

### 9.1 New packages (pubspec.yaml)

```yaml
dependencies:
  barcode: ^2.2.9               # Code 128 preview rendering
  flutter_blue_plus: ^1.32.0    # Bluetooth transport (added in phase 3.b)
  usb_serial: ^0.5.2            # Android USB transport (added in phase 3.c)
```

### 9.2 New directory: `lib/services/`

Pull cross-cutting helpers out of screens. The new code lives here, not in `screens/` or `dao/`.

```
lib/services/
├── product_id_generator.dart       # §4.3
├── barcode_renderer.dart           # §5.2 — Dart-side Code 128 SVG/widget
└── tsc/
    ├── tspl_builder.dart           # §6.1 — pure-Dart TSPL command builder
    ├── label_template.dart         # §9.3
    ├── printer_config.dart
    ├── printer_service.dart        # §6.3
    └── transports/
        ├── tsc_transport.dart      # abstract class
        ├── network_transport.dart
        ├── bluetooth_transport.dart  (phase 3.b)
        └── usb_transport.dart        (phase 3.c)
```

### 9.3 `LabelTemplate`

```dart
class LabelTemplate {
  final int widthMm;
  final int heightMm;
  final List<LabelField> fields;
  // factory LabelTemplate.zomoDefault50x30() => ...
}

abstract class LabelField {
  String render(ProductModel p, BarcodeContext ctx);
}
```

Concrete `LabelField` subclasses: `TextField`, `BarcodeField`, `PriceField`, etc. Each emits a line of TSPL. This makes label layouts editable later without rewriting the printer code.

### 9.4 Modified files

| File                                  | Change                                                                                          |
| ------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `lib/dao/product_dao.dart`            | `generateNextProductId` deleted. Replace call sites with `ProductIdGenerator.generate(productDao)`. Optionally add `getProductByLegacyId`. |
| `lib/screens/product_details.dart`    | Use new ID generator on save. After save, show "Print label" action in the success state.       |
| `lib/screens/home_screen.dart`        | Add `Icons.qr_code_scanner` next to the search icon → push `BarcodeScanScreen`.                 |
| `lib/main.dart`                       | (If implementing legacy redirect) extend the `AppLinks` handler to fall back to `legacyProductId` lookup. |
| `lib/models/product_model.dart`       | Add nullable `String? legacyProductId` field (read-only after migration; ignored on new docs).  |
| `pubspec.yaml`                        | Add `barcode` (phase 1). Add `flutter_blue_plus`, `usb_serial` in their phases.                 |

### 9.5 New screens

| File                                           | Purpose                                                                 |
| ---------------------------------------------- | ----------------------------------------------------------------------- |
| `lib/screens/barcode_scan_screen.dart`         | User-app scan flow (§7).                                                |
| `lib/screens/admin/printer_settings_screen.dart` | Configure transport, host/port/MAC, label size, darkness, test print. |
| `lib/screens/admin/migration_screen.dart`      | Plan + execute the one-time ID migration (§8).                          |
| `lib/screens/admin/product_admin_list_screen.dart` | List of products with print + reprint icons; bulk-select for batch printing. |

### 9.6 Documentation updates (after implementation)

- `CLAUDE.md` — add a section on the ID format and printer abstraction.
- `DOCUMENTATION.md` — describe `lib/services/` layer and the print/scan flows.
- `DATA_MODEL.md` — note `legacyProductId`, document the migration in a history section.

## 10. Phased task breakdown

Each phase is a shippable, testable increment. Tasks within a phase can be parallelized.

### Phase 1 — Foundation (new ID format & barcode preview)

| #   | Task                                                              | Acceptance criteria                                                  |
| --- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1.1 | Add `barcode: ^2.2.9` to `pubspec.yaml`                           | `flutter pub get` succeeds; `import 'package:barcode/barcode.dart'` works. |
| 1.2 | Create `lib/services/product_id_generator.dart`                   | Function `Future<String> generate(ProductDao)` returns 8-digit IDs in 1–9, retries on collision, max 5 attempts. |
| 1.3 | Add unit tests for ID generator                                   | Tests cover digit distribution (no zeros), length, collision retry, exhaustion error path. |
| 1.4 | Create `lib/services/barcode_renderer.dart`                       | Function returns a Flutter `Widget` rendering a Code 128 barcode for a given productId. |
| 1.5 | Update `product_details.dart` save flow to use new generator      | Newly created products get 8-digit IDs. `sequences/product_sequence` is no longer touched. |
| 1.6 | Show barcode preview in admin product detail page                 | After save, the Save button is replaced with a barcode preview + "Print label" button (button is a no-op until phase 3). |

**Phase 1 ships:** new products get 8-digit IDs and a viewable barcode preview. No printing yet, no migration yet, no scanning yet.

### Phase 2 — Migration

| #   | Task                                                              | Acceptance criteria                                                  |
| --- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| 2.1 | Add `legacyProductId` field to `ProductModel` (nullable)          | Field round-trips through `fromSnapshot` / `toJson`. Not breaking for existing docs. |
| 2.2 | Create `MigrationScreen` (admin) — generate-plan stage            | Reads all `Products`, generates new IDs, writes plan JSON to `migrations/{timestamp}`, displays a summary. **No mutations.** |
| 2.3 | Create `MigrationScreen` — execute stage                          | Reads plan, transactionally rewrites product docs and updates `Wishlist.productId` references. Idempotent: re-running with same plan is a no-op. |
| 2.4 | Add legacy-ID fallback in `ProductDao.getProductById`             | If direct fetch misses, query by `legacyProductId`. |
| 2.5 | Extend deep-link handler in `main.dart` (if doing legacy redirect)| Old URLs resolve to the new product detail page.                     |
| 2.6 | Run dry-run, review plan, take backups, run real migration        | All `Products` have new IDs; all `Wishlist` references resolve; no docs lost. |

**Phase 2 ships:** all existing products on the new ID format, deep links still work.

### Phase 3 — Label printing

#### 3.a Network transport (works on all platforms now)

| #   | Task                                                              | Acceptance criteria                                                  |
| --- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| 3.a.1 | Create `tspl_builder.dart`                                      | Pure functions: `size`, `gap`, `cls`, `text`, `barcode`, `print`. Output is a `String` matching the TSPL spec. Unit tested. |
| 3.a.2 | Create `LabelTemplate` and a default 50×30mm Zomo template      | `template.render(product) → tsplCommands`. |
| 3.a.3 | Create `TscTransport` abstract class + `NetworkTransport` impl  | `open` connects via `Socket`, `sendBytes` writes, `close` shuts. Robust to flaky networks. |
| 3.a.4 | Create `PrinterService` singleton + `PrinterConfig` persisted in SharedPreferences | `print(template, product)` succeeds end-to-end. Errors surface to UI. |
| 3.a.5 | Build `PrinterSettingsScreen` (admin)                           | Choose transport, enter host/port, "Test print" emits a known label. |
| 3.a.6 | Wire "Print label" button in product detail save flow + admin product list | Tapping prints a real label on the configured printer. |

**Phase 3.a ships:** admin can print labels from any platform with network access to the printer.

#### 3.b Bluetooth transport

| #   | Task                                                          | Acceptance criteria                                                |
| --- | ------------------------------------------------------------- | ------------------------------------------------------------------ |
| 3.b.1 | Add `flutter_blue_plus` to pubspec                          | Compiles on Android and iOS. |
| 3.b.2 | Implement `BluetoothTransport`                              | Pairs with the printer, sends bytes, closes cleanly. |
| 3.b.3 | Extend `PrinterSettingsScreen` with a Bluetooth device picker | Choose a paired device; "Test print" works. |

#### 3.c USB transport (Android first)

| #   | Task                                                          | Acceptance criteria                                                |
| --- | ------------------------------------------------------------- | ------------------------------------------------------------------ |
| 3.c.1 | Add `usb_serial` to pubspec                                 | Compiles on Android. |
| 3.c.2 | Implement `UsbTransport` for Android                        | Detects connected TSC printer, sends bytes. |
| 3.c.3 | Extend settings UI to pick USB device                       | "Test print" works over USB-OTG. |

### Phase 4 — Scanner UX

| #   | Task                                                              | Acceptance criteria                                                  |
| --- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| 4.1 | Add scan icon next to search on `home_screen.dart`                | Tapping pushes `BarcodeScanScreen`. |
| 4.2 | Build `BarcodeScanScreen`                                         | Auto-focuses input, on Enter validates 8-digit format and calls `getProductById`. Shows clear empty/loading/error states. |
| 4.3 | Wire navigation on hit                                            | `pushReplacement` to `ProductDetailsViewPage`. |
| 4.4 | Wire UX on miss                                                   | "Product not found" message + "Scan another" button. |
| 4.5 | Optional: add `mobile_scanner` camera fallback (mobile only)      | Camera button on the scan screen opens the camera; recognized 8-digit codes are treated identically to keyboard input. |

**Phase 4 ships:** users can scan a printed label and land on the product page.

### Phase 5 — Hardening

| #   | Task                                                              | Acceptance criteria                                                  |
| --- | ----------------------------------------------------------------- | -------------------------------------------------------------------- |
| 5.1 | Print preview dialog                                              | Shows what will print before sending. Cancellable. |
| 5.2 | Batch print from admin product list                               | Multi-select rows, "Print N labels" sends them serialised to the printer. |
| 5.3 | Reprint history per product (optional)                            | Last N print times stored in `Products.printedAt[]` for audit. |
| 5.4 | Documentation refresh (`CLAUDE.md`, `DOCUMENTATION.md`, `DATA_MODEL.md`) | Updated to reflect implementation. |
| 5.5 | Add basic tests for `tspl_builder`, ID generator, scanner input parsing | All pass in CI. |

## 11. Open questions

These should be answered before the relevant phase starts.

1. **Label dimensions and content.** 50 × 30 mm is the proposed default. What store name, fields, and exact layout does Zomo want? This affects `LabelTemplate.zomoDefault50x30`.
2. **Which TSC model(s)?** Most TSC desktop printers (TE200, TX200, TDP-225, etc.) support TSPL2. Knowing the specific model lets us pre-test command compatibility (some older models lack certain commands).
3. **How is the printer wired in the shop?** This determines which transport is built first. If it's connected to a Wi-Fi network, phase 3.a is enough for production. If the staff laptop talks to it over USB, prioritize 3.c.
4. **Legacy deep-link redirect — yes or no?** §8.6. Recommendation is yes; needs explicit confirmation.
5. **Wishlist sequence migration.** §4.4 — should `wishlist_sequence` also move off the non-transactional generator? Recommended, but it's lower urgency since wishlists are user-private and a duplicate ID is recoverable (server-side dedupe by `(userId, productId)`).
6. **Admin role gating.** Currently anyone can hit `GoldRatesScreen`. Before exposing the migration screen, we must add a role check (custom claim or hard-coded admin uid list). This is technically out of scope for this feature but blocks shipping the migration screen safely.
7. **Storage cleanup.** Orphaned `products/{oldId}/...` paths after migration — sweep at the end, or leave?

## 12. Risks and mitigations

| Risk                                                                | Mitigation                                                          |
| ------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Migration corrupts production data                                  | Mandatory dry-run, mandatory backups, transactional writes, and the migration plan stored in Firestore for forensic recovery. Run during off-hours. |
| TSC printer model uses a non-standard TSPL dialect                  | Test phase 3.a against the actual printer before shipping. Keep `tspl_builder` small and clearly mapped to spec sections so we can patch quickly. |
| Bluetooth pairing UX is brittle on Android 12+                      | Use `flutter_blue_plus` (modern, actively maintained). Document the runtime permissions added to `AndroidManifest.xml`. |
| HID scanner emits unexpected suffix (e.g. tab instead of CR)        | Configure the scanner once (manual scanner config sheets ship with the device). The app accepts both \r and \n as terminators just in case. |
| Old WhatsApp links break after migration                            | Implement the `legacyProductId` fallback (§8.6).                    |
| ID collisions despite 43M namespace                                 | Collision check on every generation. 5-retry cap. Logging on retry so we'd notice if it ever happens. |
| Web build can't print over USB / Bluetooth                          | Document this. Network transport (phase 3.a) covers web. Direct printing from web is not a v1 requirement. |
| No security rules → anyone can run the migration                    | Block the migration screen behind admin role check (open question 6) before phase 2 ships. |

## 13. Estimated effort

Rough order-of-magnitude, assuming one developer familiar with Flutter and Firestore:

| Phase                       | Effort       |
| --------------------------- | ------------ |
| 1. Foundation               | 2–3 days     |
| 2. Migration                | 3–4 days (incl. dry-run reviews and the actual migration window) |
| 3.a Network printing        | 3–4 days     |
| 3.b Bluetooth printing      | 2–3 days     |
| 3.c USB printing            | 2–3 days     |
| 4. Scanner UX               | 1–2 days     |
| 5. Hardening                | 2–3 days     |
| **Total**                   | **~3 weeks** |

Phases 1, 2, 3.a, and 4 are the critical path to "feature usable in store". Phases 3.b, 3.c, and 5 can follow once the basics are validated.

## 14. Suggested order of execution

1. Get answers to the open questions in §11 (especially #2, #3, #4, #6).
2. Phase 1 (new IDs + barcode preview) — independent, no risk.
3. Phase 3.a (network printing) — independent of migration, lets us start printing for **new** products immediately.
4. Phase 2 (migration) — once printing works, we can re-print labels for backfilled products.
5. Phase 4 (scanner) — once §10's IDs and barcodes are real, scanning has something to read.
6. Phases 3.b / 3.c (more transports) and Phase 5 (hardening) — as needed.

---

When you're ready, mark the open questions as answered (or accept the recommendations) and we'll start with Phase 1.
