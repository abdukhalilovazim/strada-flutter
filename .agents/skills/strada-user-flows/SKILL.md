---
name: strada-user-flows
description: >-
  Standard operational manual and architectural guide for Strada Pizza Flutter user flows,
  business logic transitions, design specifications, payment gateway handoffs, and edge case handling.
---

# Strada Pizza — User Flows & Architecture Manual

This skill documents the complete end-to-end user journeys, state transitions, UI/UX guidelines, and error/edge-case handling for the Strada Pizza Flutter mobile application.

---

## 1. Product Flow (Mahsulotlar Oqimi)

### 1.1 Mahsulot Kartochkasi (`ProductCard`)
- **Joylashuvi:** `lib/features/home/presentation/widgets/product_card.dart`
- **Vizual Ko'rinish:** Uzum Tezkor uslubida:
  - 1:1 AspectRatio mahsulot rasmi (CachedNetworkImage + Shimmer placeholder).
  - Agar chegirma bo'lsa (`oldPrice != null && oldPrice > price`), chap yuqorida qizil chegirma nishoni.
  - Mahsulot nomi (1 qator, ellipsis, qalin shrift) va narxi (`NumberFormatter.formatSum`).
- **Holatlar va Harakatlar:**
  1. **Kartaga umumiy tegish (Tap on card):**
     - Har qanday holatda `ProductDetailModal.show(context, product)` oynasini ochadi.
  2. **Pastki tugma (Pastki-o'ng / Full-width button):**
     - `quantityInCart == 0` bo'lsa: Qizil "Ochish" (`product.open_btn`) tugmasi ko'rinadi. Bosilganda `ProductDetailModal.show(context, product)` ochiladi.
     - `quantityInCart > 0` bo'lsa: Qizil fonli `-` `[Miqdor]` `+` stepper ko'rsatiladi.
  3. **Stepper bosilganda (`+` yoki `-`):**
     - **`+` bosilganda:**
       - Agar mahsulotda **1 tadan ortiq variant bo'lsa** (`product.variants.length > 1`), modal ochiladi (foydalanuvchi qaysi o'lchamni oshirmoqchiligini tanlashi shart).
       - Agar mahsulot **variantsiz yoki faqat 1 ta variantli bo'lsa**, `CartCubit.addToCart(product, variant: ...)` to'g'ridan-to'g'ri chaqiriladi.
     - **`-` bosilganda:**
       - Savatdan tegishli mahsulot topiladi va `CartCubit.updateQuantity(cartItem, -1)` orqali miqdor kamaytiriladi. 0 ga yetganda savatdan o'chiriladi.

### 1.2 Mahsulotning Modal Oynasi (`ProductDetailModal`)
- **Joylashuvi:** `lib/features/home/presentation/widgets/product_detail_modal.dart`
- **Arxitekturasi:** `Dialog` sifatida ochiladi, qorong'u orqa fon (`barrierColor: 0.65`).
- **Variantsiz Mahsulotlar (0 yoki 1 ta variant):**
  - Segmented variant tanlov bloki yashiriladi.
  - Asosiy narx: `product.price`.
  - Stepper (`-` `[1]` `+`): foydalanuvchi xohlagancha miqdor tanlaydi (minimum 1).
- **Variantli Mahsulotlar (>1 ta variant, masalan: 25cm / 30cm / 35cm):**
  - Segmented variant tanlagich chiqadi.
  - Default holatda birinchi variant (`product.variants.first`) tanlangan bo'ladi.
  - Har bir variant tanlanganda `_selectedVariant` yangilanadi va pastdagi narx dinamik ravishda `_selectedVariant.price * _quantity` ga hisoblanadi.
- **Amallar Tugmalari:**
  1. **"Savatga qo'shish" (`product.add_to_cart_full` — Outlined Button):**
     - Mahsulot va tanlangan variant/miqdorni `CartCubit.addMultipleToCart` orqali savatga qo'shadi.
     - Modal yopiladi (`Navigator.pop`).
     - Ekranda yashil "Savatga qo'shildi" floating SnackBar chiqadi.
  2. **"Hozir xarid qilish" (`product.buy_now` — Filled Red Button):**
     - Mahsulotni savatga qo'shadi.
     - Modal yopiladi.
     - Darhol `/cart` (Savat) sahifasiga o'tadi (`context.push('/cart')`).
  3. **Yopish (X tugmasi yoki tashqariga tegish):**
     - Dialogni hech qanday o'zgarishsiz yopadi.

---

## 2. Cart Flow (Savat Oqimi)

- **Joylashuvi:** `lib/features/cart/presentation/pages/cart_page.dart`
- **Bo'sh Holat (`state.items.isEmpty`):**
  - Markazda sumka ikonkasi, "Savatingiz bo'sh", "Menyudan taomlarni tanlang" matni.
  - "Asosiy sahifaga o'tish" tugmasi → `context.go('/home')`.
- **Mahsulotlar Mavjud Holat:**
  - Har bir elementda: rasm, mahsulot nomi, tanlangan variant nomi (agar bo'lsa), birlik narxi va qatordagi umumiy narx.
  - **Miqdor Stepperi:**
    - Agar miqdor `1` bo'lsa, chap tugma qizil `delete` (axlat qutisi) ikonkasiga aylanadi. Bosilganda element savatdan o'chiriladi.
    - Agar miqdor `> 1` bo'lsa, oddiy `-` belgisi bo'ladi.
    - `+` tugmasi miqdorni oshiradi.
  - **Pastki Fiksatsiyalangan Panel:**
    - Jami summa (`NumberFormatter.formatSum(state.subtotal)`).
    - "Rasmiylashtirish" (`cart.checkout`) tugmasi → `context.push('/checkout')`.

---

## 3. Checkout Flow (Buyurtma Rasmiylashtirish Oqimi)

- **Joylashuvi:** `lib/features/cart/presentation/pages/checkout_page.dart`

### 3.1 Yetkazib Berish / Olib Ketish Tanlovi
- **Yagona Karta Dizayni:**
  - Sahifaning eng yuqori qismida bitta chiroyli karta turadi:
    - Yetkazib berish (Delivery) tanlangan bo'lsa: "Yetkazib berish" tegi, manzil nomi va hisoblangan yetkazib berish narxi.
    - Olib ketish (Pickup) tanlangan bo'lsa: "Olib ketish" tegi va tanlangan filial nomi (yetkazib berish narxi 0 bo'ladi).
    - O'ng tomonda "O'zgartirish" (`common.change`) tugmasi.
- **`OrderTypeBottomSheet` (Tanlov oynasi):**
  - Foydalanuvchi kartani bosganda pastdan ochiladi.
  - Ikkita tab: "Yetkazib berish" va "Olib ketish".
  - **Yetkazib berish tanlanganda:**
    - Agar manzil tanlanmagan bo'lsa: "Xaritadan manzilni belgilash" tugmasi.
    - Agar manzil bor bo'lsa: joriy manzil matni va "Xaritadan o'zgartirish" tugmasi.
    - Tugma bosilganda `MapPickerPage` ochiladi. Xaritada nuqta tanlangach, `setAddressAndCalculateDelivery(lat, lng, address)` orqali backenddan real yetkazib berish narxi olinadi.
  - **Olib ketish tanlanganda:**
    - Mavjud filiallar ro'yxati radio orqali ko'rsatiladi.
    - Filial tanlanganda `setBranch(branch.id, branchTitle: branch.title)` chaqiriladi va yetkazib berish narxi avtomatik 0 so'mga aylanadi.

### 3.2 Foydalanuvchi Shaxsi (Login vs Mehmon)
1. **Tizimga kirgan foydalanuvchi (`_isLoggedIn == true`):**
   - Hech qanday ism/telefon kiritish maydoni ko'rsatilmaydi!
   - Kichik ixcham kartochkada foydalanuvchi ismi va telefon raqami ko'rinadi (`+998 XX XXX XX XX`).
2. **Mehmon foydalanuvchi (`_isLoggedIn == false`):**
   - Ism kiritish (`AppTextField`, matn) va Telefon raqam kiritish (`+998` prefiksi, 9 ta raqam) chiqadi.
   - Buyurtma berish tugmasi bosilganda:
     1. Ism va telefon validatsiyadan o'tkaziladi.
     2. Serverga `loginWithChannel` so'rovi yuboriladi.
     3. Pastdan `CheckoutOtpSheet` ochiladi (4 raqamli SMS/Telegram OTP).
     4. Kod to'g'ri kiritilgach, avtorizatsiya tokeni va foydalanuvchi ma'lumotlari `SecureStorage` ga saqlanadi.
     5. Foydalanuvchi tizimda avtorizatsiyadan o'tgan bo'lib qoladi va keyingi buyurtmalarda qayta so'ralmaydi.

### 3.3 To'lov Usullari va Qaytim (Payment Methods & Change)
1. **Naqd pul (Cash / ID 0):**
   - Tanlanganda "Qaytim kerakmi?" (Change needed) switcheri ko'rinadi.
   - Switch yoqilganda qancha summadan qaytim kerakligi kiritiladigan maydon ochiladi (`_changeController`).
2. **Payme (ID 1) yoki Click (ID 2):**
   - Tanlanganda "Qaytim" switcheri avtomatik ravishda yashiriladi.
   - Backendga so'rov yuborilganda `payment_url` qaytariladi.

### 3.4 Promokod va Izoh
- Promokod switch yoqilganda: input maydoni va "Tekshirish" tugmasi chiqadi. Valid bo'lsa chegirma foizi yoki summasi `CheckoutCubit` ga saqlanadi va jami summadan ayiriladi.
- Izoh switch yoqilganda: kuryer yoki oshxona uchun ko'p qatorli `AppTextField` maydoni ochiladi.

---

## 4. Order Confirmation Flow (Buyurtmani Tasdiqlash)

- **Joylashuvi:** `lib/features/cart/presentation/widgets/order_confirmation_sheet.dart`
- **Mantiq:**
  - Foydalanuvchi "Buyurtma berish" tugmasini bosganda, darhol API chaqirilmaydi.
  - Oldin `OrderConfirmationSheet` dialogi ochilib, barcha ma'lumotlar foydalanuvchiga xulosa ko'rinishida taqdim etiladi:
    1. **Yetkazib berish turi:** Manzil yoki Filial.
    2. **Qabul qiluvchi:** Ism va formatlangan telefon raqami.
    3. **To'lov usuli:** Naqd pul / Payme / Click.
    4. **Mahsulotlar ro'yxati:** Har bir mahsulot nomi, varianti, miqdori va narxi.
    5. **Izoh:** Agar yozilgan bo'lsa.
    6. **Moliyaviy hisob-kitob:** Oraliq summa, yetkazib berish to'lovi, chegirma va yakuniy to'lanadigan summa.
  - Foydalanuvchi "Buyurtmani tasdiqlash" tugmasini bosgandagina `_executeSubmitOrder` chaqirilib, backendga `POST /api/v1/orders` so'rovi ketadi.

---

## 5. Post-Order & Payment Gateway Return Flow (Buyurtmadan Keyingi Holat)

### 5.1 Buyurtma Muvaffaqiyatli Yaratilganda (`_handleSuccess`)
1. Backend `201 Created` qaytaradi (`order_id`, `payment_url`, va to'liq `data`).
2. `AnalyticsService.logOrderPlaced` hodisasi yuboriladi.
3. Savat to'liq tozalanadi: `cartCubit.clear()`.
4. Checkout holati qayta tiklanadi: `checkoutCubit.resetAfterOrder()`.
5. **Agar Payme / Click bo'lsa:**
   - `payment_url` mavjud bo'lsa, `launchUrl(uri, mode: LaunchMode.externalApplication)` orqali brauzer yoki to'lov ilovasi ochiladi.
6. Ilova `/order/:orderId` sahifasiga `extra: orderEntity` bilan yo'naltiriladi.

### 5.2 Payme/Click'dan Ilovaga Qaytib Kelinganda (`OrderDetailPage`)
- **Joylashuvi:** `lib/features/orders/presentation/pages/order_detail_page.dart`
- **Mumkin bo'lgan muammo:** Foydalanuvchi tashqi brauzerdan qaytganda GoRouter navigatsiya steki yo'qolishi yoki `extra` null kelishi mumkin.
- **Yechim va Arxitektura:**
  - `OrderDetailPage` — `StatefulWidget`.
  - Agar `widget.order == null` bo'lsa (masalan, bevosita URL yoki qayta yuklanish orqali kirilganda), `_fetchOrder()` metodi avtomatik ishga tushadi:
    - `ApiClient().get('orders/${widget.orderId}')` orqali buyurtmaning dolzarb holatini yuklaydi.
    - Agar xato bo'lsa, "Qayta urinish" tugmasini ko'rsatadi.
  - **Orqaga qaytish xavfsizligi (`_buildBackButton`):**
    - `context.canPop() ? context.pop() : context.go('/orders')`.
    - Bu foydalanuvchi tashqi ilovadan qaytganda orqaga tugmasini bossa oq ekran chiqib qolishini yoki ilovadan chiqib ketishini 100% oldini oladi.
  - **Holat va Amallar:**
    - Agar to'lov qilinmagan bo'lsa (`showPayNow == true`): pastda "To'lash" tugmasi chiqadi (qayta to'lov linkiga o'tish uchun).
    - Agar buyurtma tayyorlanayotgan bo'lsa va filial raqami bo'lsa: "Filial bilan bog'lanish" (`tel:...`) tugmasi chiqadi.
    - Agar buyurtma yetkazilgan bo'lsa (`status == 6`): "Qayta buyurtma" tugmasi chiqadi va mahsulotlarni bir bosishda yana savatga solish imkonini beradi.

---

## 6. Dizayn Tizimi va Sifat Standartlari (Design System & Quality)

- **Tipografiya:** Faqat `AppTextStyles` (Inter shrifti).
- **Ranglar:**
  - Primary: `AppColors.primary` (`#D32F2F` — Qizil)
  - Secondary/Muvaffaqiyat: `AppColors.secondary` (`#2E7D32` — Yashil)
  - Fon: `AppColors.surface` / `AppColors.darkSurface`
- **Narxlar:** Har doim `NumberFormatter.formatSum(sum)` orqali formatlanadi.
- **Mahalliylashtirish:** Hardcoded stringlar umuman ishlatilmaydi. Har bir matn `uz.json`, `ru.json`, `en.json` da bo'lishi va `.tr()` orqali chaqirilishi shart.
- **Xatoliklar:** Har qanday internet uzilishi yoki server xatosi do'stona xabar va `common.retry` tugmasi bilan ta'minlanadi.
