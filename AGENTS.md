# Strada Pizza — Flutter Mobile App Development Guide

Ushbu qo'llanma Strada Pizza loyihasi uchun Flutter mobil ilovasini ishlab chiqishda Claude (yoki boshqa AI) uchun asosiy qoidalar va GraphQL API bilan ishlash bo'yicha to'liq ko'rsatmalarni o'z ichiga oladi.

---

## 🏗 Texnologiyalar

- **Framework:** Flutter
- **State Management:** BLoC (flutter_bloc)
- **API Client:** `graphql_flutter`
- **Dependency Injection:** `get_it`
- **Local Storage:** `hive` yoki `shared_preferences`
- **Design System:** Maxsus dizayn (Vanilla styling), `flutter_screenutil` (responsiveness)

---

## 📡 GraphQL API Konfiguratsiyasi

Loyiha ikkita asosiy schema'dan foydalanadi:

1.  **Common Schema:** `/graphql/common` (Auth, mahsulotlar, filiallar)
2.  **Order Schema:** `/graphql/order` (Savat, buyurtma yaratish)

### 1. Environments & Base URLs

| **Production**  | `https://pizzastada.uz/graphql/` |
| **Development** | `https://food.khalilovdev.uz/graphql/` |

_Eslatma: GraphQL so'rovlarida schema nomini path segment sifatida berish kerak (`/graphql/common` yoki `/graphql/order`)._

### 2. Authentication

Barcha so'rovlarda `Authorization: Bearer <token>` headeri yuborilishi kerak (Auth talab qilinadigan endpointlar uchun). Token `login` va `confirmOtp` mutationlari orqali olinadi.

### 3. Header Signature (Mutations uchun majburiy)

Barcha **Mutation** so'rovlari uchun (Production muhitida) maxsus xavfsizlik headerlari talab qilinadi:

- `Header-Random-Str`: Noyob ixtiyoriy satr (Random string).
- `Header-Timestamp`: Millisekunddagi joriy vaqt (Timestamp).
- `Header-Sign`: HMAC SHA256 orqali hisoblangan imzo.

**Imzo hisoblash algoritmi:**

```dart
String stringToHash = jsonEncode(variables) + randomStr + timestamp;
String signature = hmacSha256(secretKey, stringToHash);
```

_Eslatma: `variables` JSON formatida, unicode va slashlar escape qilinmagan bo'lishi kerak._

---

## 📂 Loyiha Tuzilmasi (Feature-driven)

Ilovani quyidagi papkalar strukturasida tashkil qil:

```
lib/
  core/                # Shared logic, networks, themes, constants
    network/           # GraphQL client config, interceptors
    theme/             # Color scheme, Typography
    utils/             # Helpers, Validators
  features/            # Barcha modullar
    auth/
      data/            # Datasources, Repositories
      domain/          # Models, Entities
      presentation/    # Bloc, Screens, Widgets
    home/
    orders/
    profile/
  main.dart
```

---

## 🛠 GraphQL So'rovlari bo'yicha Ko'rsatmalar

### Queries

- `categories`: Barcha kategoriyalar va ularning mahsulotlari.
- `products`: Mahsulotlar ro'yxati (filterlar bilan).
- `product`: Bitta mahsulot tafsilotlari.
- `branches`: Filiallar ro'yxati.
- `settings`: Ilova sozalamalari (tel raqam, ish vaqti va h.k).
- `order(id: Int!)`: Bitta buyurtma tafsilotlari (new schema).
- `orders`: Buyurtmalar ro'yxati (new schema).

### Mutations

- `login(phone, full_name)`: OTP yuborish.
- `confirmOtp(phone, code)`: Token olish.
- `createOrder(...)`: Buyurtma yaratish.
- `checkPromoCode(code)`: Promo kodni tekshirish.

#### `createOrder` argumentlari va validatsiya:

| Argument         | Turi      | Tavsif                                                       |
| ---------------- | --------- | ------------------------------------------------------------ |
| `type`           | `int`     | `0` - Yetkazib berish (Delivery), `1` - Olib ketish (Pickup) |
| `branch_id`      | `int?`    | `type=1` bo'lsa majburiy                                     |
| `latitude`       | `float?`  | `type=0` bo'lsa majburiy                                     |
| `longitude`      | `float?`  | `type=0` bo'lsa majburiy                                     |
| `payment_method` | `int`     | `0` - Naqd, `1` - Payme, `2` - Click                         |
| `products`       | `List`    | `OrderProductInput` listi (id, quantity, variants)           |
| `promo_code`     | `string?` | Ixtiyoriy promo kod                                          |

---

## 🌍 Localization (Ko'p tillilik)

Ilova 3 ta tilda to'liq ishlashi kerak:

- **O'zbekcha (`uz`)** — Asosiy til.
- **Ruscha (`ru`)**
- **Inglizcha (`en`)**

### 0. Localization Rules (Majburiy)
- Barcha static textlar (label, button text, error message) `lib/l10n/*.json` fayllarida saqlanishi shart.
- Kodda textlardan foydalanishda `tr()` funksiyasi yoki `LocaleKeys` dan foydalaniladi.
- Har bir yangi text qo'shilganda barcha 3 ta tilda (uz, ru, en) tarjimasi berilishi majburiy.

### 1. Language Header

Barcha API so'rovlarida tanlangan tilni serverga bildirish uchun quyidagi header yuborilishi shart:

- `language`: `uz`, `ru` yoki `en`

### 2. Flutter Localization

Localizatsiya uchun `easy_localization` paketidan va `.json` fayllardan foydalaniladi (`lib/l10n/` papkasida).

- Har bir label uchun kalit so'zlar (keys) barcha 3 ta tilda mavjud bo'lishi shart.
- Generatsiya qilingan `locale_keys.g.dart` faylidan foydalaniladi.

---

## 🛑 Kod Qoidalari va Validatsiya

1.  **DTO va Modellar:** GraphQL'dan kelgan ma'lumotlar uchun har doim `fromJson` va `toJson` metodlariga ega modellar yaratilishi shart.
2.  **Majburiy Headerlar:** Barcha so'rovlarda quyidagi headerlar yuborilishi shart:

| Header          | Qiymat / Tavsif                                |
| --------------- | ---------------------------------------------- |
| `Accept`        | `application/json`                             |
| `Content-Type`  | `application/json`                             |
| `device`        | `android` yoki `ios`                           |
| `device-id`     | Qurilmaning noyob ID raqami (Unique ID)        |
| `device-name`   | Qurilma modeli nomi (masalan: `iPhone 15 Pro`) |
| `language`      | `uz`, `ru` yoki `en`                           |
| `Authorization` | `Bearer <token>` (agar login qilingan bo'lsa)  |

3.  **Security Headers (Mutations uchun):**
    Mutatsiyalar uchun qo'shimcha ravishda quyidagilar majburiy:
    - `Header-Random-Str`
    - `Header-Timestamp`
    - `Header-Sign` (Algoritm yuqorida keltirilgan)

4.  **UI/UX Qoidalari:**
    - **Filtrlash:** Home pageda kategoriyalar bo'yicha filtrlash client-side amalga oshirilishi kerak (barcha mahsulotlar bir marta olinadi).
    - **O'lchamlar (Variants):** Agar mahsulotda o'lchamlar 1 tadan ko'p bo'lsa, tanlash majburiy (default tanlanmagan bo'lishi kerak). 1 ta bo'lsa UI yashiriladi.
    - **Slider:** Sliderlarda text va button ko'rsatilishi shart. Width 100% (viewportFraction: 0.92+), radius: 20px, shadow va gradient overlay bo'lishi premium look uchun majburiy.
    - **Refresh:** Home pageda pull-to-refresh bo'lishi shart.
    - **Order History:** Buyurtmalar sahifasida barcha fieldlar (subtotal, delivery, total) aniq ko'rsatilishi va kartalar 16px radiusda bo'lishi shart.

5.  **Error Handling (Xatolarni boshqarish):**
    - GraphQL xatolarini (`GraphQLError`) tahlil qil va foydalanuvchiga tushunarli tilda ko'rsat.
    - Model parsingda `tryParse` va null-safety'dan foydalan (Orders va h.k).
    - Tarmoq xatolarini (Connectivity) alohida ushla.
6.  **Security:** `secretKey` (Header-Sign uchun) `--dart-define` yoki `.env` orqali berilishi kerak.
7.  **State Management:** Feature-based BLoC pattern. Logic UI dan to'liq ajratilgan bo'lishi kerak.
8.  **Testing (Dev Mode):** Hozirda test yozish majburiy emas (Dev Mode). Lekin har bir yangi qo'shilgan metod yoki mantiq qanday ishlashi haqida kodda sharhlar (documentation) yozib ketilishi shart. Kelajakda testlar qo'shiladi.
9.  **App Initialization (Splash):** Ilova ishga tushayotganda `settings` query orqali tizim holati tekshirilishi shart. Agar `can_order` false bo'lsa yoki boshqa texnik cheklov bo'lsa, foydalanuvchiga tegishli xabar ko'rsatilishi kerak.

---

## 📝 Claude uchun Task Berish Namuna

> "Ushbu `order` schema'dan foydalanib, buyurtma yaratish (`createOrder`) mutation'ini amalga oshir. Header signaturani hisoblashni unutma. Header'da `language: uz` yuborilishini ta'minla."

---

## ⚠️ Muhim Cheklovlar

- Dizayn uslubi: Dark/Light mode qo'llab-quvvatlanishi kerak (Premium look).
- API bilan ishlashda N+1 muammosidan qochish uchun fragmentlardan foydalan.
- **APK hajmi cheklovi (Telegram):** Telegram Bot orqali faqat 50MB gacha bo'lgan fayllarni yuborish mumkin. Agar APK hajmi 50MB dan oshishi taxmin qilinsa (masalan: `yandex_mapkit`, xarita kutubxonalari ishlatilganda), APK ni GitHub Releases yoki boshqa xizmat (masalan: Firebase App Distribution) orqali tarqatish kerak. CI/CD workflow'da hajm avtomatik tekshiriladi va 50MB dan katta bo'lsa GitHub Release'ga yuklanadi.

---

## 🔄 Avtomatik Yangilanish Qoidasi

Agent (Claude yoki boshqa AI) har safar foydalanuvchi tomonidan yangi texnik talab, cheklov yoki qoida berilganda, ushbu `AGENTS.md` faylini quyidagi tartibda yangilashi shart:
1. Yangi qoidani tegishli bo'limga qo'shish.
2. Agar yangi bo'lim kerak bo'lsa, uni yaratish.
3. Ushbu faylning oxirgi holatini doimo dolzarb saqlash.
