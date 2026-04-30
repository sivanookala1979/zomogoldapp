# Zomo Gold App — Data Model Reference

Authoritative reference for Firestore collections, Dart models, and the screens that read/write them. For the broader architecture see `DOCUMENTATION.md`.

## 1. Firestore overview

The app uses **five top-level collections** in the `zomo-1f300` Firestore database:

| Collection      | Purpose                                                        | Doc-ID strategy                                |
| --------------- | -------------------------------------------------------------- | ---------------------------------------------- |
| `Products`      | Catalog (rings, necklaces, etc.)                               | `productId` from `sequences/product_sequence`  |
| `Category`      | Category metadata used for filters and grouping                | Auto / numeric (a separate `id` field is also stored on the doc) |
| `Wishlist`      | One entry per (user, product) saved item                       | `wishlistId` from `sequences/wishlist_sequence`|
| `product_rate`  | Append-only history of gold/silver rate updates                | `${PRODUCT_TYPE}_${epochMillis}`               |
| `sequences`     | Monotonic counter docs for sequential IDs                      | `product_sequence`, `wishlist_sequence`        |

There is no `Users` collection — user identity comes from Firebase Auth (phone provider) and is referenced by `uid` strings in `Wishlist.userId`, `Products.userId`, and `product_rate.userId`.

## 2. `Products` collection

Document shape (as serialized by `ProductModel.toJson()` in `lib/models/product_model.dart`):

| Field                | Type            | Description                                                   |
| -------------------- | --------------- | ------------------------------------------------------------- |
| `productId`          | String          | Sequential ID; also used as the Firestore doc ID.             |
| `categoryId`         | String          | Reference to a `Category.id`.                                 |
| `productName`        | String          | User-visible name. Defaults to `""` on read.                  |
| `productNameLower`   | String          | Lowercase copy used for prefix search (`>=` / `<=` queries).  |
| `userId`             | String          | Firebase Auth uid of the admin who created the product. Often `""`. |
| `images`             | List&lt;String&gt; | Firebase Storage download URLs. Path: `products/{productId}/image_$i.jpg`. |
| `metalName`          | String          | One of `Platinum`, `Gold`, `Silver`, `Diamond`, or `Select`.  |
| `carats`             | String          | One of `14`, `18`, `20`, `22`, `23`, `24`, or `Select`. Stored as a string for legacy reasons; parsed in `PriceCalculator`. |
| `metalGrams`         | double          | Net metal weight.                                             |
| `stoneWeight`        | double          | Stone weight; unit defined by `stoneWeightUnit`.              |
| `stoneCost`          | double          | Cost per unit weight of stone.                                |
| `stoneWeightUnit`    | String          | One of `Gram`, `Carat`, `Cents`, `Piece`, or `Select`.        |
| `purity`             | double          | Currently always `0.0` (form does not capture this).          |
| `makingCharges`      | double          | Either flat ₹ or percentage; the type is **not** persisted.   |
| `discount`           | double          | Subtracted as a flat ₹ amount from MRP at read time.          |
| `tagId`              | String          | Reserved; currently always `""`.                              |
| `productInformation` | String          | `flutter_quill` JSON delta serialized as string.              |
| `specifications`     | String          | `flutter_quill` JSON delta serialized as string.              |
| `hallmark`           | bool            | True if hallmark certification available.                     |
| `createdTimestamp`   | Timestamp       | Firestore `Timestamp`. Used as the default sort key.          |
| `modifiedTimestamp`  | Timestamp       | Currently set to the same value as `createdTimestamp` on create. |
| `gender`             | String          | One of `Male`, `Female`, `Children`, `Unisex`, or `Select`.   |
| `viewCount`          | int             | Atomically incremented when the product detail page opens.    |

### Reads

| Where                          | How                                                   |
| ------------------------------ | ----------------------------------------------------- |
| `home_screen.dart`             | Loads `Category` for category-name lookup.            |
| `grid_screen.dart`             | Paginated query (`limit(20)` + `startAfterDocument`) with `whereIn` on `categoryId` / `gender` / `metalName` and `orderBy` on `createdTimestamp` or `viewCount`. |
| `search_screen.dart`           | Prefix query on `productNameLower`.                   |
| `wishlist_screen.dart`         | `whereIn` on `productId` (capped at 10 per query).    |
| `product_view_page.dart`       | `ProductDao.getProductById` then `getProductsByMetal` for "You may also like". |

### Writes

| Where                          | How                                                   |
| ------------------------------ | ----------------------------------------------------- |
| `product_details.dart` (admin) | `ProductDao.addProduct` after generating an ID and uploading images. |
| `product_view_page.dart`       | `ProductDao.recordView` → `viewCount: FieldValue.increment(1)`. |

### Notable indexes likely required

- `Products`: `productNameLower` ASC (prefix search) — auto-handled.
- `Products`: composite indexes for `(metalName, createdTimestamp DESC)`, `(gender, createdTimestamp DESC)`, `(categoryId, createdTimestamp DESC)`, and the same with `viewCount DESC`.

## 3. `Category` collection

Used by `CategoryService` and several screens to render filter UIs and to translate category IDs to names.

| Field   | Type   | Description                                  |
| ------- | ------ | -------------------------------------------- |
| `id`    | int / String | Numeric category ID (read with `.toString()`). |
| `name`  | String | Display name (e.g. "Rings", "Necklaces").    |

The `name` is shown in the filter side-tab and the search trending chips. The `id` is what's stored on `ProductModel.categoryId`.

### Reads

| Where                  | Notes                                                       |
| ---------------------- | ----------------------------------------------------------- |
| `category_service.dart` | Loads once, caches in memory; `getCategoryName(id)` lookup. |
| `home_screen.dart`     | `_getCategoryIdByName` reverse lookup for hard-coded categories. |
| `grid_screen.dart`     | Direct fetch for filter chips and category-name display.    |
| `filter_screen.dart`   | Renders the "Product type" tab.                             |
| `product_details.dart` | Renders the category dropdown in admin form.                |
| `search_screen.dart`   | Reverse lookup when user taps a category chip.              |

### Writes

There is no admin UI for adding categories. They are seeded directly in Firestore.

## 4. `Wishlist` collection

| Field         | Type          | Description                              |
| ------------- | ------------- | ---------------------------------------- |
| `wishlistId`  | String        | Sequential ID; also used as the doc ID.  |
| `userId`      | String        | Firebase Auth uid.                       |
| `productId`   | String        | Reference to `Products.productId`.       |
| `createdAt`   | String (ISO 8601) | Stored via `DateTime.toIso8601String()`. Parsed on read with `DateTime.parse`. |

### Reads

| Where                  | How                                                     |
| ---------------------- | ------------------------------------------------------- |
| `product_card.dart`    | `WishlistDao.isProductInWishlist(uid, productId)` to render the heart toggle state. |
| `product_view_page.dart` | Same — for the heart icon in the header.              |
| `wishlist_screen.dart` | `WishlistDao.getWishlistForUser(uid).first` then `whereIn` on `productId` (Firestore caps at 10). |

### Writes

| Where                  | How                                                     |
| ---------------------- | ------------------------------------------------------- |
| `product_card.dart`    | `addProduct` / `removeProduct` on heart toggle.         |
| `product_view_page.dart` | Same.                                                 |

`removeProduct` queries by `(userId, productId)` and deletes every matching doc — protective against duplicates if `addProduct` is ever called twice for the same pair.

### Notable index required

`Wishlist`: composite index on `(userId, createdAt DESC)`. Firestore prompts to create it on first run of the wishlist screen.

## 5. `product_rate` collection

Append-only log of gold/silver rate updates. Each entry captures both the manually entered rate and a snapshot of the live API rate at the moment of update.

| Field          | Type     | Description                                                        |
| -------------- | -------- | ------------------------------------------------------------------ |
| `id`           | String   | Format: `${PRODUCT_TYPE}_${epochMillis}`. Used as the doc ID.       |
| `productType`  | String   | `GOLD` or `SILVER` (uppercase).                                     |
| `price`        | double   | Manual rate entered by admin.                                       |
| `livePrice`    | double   | API rate snapshot at the same instant.                              |
| `unit`         | String   | `per 1g` (gold) or `per KG` (silver).                               |
| `userId`       | String   | Currently always `'admin'`.                                         |
| `timestamp`    | int      | `DateTime.now().millisecondsSinceEpoch`.                            |
| `remarks`      | String   | Optional admin comment. Defaults to `''`.                           |

### Reads

| Where                  | How                                                                       |
| ---------------------- | ------------------------------------------------------------------------- |
| `gold_rate.dart`       | None — this screen only writes. The current rate is fetched from the external API, not from this collection. |
| `history_screen.dart`  | `ProductRateDao.getFilteredRates(type, startTs, endTs)` — live stream sorted by `timestamp` desc. |
| `grid_screen.dart`, `wishlist_screen.dart`, `product_view_page.dart`, `product_card.dart` | All call `getLatestRateByType(metal)` to compute selling prices in real time. |

`getLatestRateByType` runs:

```
product_rate
  where productType == metal.toUpperCase()
  orderBy timestamp desc
  limit 1
```

Returns `0.0` if no entries exist — which silently produces ₹0 prices. Seed at least one row per metal in production.

### Writes

| Where             | How                                          |
| ----------------- | -------------------------------------------- |
| `gold_rate.dart`  | `ProductRateDao.addRateEntry(model)` on "Update Rate" form submit. |

### Notable index required

`product_rate`: composite index on `(productType, timestamp)`.

## 6. `sequences` collection

Two counter documents.

| Doc ID              | Field     | Type | Used by                         |
| ------------------- | --------- | ---- | ------------------------------- |
| `product_sequence`  | `nextId`  | int  | `ProductDao.generateNextProductId()`  |
| `wishlist_sequence` | `nextId`  | int  | `WishlistDao.generateNextWishlistId()`|

Both DAOs read, increment, and write back **without a transaction**. Concurrent admin writes can collide and produce duplicate IDs. If you start needing real concurrency, switch to `FirebaseFirestore.runTransaction` or use Firestore-generated doc IDs and stop relying on numeric sequences.

If the document doesn't exist, the code creates it with `nextId: 1` and returns `1`. On any error it falls back to `DateTime.now().millisecondsSinceEpoch`.

## 7. Firebase Auth users

The app does not store user records in Firestore. Authentication is phone-based (`+91` country code hard-coded in `phone_login_screen.dart`). The `User.uid` returned by `FirebaseAuth.instance.currentUser` is what's referenced in `Wishlist.userId`, `Products.userId`, and `product_rate.userId`.

There is no profile screen, no display name, no email — the Profile tab in the bottom nav opens the admin `GoldRatesScreen` instead.

## 8. Firebase Storage

| Path                              | Content                                            |
| --------------------------------- | -------------------------------------------------- |
| `products/{productId}/image_$i.jpg` | Product images. `i` is 0-indexed up to 9 (max 10 per product). Uploaded by `product_details.dart`; URLs are written into `Products.images`. |

There is no cleanup when products are deleted — `ProductDao.deleteProduct` removes the Firestore doc but leaves orphan images in Storage.

## 9. Screen → data flow summary

| Screen                       | Reads                                                  | Writes                                       |
| ---------------------------- | ------------------------------------------------------ | -------------------------------------------- |
| `phone_login_screen.dart`    | (Firebase Auth)                                        | (Firebase Auth)                              |
| `otp_verification_screen.dart` | (Firebase Auth)                                      | (Firebase Auth)                              |
| `home_screen.dart`           | `Category`                                             | —                                            |
| `search_screen.dart`         | `Products` (prefix search), `Category`, `SharedPreferences` | `SharedPreferences` (recent searches)   |
| `grid_screen.dart`           | `Products`, `Category`, `product_rate`                 | —                                            |
| `filter_screen.dart`         | `Category`                                             | — (returns selections to caller)             |
| `product_card.dart`          | `Wishlist` (existence)                                 | `Wishlist` (add/remove)                      |
| `product_view_page.dart`     | `Products`, `Wishlist`, `product_rate`                 | `Products.viewCount`, `Wishlist`             |
| `wishlist_screen.dart`       | `Wishlist`, `Products`, `product_rate`                 | —                                            |
| `product_details.dart` (admin) | `Category`, `sequences/product_sequence`             | `Products`, `sequences/product_sequence`, Storage `products/...` |
| `gold_rate.dart` (admin)     | external API (dpgold.in)                               | `product_rate`                               |
| `history_screen.dart`        | `product_rate`                                         | —                                            |
| `cart_screen.dart`, `orders_screen.dart`, `category_screen.dart` | — (stubs)                          | —                                            |

## 10. Recommended Firestore security rules (not currently in repo)

These rules are not enforced today. As a starting point:

```
service cloud.firestore {
  match /databases/{db}/documents {
    function isSignedIn() { return request.auth != null; }
    function isAdmin()    { return isSignedIn() && request.auth.token.admin == true; }

    match /Products/{id}        { allow read: if true;       allow write: if isAdmin(); }
    match /Category/{id}        { allow read: if true;       allow write: if isAdmin(); }
    match /product_rate/{id}    { allow read: if true;       allow write: if isAdmin(); }
    match /sequences/{id}       { allow read, write: if isAdmin(); }
    match /Wishlist/{id} {
      allow read:   if isSignedIn() && resource.data.userId == request.auth.uid;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
  }
}
```

Set the `admin` custom claim on admin Firebase Auth users via the Admin SDK or a Cloud Function.
