# Zomo Gold App — User Guide

A walkthrough of every feature in the Zomo Gold app, written for shoppers and store staff. The app showcases the Zomo Jewellers (Hyderabad) catalog of gold, silver, diamond, and platinum jewellery. There is no in-app checkout — interested buyers contact the shop directly via WhatsApp or phone call.

## 1. Getting started

The app runs on Android phones, iPhones, and any modern web browser. When you open it for the first time, you'll be taken to the login screen.

### Logging in with your phone number

1. Enter your 10-digit Indian mobile number. The country code `+91` is added for you.
2. Tap **Send OTP**.
3. You'll receive a 6-digit code by SMS. Enter it in the six boxes on the next screen.
4. Tap **Verify**. If the code is correct, you'll go straight to the home screen.

If you don't receive the SMS within 30 seconds, a **Resend OTP** option appears below the verify button. The "Login as guest" button in the top-right of the login screen is currently inactive.

## 2. The home screen

After logging in, you land on the home screen. From top to bottom:

- **App bar** — A logo placeholder, a search icon, a wishlist (♡) icon, and a shopping bag icon.
- **Hero banner** — A featured image highlighting the latest collection.
- **Shop By** — Three pill buttons (Gold, Silver, Diamond) that take you to a filtered product list.
- **Shop by category** — A 4-column grid of jewellery types: Rings, Necklaces, Nose accessories, Silver coins, Pendants, Earrings, Bracelets, and Anklets. Tap any tile to see all products in that category.
- **Shop by** (people) — Three avatars: Men, Women, Boy. Tap one to filter for jewellery suited to that audience.
- **About us** — Address footer for Zomo Jewellers Pvt. Ltd., Hyderabad.

At the bottom there's a four-tab navigation bar:

| Tab        | What it does                                    |
| ---------- | ----------------------------------------------- |
| Home       | Returns to this screen.                         |
| Category   | Placeholder — full implementation coming soon.  |
| Orders     | Placeholder — your past orders will appear here once order tracking is added. |
| Profile    | Opens the Admin screen (currently not gated). For most users this is not relevant. |

## 3. Searching for jewellery

Tap the search icon in the home app bar. You'll see:

- **Search bar** at the top. Start typing and matching product names appear in a dropdown. Tap a suggestion to jump directly to those products. You can also type a free-form term and press the search icon or hit Enter.
- **Recent searches** — Up to five of your most recent searches show as pill chips. Tap one to repeat the search.
- **Top recommendations** — Quick filters: Gold jewellery, Silver jewellery, Men's, Ladies, New born.
- **Trending searches** — Common searches as rectangular chips.

## 4. The product list (grid)

You'll arrive on a grid of products whenever you tap a category, a Shop-by tile, a recommendation, or perform a search. Each product card shows:

- The first product image.
- A heart icon in the top-right — tap to add or remove from your wishlist.
- The current selling price (live, computed from today's metal rate).
- The MRP with a strike-through (so you can see the discount).
- The product name (or category name if the product has no name).

Scroll down to load more products automatically (20 at a time).

### Sorting

Tap **Sort by** in the bottom bar to choose:

- **New Arrivals** — most recently added first (default)
- **Popular** — most viewed first
- **Low to high price** — cheapest first (computed using today's metal rate)
- **High to low price** — most expensive first

### Filtering

Tap **Filter** in the bottom bar. The filter screen has four sections in a left-side menu:

- **Product type** — pick one or more categories (Rings, Necklaces, etc.).
- **Price** — drag the range slider between ₹0 and ₹20,00,000. The selected range is shown as a chip and in the two boxes below.
- **Metal** — Platinum, Gold, Silver, Diamond.
- **Gender** — Male, Female, Kids, Unisex.

A small count badge appears next to each section showing how many filters are active. **Reset** clears everything; **Apply Filter** returns you to the grid with the new filters.

The number of active filters is also shown next to "Filter" in the bottom bar, so you can see at a glance how restrictive your view is.

## 5. The product detail page

Tap any card to open the detail page.

- **Image gallery** — swipe through all photos. Page indicators below show your position. Tap an image to open the full-screen viewer (pinch to zoom, swipe to flip through).
- **Header row** — metal name on the left; heart (wishlist) and share icons on the right.
- **Prices** — strike-through MRP and the bigger selling price below it. "MRP Incl. of all taxes" is noted in small text.
- **Info chips** — show the carat purity (e.g. "22 karat") and the making charge percentage.
- **Product details** and **Specifications** — collapsible sections with rich-text content provided by the store.
- **You May Also Like** — a horizontal carousel of related products in the same metal.

### Ordering a product

Two big buttons sit at the bottom of the detail page:

- **Order on WhatsApp** (green) — opens WhatsApp with a pre-filled message containing the product name, current price, and a deep link back to the product. The store WhatsApp number is hard-coded in the app.
- **Call to Order** (purple) — opens your phone's dialer with the store's number ready to call.

Both routes connect you directly with Zomo Jewellers staff, who finalize details (purity verification, customization, payment, delivery).

### Sharing a product

Each product has a unique link in the form `https://zomogold.com/product/{id}`. When this link is sent via WhatsApp or any other channel and tapped on a device with the app installed, it opens the product detail page directly.

## 6. The wishlist

Tap the heart icon in any app bar to view all your saved products. Each saved item shows the same card layout, with two extra controls below:

- **Trash icon** — opens a confirmation sheet. Tap **Remove** to delete the item from your wishlist.
- **Add to Bag** — currently a placeholder; cart functionality is not yet implemented.

Your wishlist is tied to the phone number you logged in with, so it persists across devices when you log in with the same number.

## 7. The cart and orders (placeholder)

Both the **cart** and **My Orders** screens currently show empty-state messages. Cart and order tracking are planned for a future release. To purchase, use the WhatsApp or Call buttons on the product detail page.

## 8. Admin features

These are accessed from the **Profile** tab in the bottom nav. There is no role gating today, so anyone who reaches this screen can use them — exercise care.

### Updating gold and silver rates

The **Rate update** tab shows two cards: **CURRENT GOLD RATE** (per gram) and **CURRENT SILVER RATE** (per kilogram), pulled from a live external feed. A refresh icon refetches the latest figures.

To record a new in-store rate:

1. Swipe horizontally to the GOLD or SILVER card. The active metal is the one currently centered.
2. Scroll down to **UPDATE GOLD RATE** (or SILVER) and enter your store's rate.
3. Optionally add **Remarks** (e.g. "Diwali sale rate").
4. Tap **Update Rate**.

The new rate is saved with a timestamp and a snapshot of the live API rate at the same moment, for audit purposes. All product prices across the app immediately recompute against the latest manual rate.

### Viewing rate history

Tap **View History** on either rate card. You can:

- Pick a time range from the dropdown (1 Day, 1 Week, 1 Month, 3 Months, 6 Months, 1 Year).
- See a line chart with two series: **Rate** (your manually entered rates, in purple) and **Live Rate** (the API snapshots, in cyan).
- Scroll the list below the chart to see every individual entry with its timestamp and rate.

### Adding a new product

Switch to the **Product update** tab. Fill in:

1. **Product images** — tap the **+** square to upload up to 10 images. Each thumbnail can be dragged to reorder. Tap the red ✕ to remove a thumbnail. **Clear All** removes every image.
2. **Product Name** — what shoppers will see on the card and in search.
3. **Metal Name** — Platinum, Gold, Silver, or Diamond.
4. **Carats** — 14, 18, 20, 22, 23, or 24.
5. **Suitable For** — Male, Female, Children, or Unisex.
6. **Category** — choose from the categories already in the catalog.
7. **No. Of Grams** — net weight of the metal.
8. **Stone Weight** — and unit (Gram, Carat, Cents, Piece).
9. **Stone Cost** — per unit weight.
10. **Making Charges** — and type (% or Flat).
11. **Discount** — flat ₹ amount (the field is named "%" but is currently treated as a flat amount).
12. **Product Details** — rich text describing the product.
13. **Specifications** — rich text with materials, dimensions, certifications, etc.
14. **Hallmark Available** — tick if the product carries hallmark certification.

When you tap **Save Product**, the app validates required fields, uploads images to cloud storage, and writes the product to the catalog. A green toast confirms success. The product appears in browsing immediately.

## 9. Tips for shoppers

- **Prices update live.** The grid and detail pages always recalculate prices using the most recent rate set by the store. If you saw ₹X yesterday, today's price may differ — that's gold and silver markets, not the app.
- **Wishlist before you compare.** Tap the heart on as many products as you like; reviewing the wishlist later side-by-side is much faster than scrolling the grid.
- **Use filters together.** Combining a category, a metal, and a price range usually narrows tens of products down to a handful that match what you actually want.
- **Sharing works.** Every product has a unique link. Send it to a family member to discuss before contacting the store.

## 10. Tips for store staff

- **Update the rate before opening the shop.** All prices the user sees are derived from your latest manual rate. Stale rates lead to awkward conversations with customers.
- **Add remarks to rate updates.** Makes the history screen useful when reviewing later.
- **Quality matters for product images.** Up to 10 photos per product, drag to reorder so the best shot is first — that's the one customers see in the grid.
- **Pricing: making charges field accepts both % and flat ₹.** Pick the type from the dropdown. (Note: pricing in the live app currently treats every product as flat — confirm with the developers before relying on percentage making charges.)
- **Discount is a flat ₹ amount.** Despite the field being labelled with `%` in the form, it is subtracted from the MRP as a rupee value when prices are displayed.
