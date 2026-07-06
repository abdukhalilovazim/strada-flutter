# Strada Pizza — AI Agent Operational Guide

> **Scope:** This file defines strict execution rules, architecture constraints, and performance mandates for any AI agent working on the Strada Pizza Flutter codebase.

---

## 1. Architecture Overview

### 1.1 Pattern: Feature-First Clean Architecture + BLoC

```
lib/
├── core/                         # Shared infrastructure
│   ├── constants/                # ApiConstants, AppConstants
│   ├── di/                       # get_it + @injectable DI
│   ├── error/                    # Failure classes (dartz Either<Failure, T>)
│   ├── network/                  # GraphQL client (single link chain)
│   ├── router/                   # go_router configuration
│   ├── storage/                  # SecureStorage, SharedPrefs
│   ├── theme/                    # AppColors, AppTextStyles, AppTheme, AppIcons, AppDimensions
│   ├── utils/                    # DeviceInfoHelper, validators, NumberFormatter
│   └── widgets/                  # AppButton, AppShimmer, AppTextField
├── features/
│   ├── auth/                     # Login + OTP (data → domain → presentation)
│   ├── cart/                     # Cart management (domain → presentation)
│   ├── home/                     # Products, categories, sliders (data → domain → presentation)
│   ├── orders/                   # Order history + detail (data → domain → presentation)
│   ├── profile/                  # Settings page (presentation only)
│   └── splash/                   # Splash + can_order check (presentation only)
├── l10n/                         # uz.json, ru.json, en.json
├── generated/                    # locale_keys.g.dart (NOT used — .tr() only)
└── main.dart                     # Entry point, global BlocProviders
```

### 1.2 Data Flow

```
UI (Widget) → Cubit → UseCase → Repository → DataSource → GraphQL API
                ↓
        State emission → UI rebuild
```

### 1.3 Technology Stack

| Layer            | Library                        | Version        |
|------------------|--------------------------------|----------------|
| State Management | `flutter_bloc` (Cubit)         | ^8.1.6         |
| DI               | `get_it` + `injectable`        | ^8.0.2 / ^2.4.4|
| API Client       | `graphql_flutter`              | ^5.2.0-beta.7  |
| Navigation       | `go_router`                    | ^14.6.2        |
| Localization     | `easy_localization`            | ^3.0.7         |
| Secure Storage   | `flutter_secure_storage`       | ^9.2.2         |
| Maps             | `flutter_map` + `geolocator`   | ^7.0.2 / ^13.0.2|
| Firebase         | `firebase_core` + `firebase_messaging` | ^3.8.1 / ^15.1.6 |

### 1.4 Global vs Scoped Cubits

| Cubit       | Scope   | Provided In                       |
|-------------|---------|-----------------------------------|
| `HomeCubit` | Global  | `main.dart` → `MultiBlocProvider` |
| `CartCubit` | Global  | `main.dart` → `MultiBlocProvider` |
| `AuthCubit` | Scoped  | Feature-level `BlocProvider`      |
| `OrderCubit`| Scoped  | Feature-level `BlocProvider`      |
| `SplashCubit`| Scoped | Feature-level `BlocProvider`      |

---

## 2. Strict Operational Rules

### 2.1 Dead Code Elimination ⚠️ MANDATORY

During **every** code modification, the agent **MUST**:

1. **Remove unused imports** — Run conceptual `dart fix --apply` checks. Every `import` must be referenced.
2. **Delete dead variables** — Any variable assigned but never read must be removed.
3. **Remove orphaned methods** — Private methods (`_methodName`) not called anywhere in the file must be deleted.
4. **Clean unused widgets** — Widget classes not referenced in any route, builder, or parent widget must be removed.
5. **Prune stale state fields** — Cubit state fields not consumed by any `BlocBuilder`/`BlocListener` must be removed.
6. **Remove commented-out code** — Blocks of commented code (not documentation comments) must be deleted.

> **Rule:** Never leave dead code "for later." If it's not used now, it doesn't exist.

### 2.2 API Minimization & Performance ⚡ MANDATORY

#### Widget Rebuild Optimization
- Use `const` constructors on **every** widget and parameter that allows it.
- Never use `setState()` in a `StatelessWidget` or inside a `BlocBuilder`. Use `Cubit.emit()`.
- Prefer `BlocSelector` over `BlocBuilder` when only a subset of state fields triggers a rebuild.
- Extract heavy subtrees into separate `const` widgets to isolate rebuilds.
- Never create objects (lists, maps, callbacks) inline inside `build()` — hoist them to class-level or use `const`.

#### GraphQL / Network Efficiency
- **No duplicate requests:** Before adding a new GraphQL call, verify the data isn't already available in an existing Cubit state.
- **No redundant fetches:** `HomeCubit.init()` fetches products + categories + sliders in parallel. Never re-fetch individually.
- **Client-side filtering only:** Products are fetched once; category filtering happens in-memory via `category.slug` match.
- **Debounce mutations:** Never fire the same mutation (e.g., `createOrder`) twice. Disable UI trigger after first tap.
- **Cache-first:** Use GraphQL cache policies (`CachePolicy.cacheFirst`) for static data (settings, categories, branches).
- **60s timeout:** All network operations MUST have a 60-second `connectionTimeout`. No exceptions.

#### State Management Efficiency
- Emit **new state objects** — never mutate existing state.
- One Cubit per domain concern — no god cubits handling unrelated logic.
- Don't duplicate data across Cubits — reference `HomeCubit` for product data in `CartCubit`, not a copy.

### 2.3 Token Efficiency 📏 MANDATORY

When responding to code modification requests:

1. **Minimal diffs only** — Output only the changed lines with surrounding context (3–5 lines). Never reprint an entire file or widget tree.
2. **Targeted snippets** — Reference files by path and line range, e.g., "In `lib/features/home/presentation/pages/home_page.dart:42-58`, replace..."
3. **No boilerplate repetition** — Don't repeat import blocks, class declarations, or unchanged methods. Use `// ... existing code ...` markers.
4. **Batch related changes** — Group all edits to a single file in one response block, not scattered across the conversation.
5. **Use file references** — Point to existing implementations instead of re-explaining them. E.g., "Follow the pattern in `AuthCubit`."

### 2.4 Localization Enforcement 🌐 MANDATORY

- **Zero hardcoded strings** in UI. Every user-visible string MUST use `'key'.tr()`.
- New strings MUST be added to ALL 3 locale files: `uz.json`, `ru.json`, `en.json`.
- Error messages from the server should be displayed as-is (they arrive pre-localized via the `language` header).
- `locale_keys.g.dart` exists but is **NOT used** — only raw string keys with `.tr()`.

### 2.5 Code Style & Documentation 📝 MANDATORY

- Every new public method/class MUST have a `///` Dart doc comment.
- Follow `flutter_lints` rules from `analysis_options.yaml`.
- Use `AppColors`, `AppTextStyles`, `AppDimensions` from the design system — no magic numbers or hex literals.
- Format all prices via `NumberFormatter.formatSum(price)` — raw `.toInt()` or `.toString()` on prices is **FORBIDDEN**.
- `flutter_screenutil` is **NOT used** — responsiveness via `MediaQuery` and `LayoutBuilder` only.
- **Type Safety & Nullability**: Always verify method parameters and type constraints. When passing optional callbacks (like disabled state callbacks), declare parameters as nullable (e.g. `VoidCallback?`) to avoid compile errors. Ensure no nullable types are assigned to non-nullable ones.

### 2.6 File Organization Rules 📁

- **Feature-first:** All feature code lives under `lib/features/<feature_name>/`.
- **Clean Architecture layers** within each feature: `data/` → `domain/` → `presentation/`.
- Shared code lives in `lib/core/`. Never put feature-specific code in core.
- New shared widgets go in `lib/core/widgets/`.
- New constants go in `lib/core/constants/`.

### 2.7 Dependency Injection Rules 💉

- All injectable classes use `@injectable` or `@LazySingleton` annotations.
- After adding new injectable classes, remind to run:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Never manually register in `get_it` — always go through `@injectable` code generation.

---

## 3. Navigation Contract

| Route            | Widget             | Auth Required |
|------------------|--------------------|---------------|
| `/splash`        | `SplashPage`       | No            |
| `/auth/login`    | `LoginPage`        | No            |
| `/auth/otp`      | `OtpPage`          | No            |
| `/home`          | `HomePage`         | Yes           |
| `/cart`          | `CartPage`         | Yes           |
| `/orders`        | `OrdersPage`       | Yes           |
| `/profile`       | `ProfilePage`      | Yes           |
| `/product/:slug` | `ProductDetailPage`| Yes           |
| `/checkout`      | `CheckoutPage`     | Yes           |
| `/order/:id`     | `OrderDetailPage`  | Yes           |
| `/map-picker`    | `MapPickerPage`    | Yes           |

- Auth redirect: If `SecureStorage.getToken()` returns `null`, redirect to `/auth/login`.
- Pass complex objects via `extra:` parameter (e.g., `ProductEntity`, `OrderEntity`).

---

## 4. GraphQL Schemas

| Schema  | Endpoint            | Operations                                                    |
|---------|---------------------|---------------------------------------------------------------|
| Common  | `/graphql/common`   | Products, Categories, Settings, Branches, Login, ConfirmOtp   |
| Order   | `/graphql/order`    | Orders, Order, CreateOrder, CheckPromoCode, CalculateDeliveryPrice |

### Routing Rule
Operations are routed via `Link.split` based on operation name. Order-schema operations: `orders`, `Orders`, `order`, `Order`, `createOrder`, `checkPromoCode`, `calculateDeliveryPrice`.

### Security Headers (Mutations Only)
Every mutation includes HMAC-SHA256 signature:
```
Header-Random-Str: <16-char random string>
Header-Timestamp:  <current time in ms>
Header-Sign:       HMAC-SHA256(jsonEncode(variables) + randomStr + timestamp, HMAC_SECRET)
```

---

## 5. Design System Quick Reference

| Token              | Value / Class                    |
|--------------------|----------------------------------|
| Primary Color      | `AppColors.primary` (`0xFFD32F2F`) |
| Secondary Color    | `AppColors.secondary` (`0xFF2E7D32`) |
| Card Radius        | `16px` (OrderCard), `20px` (ProductCard) |
| Shadow             | `Colors.black.withOpacity(0.04)`, `blurRadius: 10` |
| Font Family        | Inter (via `google_fonts`)       |
| Grid Aspect Ratio  | `0.68` (ProductCard grid)        |
| Slider Viewport    | `0.92` fraction, `20px` radius   |

---

## 6. Pre-Modification Checklist

Before making **any** code change, verify:

- [ ] No duplicate GraphQL operation exists for the same data
- [ ] New strings are added to all 3 locale files
- [ ] `const` is used wherever possible
- [ ] Prices use `NumberFormatter.formatSum()`
- [ ] No unused imports remain after the edit
- [ ] Injectable classes are annotated correctly
- [ ] Widget builds don't create inline objects
- [ ] Error states are handled with localized messages

---

## 7. Terminal Execution Rules 🚫 MANDATORY

- **NEVER run terminal commands** (`flutter run`, `flutter build`, `dart run`, `build_runner`, etc.).
- The developer handles **all** command execution manually.
- The agent's role is strictly limited to **code generation, editing, and analysis**.
- If a command needs to be run (e.g., `build_runner`), **mention it in the response** but do NOT execute it.

### 9.7 `loyalty` Feature (Rejalashtirilgan)

**Maqsad:** Faol foydalanuvchilarni rag'batlantirish va uxlab qolgan (lapsed) mijozlarni qaytarish (win-back).

**1. Ball (Point) Tizimi:**
- Har bir buyurtma summasidan **3%** avtomatik ball sifatida qaytadi.
- **1 ball = 1 so'm** chegirma.
- Muddat: **45 kun**. Agar ishlatilmasa ballar avtomatik yonib ketadi.
- Bonuslar: Birinchi buyurtma (+5,000 ball), Tug'ilgan kun (+10,000 ball), Referral (+10,000 ball).
- **UX:**
  - `Profile/Home` sahifalarida "Ballaringiz: X" widgeti va progress bar chiqadi.
  - Ball tugashiga 7 kun qolganda qizil rangda ogohlantirish ko'rsatiladi: `"X ball 7 kundan keyin tugaydi"`.
  - `CheckoutPage` da promokod kiritish qismi yonida "Ballardan foydalanish" toggle/checkbox qo'shiladi. (Promo-kod kabi ishlashi kerak).

**2. Win-back Mexanizmi (Client-side, In-app):**
- Barcha triggerlar mijozning oxirgi xaridi (`lastOrderDate`) asosida `HomeCubit.init()` da tekshiriladi.
- **Bannerlar (`HomePage` tepasida):**
  - **7-13 kun o'tsa:** Kichik eslatma — `"Sog'indingizmi? Sevimli taomingiz kutmoqda"`.
  - **14-29 kun o'tsa:** O'rtacha win-back — Banner + avtomatik 10% chegirma promokod (7 kun amal qiladi).
  - **30+ kun o'tsa:** Kuchli win-back — Banner + 20% promokod + "Ball muddati tugayapti" ogohlantirishi (agar ball bo'lsa).
- Bannerlar har doim `Dismissible` (yopish mumkin) bo'lishi kerak.

**3. Bildirishnomalar Markazi (`ProfilePage`):**
- Profil sahifasidagi "Bildirishnomalar" qismi faollashtiriladi.
- U yerni in-app notification center ga aylantiramiz: Win-back xabarlari tarixi, ball to'plash holati, order status yangilanishlari shu yerda yig'iladi.

**Arxitektura:**
- Yangi `LoyaltyCubit` (Global, `@lazySingleton` xuddi `HomeCubit` kabi).
- Backend tomondan `UserLoyaltyEntity` obyektlari qo'shilishi kutiladi.

---

## 10. Auto-Update Policy

This `agents.md` file MUST be updated immediately when:
1. A new technical requirement or constraint is established.
2. A new feature area or pattern is introduced.
3. An existing rule is modified or deprecated.

The file must always reflect the current, ground-truth state of the project.

---

## 9. Feature Documentation (Real Codebase Map)

> Bu bo'lim har bir featurening real ishlash logikasini, sahifalarini va UX xususiyatlarini tavsiflaydi. Har qanday o'zgarish kiritishdan oldin shu bo'limni o'qing.

---

### 9.1 `splash` Feature

**Fayl:** `lib/features/splash/presentation/pages/splash_page.dart`

**Maqsad:** Ilova ishga tushganda token tekshiruvi va yo'naltirish.

**Ishlash logikasi:**
1. `SplashCubit.init()` chaqiriladi → `SecureStorage.getToken()` tekshiradi.
2. Token bor → `/home`ga yo'naltiradi (`SplashAuthenticated`).
3. Token yo'q → `/auth/login`ga yo'naltiradi (`SplashUnauthenticated`).
4. Xato → `SplashFailure` — "Qayta urinish" tugmasi chiqadi.

**UX:**
- 800ms `FadeIn` animatsiya bilan logo ko'rinadi.
- Splash foni har doim `Colors.white` (tema mustaqil).
- `CircularProgressIndicator` yuklanish vaqtida ko'rinadi.
- Muvaffaqiyatsizlikda xato matni + retry tugma chiqadi.

> ⚠️ Splash page `HomeCubit.init()` ni CHAQIRMAYDI — bu `main.dart`da global qilingan.

---

### 9.2 `auth` Feature

**Fayllar:**
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/otp_page.dart`
- `lib/features/auth/presentation/bloc/auth_cubit.dart`

**Login Page (`/auth/login`):**
- Ishlash: To'liq ism + telefon raqam (9 raqam, `+998` prefiksi avtomatik) kiritiladi.
- Telefon: `FilteringTextInputFormatter.digitsOnly`, `maxLength: 9`.
- Tilni almashtirish: UZ / RU / EN tugmachalar logindan yuqorida joylashgan.
- Yuborish: `AuthCubit.login(fullName:, phone:)` → `AuthOtpSent` → `/auth/otp`ga push.

**OTP Page (`/auth/otp`):**
- 4 ta alohida input box (68×68px), autofill (`oneTimeCode`) qo'llab-quvvatlanadi.
- Har bir katakcha to'lganda keyingi fokusga o'tadi; oxirgi to'lganda `confirmOtp` avtomatik chaqiriladi.
- 60 soniyalik timer → tugagach "Qayta yuborish" tugmasi paydo bo'ladi.
- `AuthCubit.confirmOtp(phone:, code:)` → `AuthSuccess` → `/home`ga go'ing.

**AuthCubit Scope:** Scoped (`BlocProvider` ichida, featurega xos).

> ⚠️ `BlocProvider` LoginPage va OtpPage har birida alohida — ular `getIt<AuthCubit>()` bilan yaratiladi. Ular bir-biriga state ulashmaydi.

---

### 9.3 `home` Feature

**Fayllar:**
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/home/presentation/pages/product_detail_page.dart`
- `lib/features/home/presentation/widgets/product_card.dart`
- `lib/features/home/presentation/bloc/home_cubit.dart`

**HomePage (`/home`):**

| Element | Tavsif |
|---|---|
| AppBar | Logo + savat ikonkasi (badge bilan miqdor ko'rsatadi) |
| Sticky Category Chips | `SliverPersistentHeader` (pinned), gorizontal scroll |
| Product Grid | 2 ustun, `childAspectRatio: 0.68`, kategoriya bo'limlarga ajratilgan |
| Pull-to-Refresh | `RefreshIndicator` → `HomeCubit.init()` |
| Shimmer skeleton | `HomeLoading` holatda 2 ta bo'lim × 4 karta |
| Error state | WiFi off ikona + server xabar matni |
| **Search** | AppBar'da qidiruv ikonkasi yoki SliverAppBar ichida search bar |

**Scroll Sync logikasi:**
- Foydalanuvchi scroll qilganda `_onScroll()` → har bir kategoriya section balandligi hisoblanadi → aktiv chip belgilanadi.
- Chip bosilganda `_getTargetOffset()` → `animateTo(350ms, easeInOut)`.
- `_isScrollingToCategory` flag — programmatic scroll vaqtida `_onScroll` ishlamasligi uchun.

**Kategoriya filtrash:** Client-side — `fullProducts.where((p) => p.category?.slug == cat.slug)`.

**🔍 Search (Rejalashtirilgan):**
- AppBar'da qidiruv ikonkasi (bosilganda search bar ko'rinadi) yoki `SliverAppBar` ichida doimiy search field.
- Client-side filter: `fullProducts.where((p) => p.title.contains(query) || p.description?.contains(query) == true)`.
- Debounce: **300ms** — har harfda API chaqirilmaydi, `Timer`/`debounce` orqali.
- Search aktiv bo'lganda kategoriya chiplar va scroll sync o'chadi.
- Bo'sh natija: `'home.search_empty'.tr()` + ikonka.
- Search bo'sh bo'lsa — oddiy kategoriyali ko'rinishga qaytadi.

> ⚠️ Search natijasida mahsulotlar grid ko'rinishda (kategoriyasiz), umumiy list sifatida ko'rsatiladi.

**HomeCubit States:**
```
HomeInitial → HomeLoading → HomeLoaded(categories, fullProducts, products, settings)
                          ↘ HomeFailure(message)
```

**ProductDetailPage (`/product/:slug`):**
- `ProductEntity` `extra:` orqali uzatiladi (API chaqirilmaydi).
- Variantlar (o'lchamlar): 1 ta bo'lsa avtomatik tanlanadi, 1 tadan ko'p bo'lsa `Wrap` bilan ko'rsatiladi.
- Variantsiz mahsulot uchun "Savatga qo'shish" har doim ishlaydi.
- Variantli mahsulotda tanlashsiz bosish — `SnackBar` xatosi.
- `bottomNavigationBar` da `AppButton` — narx + harakat.

**ProductCard widget:**
- Savattagi miqdor `quantityInCart > 0` bo'lsa badge ko'rsatadi (qizil to'rtburchak, top-right).
- `+` / `-` tugmalari to'g'ridan-to'g'ri `CartCubit.updateQuantity()` ni chaqiradi.

---

### 9.4 `cart` Feature

**Fayllar:**
- `lib/features/cart/presentation/pages/cart_page.dart`
- `lib/features/cart/presentation/pages/checkout_page.dart`
- `lib/features/cart/presentation/pages/map_picker_page.dart`
- `lib/features/cart/presentation/bloc/cart_cubit.dart`

**CartCubit (Global — `@lazySingleton`):**

| Metod | Tavsif |
|---|---|
| `addToCart(product, variant?)` | Mavjud bo'lsa miqdor +1, yo'q bo'lsa yangi item |
| `removeFromCart(item)` | Slug + variantId bo'yicha o'chiradi |
| `updateQuantity(item, delta)` | +1 yoki -1; 0 yetganda avtomatik o'chiradi |
| `addMultipleToCart(items)` | Qayta buyurtma uchun bulk qo'shish |
| `clear()` | Savatni to'liq tozalaydi (order yaratilgandan keyin) |

**CartPage (`/cart`):**
- Bo'sh holat: katta ikonka + "Savzatga o'ting" tugmasi `/home`ga.
- Har bir item: rasm + nom + variant + narx + miqdor kontrollar.
- Bottom panel: subtotal + "Rasmiylashtirish" (`/checkout`ga push).

**Checkout 2-bosqichli oqim (Rejalashtirilgan):**

**Step 1/2: Buyurtma va Manzil (`/checkout`)**
- Tepada progress indicator (1/2).
- Savatdagi mahsulotlarni tahrirlash (+/- va o'chirish).
- Yetkazish turi (Yetkazib berish / Olib ketish).
- Filial tanlash (Olib ketish uchun) yoki Manzil (Yetkazish uchun).
- "Davom etish" tugmasi orqali Step 2 ga o'tiladi (faqat manzil/filial to'liq bo'lsa aktiv).
- Savat bo'shab qolsa, tugma "Savat bo'sh" deb o'zgaradi va bloklanadi.

**Step 2/2: To'lov va Chegirmalar (`/checkout/payment`)**
- Tepada progress indicator (2/2). Orqaga tugmasi Step 1 ga qaytaradi.
- Qisqa buyurtma xulasasi + "Tahrirlash" linki (Step 1 ga qaytaradi).
- Promo kod va Loyalty ballarni kiritish.
- To'lov usuli tanlash (Payme/Click/Naqd).
- Naqd uchun qaytim (change) va izoh maydoni.
- Kengaytirilgan narx breakdown (Subtotal, promo, ball, yetkazish, jami summa).
- "Buyurtma berish" tugmasi (`createOrder` mutation).
- Agar bu yerdan chiqib ketilsa (Cart'ga), promo va ball tanlovlari tozalanadi.

> ⚠️ **State Management:** Ikkala bosqich ham bitta `CheckoutCubit` instansiyasini ulashadi (nested navigator yoki parent route darajasida provide qilinadi). Bottom nav bar ikkala holatda ham yashirilgan.

**🚚 Delivery ETA (Rejalashtirilgan):**
- Yetkazib berish vaqti (ETA) Checkout sahifasida emas, balki buyurtma qabul qilingandan keyin (Order History / Order Detail sahifalarida) ko'rsatiladi.
- Buning uchun backend `Order` obyektiga `estimatedTime` qo'shib beradi.

**📍 Saqlangan manzillar (Rejalashtirilgan):**
- Yangi bo'lim: Profile yoki Checkout ichida `"Mening manzillarim"`.
- Model: `SavedAddress { id, label (Uy/Ish/Boshqa), lat, lng, text }` — `SharedPrefs` yoki `SecureStorage`da saqlanadi.
- CRUD: qo'shish (MapPicker orqali), tahrirlash (label), o'chirish (swipe/delete).
- Checkout'da manzil bo'limida tezkor tanlov: `ListView` + "+ Yangi manzil" tugmasi.
- Tanlanganda `_lat`, `_lng`, `_addressController` to'ldiriladi va `_calculateDelivery()` chaqiriladi.

**MapPickerPage (`/map-picker`):**
- `flutter_map` + OpenStreetMap tiles.
- `Geolocator` → joriy joylashuv → marker va karta shu joyga o'rnatiladi.
- Xaritaga tap → marker yangi joyga ko'chadi + reverse geocoding (ko'cha nomi kartochkada).
- "Joylashuvim" FAB → qayta joriy joyga qaytaradi.
- "Tasdiqlash" → `context.pop({'lat', 'lng', 'address'})` — CheckoutPage olib oladi.

**✏️ MapPicker — Qo'lda yozish fallback (Rejalashtirilgan):**
- Xarita ustida yoki tagida `"Manzilni qo'lda kiriting"` tugmasi/toggle.
- Bosilganda `TextField` paydo bo'ladi; foydalanuvchi erkin matn kiritadi.
- Geocoding shart emas — matn to'g'ridan-to'g'ri `address` sifatida saqlanadi, koordinatalar `null`.
- `context.pop({'lat': null, 'lng': null, 'address': manualText})` — CheckoutPage `null` koordinatani qabul qilishi kerak.

---

### 9.5 `orders` Feature

**Fayllar:**
- `lib/features/orders/presentation/pages/orders_page.dart`
- `lib/features/orders/presentation/pages/order_detail_page.dart`
- `lib/features/orders/presentation/bloc/order_cubit.dart`

**OrdersPage (`/orders`):**
- `BlocProvider` ichida `getIt<OrderCubit>()..getOrders()` — sahifa ochilganda avtomatik fetch.
- `OrderCubit` Scoped (global emas).
- Bo'sh holat: "Buyurtmalar yo'q" ikonka + matn.
- Har bir `OrderCard` tapda `/order/:id`ga push, `OrderEntity` `extra:` bilan.

**OrderCard:**

| Status kodi | Rang |
|---|---|
| 6 — Yakunlangan | `Colors.green` |
| 1 — Rad etilgan | `Colors.red` |
| 4 — Jarayonda | `Colors.orange` |
| Boshqalar | `AppColors.neutral700` |

- Status matni: `statusText.startsWith('orders.status_')` bo'lsa `.tr()` qo'llanadi, aks holda server matni.

**OrderDetailPage (`/order/:id`):**
- `OrderEntity` `extra:` orqali keladi — hech qanday API chaqiruvi yo'q.
- Status kartochkasi tepa qismda.
- Mahsulotlar ro'yxati: rasm + nom + variant + miqdor × narx.
- To'lov URL (`paymentUrl`) mavjud va buyurtma tugallanmagan/rad etilmagan bo'lsa "To'lash" tugmasi chiqadi → `launchUrl`.
- "Qayta buyurtma" tugmasi → `CartCubit.addMultipleToCart()` + `/cart`ga navigate.

**📞 Buyurtma bo'yicha bog'lanish / Bekor qilish:**
- Ilovada avtomatik tarzda buyurtmani bekor qilish (Cancel) funksiyasi **bo'lmaydi**.
- Buning o'rniga, Order Detail sahifasida tayyorlayotgan filialning (Branch) telefon raqami ko'rsatiladi. 
- Foydalanuvchi o'zgarishlar yoki bekor qilish niyati bo'lsa to'g'ridan-to'g'ri filialga qo'ng'iroq qiladi (`tel:+998...`).
- `Order` obyektidan `branchPhone` yoki filial ma'lumotlari kutiladi.

**🚚 Delivery ETA (Order Detail):**
- Buyurtma tafsilotlarida (Yoki Orders ro'yxatida) qachon yetib kelishi / tayyor bo'lishi haqida vaqt (`estimatedTime`) ko'rsatiladi.

---

### 9.6 `profile` Feature

**Fayl:** `lib/features/profile/presentation/pages/profile_page.dart`

**ProfilePage (`/profile`):** (Presentation only — domain/data qatlamlari yo'q)

| Element | Tavsif |
|---|---|
| Foydalanuvchi kartochkasi | `SecureStorage.getUserName()` + `getUserPhone()` |
| Bildirishnomalar | Placeholder (hozircha bo'sh `onTap`) |
| Tilni almashtirish | `showModalBottomSheet` → UZ/RU/EN; tanlagach global til sync (pastga qarang) |
| Qo'llab-quvvatlash qo'ng'irog'i | `HomeLoaded.settings.supportPhone` → `tel:` URL launcher |
| Murojaat formasi | `AnimatedSize` bilan kengayadigan forma; maqsad tanlash + xabar matni |
| Chiqish | `AlertDialog` tasdiqlash → `SecureStorage.clearAll()` → `/auth/login` |

**Murojaat maqsadlari:** food, delivery, service, suggestion, complaint, other (6 ta).

**🌐 Til o'zgarganda Sync (Yangilangan qoida):**

> ⚠️ **ESKI (noto'g'ri):** Faqat `HomeCubit.init()` chaqiriladi.
>
> ✅ **YANGI (to'g'ri):** Til o'zgarganda quyidagilar ham yangilanishi kerak:

- **`HomeCubit.init()`** — mahsulot/kategoriya nomlarini yangi tilda qayta oladi ✅ (hozir ishlaydi)
- **`CartCubit`** — item nomlar va variant nomlar `ProductEntity`dan keladi, shuning uchun `HomeCubit` yangilangandan keyin cart UI avtomatik qayta render bo'lishi kerak (tekshirilsin).
- **`CheckoutPage`** — agar ochiq bo'lsa, `settings.paymentMethods` nomlari yangi tilda emas. Yechim: `CheckoutPage` `HomeCubit.state` ni `BlocBuilder` orqali o'qishi yoki sahifani pop qilish.
- **Tavsiya:** Global `EventBus`/`Stream<Locale>` yoki `SharedPrefs`-based listener orqali barcha scoped cubitlarga til o'zgarishi signali berish. Yoki eng oddiy yechim — til o'zgarganda `context.go('/home')` bilan stack tozalansin.

---

## 10. UX Contracts (O'zgartirib bo'lmaydigan UX qoidalar)

> Bu qoidalar foydalanuvchi tajribasini buzmaslik uchun majburiydir.

### 10.1 Navigation

- `ShellRoute` = Bottom nav bar faqat `/home`, `/cart`, `/orders`, `/profile` uchun ko'rinadi.
- Checkout, MapPicker, ProductDetail — bottom nav YO'Q (to'liq sahifa).
- `go()` faqat tab o'tishda, `push()` modal/detail sahifalarda.

### 10.2 Loading States

- `HomeCubit` loading → shimmer skeleton (hech qachon `CircularProgressIndicator` emas).
- `OrderCubit` loading → `CircularProgressIndicator` markazda.
- `AuthCubit` loading → tugma `disabled` + spinner ichida.
- `CheckoutPage` submit → `_isSubmitting = true` → "Buyurtma berish" tugmasi disabled.

### 10.3 Error States

- `HomeFailure` → WiFi ikonka + server xabari, `RefreshIndicator` orqali retry.
- `AuthFailure` → `SnackBar` (floating, qizil rang, 12px radius).
- `SplashFailure` → inline xato + "Qayta urinish" tugmasi.
- Checkout promo xatosi → maydon ostida qizil matn (SnackBar emas).

### 10.4 Cart Badge

- Savat ikonkasidagi badge: `CartState.items.length` (noyob itemlar soni, miqdor emas).
- `ProductCard` dagi badge: `quantityInCart` (umumiy miqdor).
- Badge 0 bo'lsa — ko'rinmaydi.

### 10.5 Price Formatting

- Barcha narxlar: `NumberFormatter.formatSum(price)` + `' so\'m'` yoki `' UZS'`.
- Locale key: `'common.currency'.tr()` — hardcode QILINMAYDI.

### 10.6 Dark Mode

- `AppTheme.light` va `AppTheme.dark` — ikkala mavzu qo'llab-quvvatlanadi.
- Widgetlar `Theme.of(context).cardColor`, `Theme.of(context).textTheme.*` ishlatadi.
- Magic color literals (masalan, `Colors.white`) faqat komponent foni uchun ruxsat (Splash, BottomNav).

### 10.7 Scroll & Category Sync

- `HomePage`da scroll va chip sync **ikki tomonlama**: scroll → chip yangilanadi; chip → scroll animatsiya.
- `_isScrollingToCategory` flag bu ikkinchi loopni oldini oladi.
- Yangi kategoriya bo'limi qo'shilsa, `_getTargetOffset()` va `_getActiveCategory()` metodlarida height hisob-kitobi o'zgartirilishi shart.

### 10.8 Variant Selection

- 1 ta variant: sahifa ochilishida avtomatik tanlanadi, variant paneli ko'rsatilmaydi.
- 2+ variant: paneli ko'rsatiladi, default tanlov yo'q; savatga qo'shishda majburiy.
- Tanlov yo'q + "Savatga qo'shish" → `SnackBar` xatosi, sahifa yopilmaydi.
