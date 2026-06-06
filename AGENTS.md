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

## 7. Auto-Update Policy

This `agents.md` file MUST be updated immediately when:
1. A new technical requirement or constraint is established.
2. A new feature area or pattern is introduced.
3. An existing rule is modified or deprecated.

The file must always reflect the current, ground-truth state of the project.
