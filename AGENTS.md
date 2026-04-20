# Strada Pizza — Flutter Mobile App Development Guide

Ushbu qo'llanma Strada Pizza loyihasi uchun Flutter mobil ilovasini ishlab chiqishda AI agent uchun asosiy qoidalar, arxitektura patterns va GraphQL API bilan ishlash bo'yicha **haqiqiy kod bilan mos** to'liq ko'rsatmalarni o'z ichiga oladi.

---

## 🏗 Texnologiyalar (pubspec.yaml ga muvofiq)

| Qatlam              | Kutubxona                      | Versiya          |
| ------------------- | ------------------------------ | ---------------- |
| Framework           | Flutter                        | SDK ≥ 3.0.0      |
| State Management    | `flutter_bloc`                 | ^8.1.6           |
| DI                  | `get_it` + `injectable`        | ^8.0.2 / ^2.4.4  |
| API Client          | `graphql_flutter`              | ^5.2.0-beta.7    |
| Navigation          | `go_router`                    | ^14.6.2          |
| Localization        | `easy_localization`            | ^3.0.7           |
| Secure Storage      | `flutter_secure_storage`       | ^9.2.2           |
| Local Cache         | `shared_preferences`           | ^2.3.3           |
| Image Cache         | `cached_network_image`         | ^3.4.1           |
| Maps & Geo          | `yandex_mapkit`, `geolocator`  | ^3.3.0 / ^13.0.2 |
| Crypto              | `crypto`                       | ^3.0.5           |
| Device Info         | `device_info_plus`             | ^11.1.1          |
| Typography          | `google_fonts` (Inter)         | ^6.2.1           |
| Push Notifications  | `firebase_messaging`           | ^15.1.6          |
| HTTP util           | `url_launcher`                 | ^6.3.1           |

> **Eslatma:** `flutter_screenutil` ishlatilmaydi. Responsiveness uchun `MediaQuery` va `LayoutBuilder` dan foydalaniladi.

---

## 📡 GraphQL API Konfiguratsiyasi

Loyiha ikkita asosiy schema'dan foydalanadi:

1. **Common Schema:** `/graphql/common` — Auth, mahsulotlar, kategoriyalar, filiallar, sozlamalar.
2. **Order Schema:** `/graphql/order` — Buyurtmalar yaratish, ko'rish.

### 1. Environments & Base URLs

Muhit farqi **`kReleaseMode`** orqali `ApiConstants` klassida avtomatik sozlanadi:

```dart
// lib/core/constants/api_constants.dart
static const _base = kReleaseMode ? _prodBase : _devBase;
static const commonEndpoint = '$_base/graphql/common';
static const orderEndpoint  = '$_base/graphql/order';
```

| Muht         | URL                                       |
| ------------ | ----------------------------------------- |
| Production   | `https://pizzastrada.uz/graphql/`         |
| Development  | `https://food.khalilovdev.uz/graphql/`    |

### 2. GraphQL Client (`lib/core/network/graphql_client.dart`)

- `IOClient` bilan **60 soniyalik** connection timeout o'rnatilgan (majburiy).
- Routing `Link.split` orqali operation nomi asosida amalga oshiriladi (order vs common).
- Order operatsiyalari: `orders`, `Orders`, `order`, `Order`, `createOrder`, `checkPromoCode`.
- Barcha Auth, Localization, Signature va Logging mantiqi **bitta `Link.function`** da birlashtirилган — bu "Future already completed" crash'larini bartaraf etadi.

### 3. Majburiy Request Headerlar

Barcha so'rovlarda (Query va Mutation) quyidagilar yuborilishi shart:

| Header          | Qiymat / Manba                                        |
| --------------- | ----------------------------------------------------- |
| `Accept`        | `application/json`                                    |
| `Content-Type`  | `application/json`                                    |
| `language`      | `uz`, `ru` yoki `en` — `EasyLocalization.of(context)` |
| `device`        | `android` yoki `ios` — `Platform.isIOS`               |
| `device-id`     | `DeviceInfoHelper.deviceId` — `device_info_plus`      |
| `device-name`   | `DeviceInfoHelper.deviceName`                         |
| `Authorization` | `Bearer <token>` — `flutter_secure_storage`dan        |
| `User-Agent`    | `PizzaStrada/iOS-Android Mobile App`                  |

### 4. Xavfsizlik Headerlari (Faqat Mutations uchun)

Har bir mutatsiya so'roviga qo'shimcha ravishda:

| Header               | Tavsif                     |
| -------------------- | -------------------------- |
| `Header-Random-Str`  | 16 belgilik random string  |
| `Header-Timestamp`   | ms dagi joriy vaqt         |
| `Header-Sign`        | HMAC-SHA256 imzosi         |

**Imzo hisoblash (to'g'ri algorim):**

```dart
final payload = jsonEncode(variables) + randomStr + timestamp;
final hmac = Hmac(sha256, utf8.encode(ApiConstants.hmacSecret));
final sign = hmac.convert(utf8.encode(payload)).toString();
```

> `hmacSecret` `--dart-define=HMAC_SECRET=...` orqali build vaqtida beriladi. Default value hardcoded qoldirilgan (dev uchun).

---

## 📂 Loyiha Tuzilmasi (Haqiqiy)

```
lib/
  core/
    constants/       # ApiConstants, AppConstants (navigatorKey)
    di/              # injection.dart — get_it + injectable
    error/           # Failure classes (dartz Either)
    network/         # graphql_client.dart — single link chain
    router/          # app_router.dart — go_router config
    storage/         # SecureStorage, SharedPrefs
    theme/           # AppColors, AppTextStyles, AppTheme, AppIcons, AppDimensions
    utils/           # DeviceInfoHelper, validators
    widgets/         # AppButton, AppShimmer, AppTextField
  features/
    auth/
      data/          # AuthRemoteDataSource, AuthRepositoryImpl, UserModel
      domain/        # UserEntity, AuthRepository, LoginUseCase, ConfirmOtpUseCase
      presentation/  # AuthCubit, LoginPage, OtpPage
    cart/
      data/          # CartItemEntity (domain bilan birlashtirilgan)
      presentation/  # CartCubit, CartPage, CheckoutPage
    home/
      data/          # HomeRemoteDataSource, HomeRepositoryImpl, HomeModels
      domain/        # HomeEntities (ProductEntity, CategoryEntity, VariantEntity, SliderEntity, SettingsEntity)
      presentation/  # HomeCubit, HomePage, ProductDetailPage, ProductCard
    orders/
      data/          # OrderRemoteDataSource, OrderRepositoryImpl, OrderModel
      domain/        # OrderEntity, OrderItemEntity, OrderRepository, GetOrdersUseCase
      presentation/  # OrderCubit, OrdersPage (compact list), OrderDetailPage (full view)
    profile/
      presentation/  # ProfilePage (settings, language, support, logout)
    splash/
      presentation/  # SplashPage, SplashCubit — settings query orqali can_order tekshirish
  l10n/
    uz.json          # O'zbek (asosiy til)
    ru.json          # Rus tili
    en.json          # Ingliz tili
  main.dart
```

---

## 🛠 GraphQL So'rovlari

### Common Schema Queries

```graphql
# Barcha mahsulotlar (client-side filtering uchun)
query Products {
  products {
    slug title description thumbnail photo price
    category { slug title }
    variants { id title price }
    values { key value }
  }
}
# Kategoriyalar
query Categories { categories { slug title } }
# Sozlamalar (Splash da yuklanadi)
query Settings { settings { support_phone can_order } }
# Filiallar
query Branches { branches { id title address latitude longitude } }
```

### Order Schema Queries

```graphql
query Orders { orders { order_id address comment status status_text payment_url type branch latitude longitude payment_method_text payment_method subtotal_price discount_amount delivery_price total_price products { slug title image variant price quantity total_amount } } }
query Order($id: Int!) { order(id: $id) { ... same fields ... } }
```

### Mutations

```graphql
mutation login($phone: String!, $full_name: String!) { login(phone: $phone, full_name: $full_name) }
mutation confirmOtp($phone: String!, $code: Int!) { confirmOtp(phone: $phone, code: $code) { token } }
mutation createOrder(...) { createOrder(...) }

# Promo code: pass subtotal as total_price (delivery excluded)
mutation CheckPromoCode($promo_code: String, $total_price: Float) {
  checkPromoCode(promo_code: $promo_code, total_price: $total_price) {
    promo_code type value
  }
}

# Delivery price calculation: run when Delivery type is selected
mutation CalculateDeliveryPrice($latitude: Float, $longitude: Float) {
  calculateDeliveryPrice(latitude: $latitude, longitude: $longitude)
}
```

### Promo Code Logic (CheckoutPage)

| Field  | Type | Tavsif |
|--------|------|--------|
| `type` | `1`  | **Percent** — subtotal × value / 100 (delivery kirmaydi) |
| `type` | `0`  | **Fixed** — total summadan aniq `value` ayriladi |

- Muvaffaqiyatli promo: `_appliedPromoCode`ni saqla, `createOrder`ga uzat.
- Xato kelsa serverning error `message`ini foydalanuvchiga ko'rsat (`:remain`, `:amount` placeholderlar bilan kelishi mumkin).

### `createOrder` Argumentlari

| Argument         | Turi      | Tavsif                                          |
| ---------------- | --------- | ----------------------------------------------- |
| `type`           | `int`     | `0` — Delivery, `1` — Pickup                    |
| `branch_id`      | `int?`    | `type=1` bo'lsa majburiy                        |
| `latitude`       | `float?`  | `type=0` bo'lsa majburiy                        |
| `longitude`      | `float?`  | `type=0` bo'lsa majburiy                        |
| `payment_method` | `int`     | `0` — Naqd, `1` — Payme, `2` — Click            |
| `products`       | `List`    | `[{ id, quantity, variant_id }]`                |
| `promo_code`     | `string?` | Ixtiyoriy promo kod                             |

---

## 🌍 Localization (Ko'p tillilik)

- **3 ta til:** `uz` (asosiy), `ru`, `en`
- Paket: `easy_localization` + JSON fayllar (`lib/l10n/`)
- Localization fayllar `pubspec.yaml`da asset sifatida ro'yxatga olingan.

### Majburiy Qoidalar

1. Barcha static textlar (label, button, error) `lib/l10n/*.json`da saqlanishi shart.
2. Kodda faqat `.tr()` extension metodi ishlatiladi: `'key'.tr()`.
3. Yangi text qo'shilganda **barcha 3 ta tilda** tarjima majburiy.
4. Xatolik xabarlari (error messages) foydalanuvchiga tushunarli, mazmunan to'g'ri va to'liq tarjima qilingan bo'lishi shart. Hardcoded stringlar (hatto xatoliklar uchun ham) TAQIQLANGAN.
5. Til o'zgarganda `HomeCubit.init()` chaqiriladi — API so'rovlar yangi `language` headeri bilan qayta yuboriladi.

> `locale_keys.g.dart` **ishlatilmaydi** — faqat string key bilan `.tr()` ishlatiladi.

---

## 🖼 Navigatsiya (go_router)

`AppRouter.dart`da `go_router` konfiguratsiyasi:

| Route             | Widget             | Tavsif                          |
| ----------------- | ------------------ | ------------------------------- |
| `/splash`         | `SplashPage`       | Boshlang'ich ekran              |
| `/auth/login`     | `LoginPage`        | Telefon raqamni kiritish        |
| `/auth/otp`       | `OtpPage`          | SMS tasdiqlash                  |
| `/home`           | `HomePage`         | ShellRoute (bottom nav)         |
| `/cart`           | `CartPage`         | ShellRoute                      |
| `/orders`         | `OrdersPage`       | ShellRoute                      |
| `/profile`        | `ProfilePage`      | ShellRoute                      |
| `/product/:slug`  | `ProductDetailPage`| `extra: ProductEntity`          |
| `/checkout`       | `CheckoutPage`     | Buyurtma tasdiqlash             |
| `/order/:id`      | `OrderDetailPage`  | `extra: OrderEntity?`           |
| `/map-picker`     | `MapPickerPage`    | Manzil tanlash (placeholder)    |

- `SecureStorage.getToken()` `null` bo'lsa `/auth/login`ga redirect.
- `navigatorKey`: `AppConstants.navigatorKey` orqali global `BuildContext` olinadi.

---

## 🎨 Design System

### AppColors

`lib/core/theme/app_colors.dart` — `AppColors` klasi barcha rang konstantlarini saqlaydi.

- Primary: `AppColors.primary`, `AppColors.primaryLight`
- Neutral: `neutral50` → `neutral900`
- Semantic: `success`, `error`, `warning`
- Dark mode: `darkBackground`, `darkSurface`

### AppTextStyles

`lib/core/theme/app_text_styles.dart` — `Inter` Google Font asosida:
`display`, `h1-h4`, `bodyLarge/Medium/Small/ExtraSmall`, `labelLarge/Medium/Small`

### AppTheme

`lib/core/theme/app_theme.dart`:
- `AppTheme.light` — Material 3, `useMaterial3: true`
- `AppTheme.dark` — Qorong'i rejim

### AppIcons

`lib/core/theme/app_icons.dart` — Material Icons wrappers. Navigation uchun ikki holat (inactive/active):

```dart
static const IconData home = Icons.home_outlined;
static const IconData homeActive = Icons.home_rounded;
// + cart, orders, profile (xuddi shunday juftlar)
```

---

## 🛑 Kod Qoidalari

### 1. Model va Entity Ajratish

```
Data layer:  OrderModel (fromJson, toJson) — GraphQL response mapping
Domain layer: OrderEntity — ilovada ishlatiladigan sof Dart klassi
```

### 2. BLoC Pattern

```
Cubit → UseCase → Repository → DataSource → GraphQL API
```

- `HomeCubit` va `CartCubit` global (`main.dart`dagi `MultiBlocProvider`da).
- `OrderCubit`, `AuthCubit` — feature ichida `BlocProvider` orqali.

### 3. DI — Injectable

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Yangi singleton qo'shishda `@LazySingleton` yoki `@injectable` annotatsiyasidan foydalaniladi.

### 4. UI/UX Majburiy Qoidalar

| Qoida              | Tavsif                                                                     |
| ------------------ | -------------------------------------------------------------------------- |
| Kategoriya Filter  | Client-side! Barcha `products` bir marta olinadi, `category.slug` bo'yicha filter |
| Variants           | 1 tadan ko'p bo'lsa tanlash majburiy; 1 ta bo'lsa UI yashiriladi           |
| Sliders            | `viewportFraction: 0.92`, `radius: 20px`, gradient overlay, shadow         |
| Pull-to-Refresh    | `HomePage`da `RefreshIndicator` bor                                        |
| Grid Ratio         | `childAspectRatio: 0.68` — `ProductCard` overflow oldini oladi             |
| Order Card         | Compact: faqat ID, status, mahsulot soni va jami narx                     |
| Order Detail       | `OrderDetailPage` — status, barcha mahsulotlar, subtotal/delivery/total   |
| Bottom Nav Icons   | Outlined (inactive) → Rounded (active) juftlari                           |
| Card Radius        | `16px` — `OrderCard`, `20px` — `ProductCard`, `DetailCard`               |
| BoxShadow          | `Colors.black.withOpacity(0.04)`, `blurRadius: 10`                        |
| **Narx Formati**   | **Barcha narxlar `NumberFormatter.formatSum(price)` orqali ko'rsatiladi** — `product.price.toInt()` kabi raw format TAQIQLANGAN. Tegishli joylar: `ProductCard`, `_VariantPickerSheet`, `ProductDetailPage` variant chips va bottom button, `CartPage`, `CheckoutPage`, `OrderDetailPage` |

### 5. Xatolarni Boshqarish

- GraphQL xatolari: `result.hasException` tekshiriladi, exception throw qilinadi.
- UI da `SnackBar` yoki state (`OrderFailure`, `HomeFailure`) orqali ko'rsatiladi.
- Tarmoq xatolari alohida ushlanadi.

### 6. Splash va `can_order`

`SplashCubit` `Settings` query'si orqali API holatini tekshiradi:
- `can_order: false` bo'lsa foydalanuvchiga tegishli xabar ko'rsatiladi.
- Token borligiga qarab `/home` yoki `/auth/login`ga yo'naltiriladi.

### 7. Testing

Hozirda test yozish majburiy emas (Dev Mode). Lekin har bir yangi metod uchun Dart docstring (`///`) yozib ketilishi shart.

---

## ⚠️ Muhim Cheklovlar

- **APK hajmi:** `yandex_mapkit` qo'shilganda APK 50MB dan oshishi mumkin. Bunday bo'lsa GitHub Releases orqali tarqatish kerak (Telegram Bot 50MB chegarasi).
- **HMAC_SECRET:** Production build uchun: `flutter build apk --dart-define=HMAC_SECRET=<real_secret>`.
- **Localization asset:** `lib/l10n/` papkasi `pubspec.yaml`dagi `assets:` ro'yxatida saqlanishi shart.
- **N+1 muammodan** saqlanish uchun GraphQL fragment yoki to'liq field listidan foydalaniladi.
- **Orientatsiya:** Ilova faqat portrait rejimida ishlaydi (`SystemChrome.setPreferredOrientations`).
- **Network Timeout:** Barcha tarmoq so'rovlari (GraphQL, HTTP) uchun majburiy **60 soniyalik** `connectionTimeout` o'rnatilishi shart.

---

## 🔄 Avtomatik Yangilanish Qoidasi

Agent har safar yangi texnik talab, cheklov yoki qaror qabul qilinsa ushbu `AGENTS.md` faylini darhol yangilashi shart:
1. Tegishli bo'limga yangi qoidani qo'shish.
2. Kerak bo'lsa yangi bo'lim ochish.
3. Faylning dolzarbligini doimo ta'minlash.
