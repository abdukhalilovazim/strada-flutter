# Strada Pizza - Yangi UI (Green Theme) bo'yicha Texnik Topshiriq (TZ)

Ushbu hujjat Strada Pizza ilovasining joriy UI dizaynini taqdim etilgan "Green Theme" (Yashil mavzu) dizayniga to'liq o'tkazish bo'yicha qadam-ba-qadam texnik topshiriqni (TZ) o'z ichiga oladi.

## 1. Umumiy Dizayn Tizimi (Design System) Yangilanishi

### 1.1. Ranglar (AppColors)
Ilovaning asosiy ranglari (Primary Color) joriy qizil rangdan yangi yashil rangga o'zgartiriladi.
- **Primary Color:** Ochiq yashil (Masalan: `0xFF5BCE74` yoki dizayndagi mos yashil).
- **Background Color:** Sof oq (`0xFFFFFFFF`) va ochiq kulrang (`0xFFF7F7F7`).
- **Text Colors:** To'q kulrang/qora (`0xFF1A1A1A`) va yordamchi matnlar uchun ochiqroq kulrang (`0xFF8E8E93`).
- **Surface/Card Color:** Sof oq (`0xFFFFFFFF`) yumshoq soya (box-shadow) bilan.

### 1.2. Tipografiya (AppTextStyles)
- Shrift (Font) asosan `Inter` yoki `Outfit` qoladi.
- Sarlavhalar (H1, H2, H3) qalinroq (Bold - 600/700) va quyuqroq rangda.
- Narxlar uchun ishlatiladigan shrift alohida yashil rang bilan ajratilishi kerak.

### 1.3. Umumiy UI Elementlar (Core Widgets)
- **AppButton:** Asosiy tugma (Primary Button) endi to'liq yashil fonda, ichidagi matn oq rangda bo'ladi. Burchaklari (border-radius) ko'proq yumaloqlangan (`24px` yoki `32px`).
- **Card Soya (Shadows):** Kartochkalar atrofida juda yumshoq va tarqoq soya (blurRadius: 15, offset: 0, 5, color: black12) ishlatiladi.
- **Bottom Navigation Bar:** Joriy navbar o'rniga ichki "Floating" yoki oq fonli, faol element yashil fonli kapsula (pill) shaklida bo'lgan zamonaviy navbar yoziladi (Home, Heart, Bag, Ticket, Profile).

---

## 2. Sahifalar (Pages) Bo'yicha O'zgarishlar

### 2.1. Home Page (`/home`)
- **App Bar:** 
  - Chap tomonda foydalanuvchi nomi ("Hello 👋 Delisas Agency").
  - O'ng tomonda Qidiruv (Search) va Bildirishnoma (Notification) ikonkalari (dumaloq fon ichida).
- **Kategoriyalar (Categories):**
  - Gorizontal "Sticky Chips" o'rniga, dizayndagidek 4-5 ta ustunli (Grid) yoki gorizontal scroll bo'ladigan, har birida rasm/ikonka va tagida nomi yozilgan dumaloq yoki to'rtburchak shakldagi tugmalar.
- **Promo Banner:**
  - Katta, qalin burchakli (20px radius) yashil/qoramtir promo banner ("New Year Offer 30% OFF").
- **Best Sellers (Mahsulotlar Grid/List):**
  - Sarlavha: "Best Sellers" va "See All" tugmasi.
  - Kartochka dizayni: Mahsulot rasmi o'rtada katta, tagida nomi va narxi. Yonida "Kaloriya" va "Vaqt" (olov va soat ikonkalari) chiqadi. 
  - Eng muhimi: Kartochkaning pastki o'ng burchagida faqat kichik yashil `+` (Savatga qo'shish) tugmasi joylashadi.

### 2.2. Product Detail Page (`/product/:slug`)
- **Tuzilishi:** Rasm ekranning eng tepasida katta o'lchamda joylashadi, orqa fonsiz (shaffof PNG).
- **App Bar:** Orqaga, Sevimlilar (Heart), va Ulashish (Share) tugmalari.
- **Tafsilotlar:** Mahsulot nomi, do'kon nomi va Reyting (4.8).
- **Variantlar (Sizes):** Kvadrat shakldagi qutilar, tanlangani yashil chegarali (Border) va ichida yashil radio tugmacha bilan ko'rsatiladi (Masalan: 6" - Small, 8" - Medium).
- **Qo'shimchalar (Add Ingredients):** Ingredientlar ro'yxati chiqadi, yonida narxi va Checkbox (Yashil).
- **Bottom Bar:** 
  - Chapda dumaloq shakldagi Savat miqdorini tanlash (Stepper: - 1 +).
  - O'ngda katta "Add to Cart • $11.88" yashil tugmasi.

### 2.3. Cart Page (`/cart`)
- **Ro'yxat:** Savatdagi mahsulotlar kichik rasmi chap tomonda, o'rtada nomi va narxi, o'ng tomonda esa yashil Stepper (- 1 +) shaklida chiqadi.
- **Promo Code:** Savat ro'yxatining pastida bitta qatorda Input va "Apply" yashil tugmasi.
- **Xulosa (Summary):** Subtotal, Delivery, Total narxlar yozuvi pastga qo'yiladi. Total narx yashil rangda bo'ladi.
- **Bottom Bar:** Katta yashil "Checkout • $26.43" tugmasi.

### 2.4. Tracking / Map Page (`/map-picker` & `/tracking`)
- Dizayndagi xarita asosan Tracking (Kuryerni kuzatish) uchun mo'ljallangan. 
- Xarita ustida dumaloq status paneli (20 min Delivery - The courier is on the way).
- Kuryer ma'lumotlari: Rasmi, Ismi, Reytingi, va Aloqa (Chat/Call) tugmalari.
- Status Timeline (Buyurtma qabul qilindi, Tayyorlanmoqda, Yo'lda, Yetkazildi) vertikal ro'yxat shaklida pastda chiqadi. Tanlangan holat yashil marker bilan ajralib turadi.

### 2.5. Order Details Page (`/order/:id`)
- Do'kon logotipi va nomi, Buyurtma raqami va sanasi.
- "Arrival Time" (Yetib kelish vaqti) alohida yashil qutida (20 min).
- Buyurtma qilingan mahsulotlar ro'yxati (rasmi, nomi, o'lchami va narxi bilan).

### 2.6. Notification Page (`/notifications`)
- Yangi sahifa. Har bir bildirishnoma avatar/logo bilan chiqadi.
- Agar u tasdiqlashni so'raydigan xabar bo'lsa (Masalan, Decline, View Details tugmalari bilan) interaktiv bo'ladi.

---

## 3. Texnik O'zgarishlar va State Management

- **Mavjud Arxitektura:** Clean Architecture + BLoC saqlanadi. UI faqatgina Presentation qatlamida o'zgaradi.
- **HomeCubit / CartCubit / OrderCubit:** State va Logic deyarli o'zgarmaydi, faqat UI qismlari ushbu datalarni yangicha dizaynda chizadi.
- **Routing (`go_router`):** Pastki Navbar o'zgarishi munosabati bilan `ShellRoute` (yoki Custom Bottom Nav) strukturasi yangi dizaynga moslashtiriladi.
- **Icons & Assets:** Dizayndagi barcha ikonkalarni (Line icons) `AppIcons` ga o'zlashtirish yoki qo'shish kerak. Rasm assetlarini shaffof va sifatli PNG ga almashtirish maqsadga muvofiq.

## 4. Amalga Oshirish Bosqichlari (Implementation Plan)

1. **Theme Setup:** `AppColors`, `AppTextStyles`, `AppTheme` va `AppButton` kabi core UI komponentlarni yangi "Yashil" dizaynga moslashtirish.
2. **Bottom Navigation Bar:** Yangi "Pill" uslubidagi Bottom Nav Bar yaratish.
3. **Home Page & Product Card:** `HomePage` va uning ichidagi `ProductCard` komponentlarini dizayndagidek Grid + Banner ko'rinishiga o'tkazish.
4. **Product Detail Page:** Yangi `ProductDetailPage` ni to'liq shaffof rasm, variant tanlash kvadrati va Stepper bar bilan noldan chizish.
5. **Cart & Checkout UI:** `CartPage` va `CheckoutPage` ni yangi dizayndagi toza va oq UI ga o'tkazish. Promo-kod blokini optimallashtirish.
6. **Order Tracking & Details:** `Order Tracking` xaritasi va Status Timeline ni yaratish.

---
**Qabul qilish (Approve):** Ushbu TZ bo'yicha ishlarni boshlash uchun o'z tasdig'ingizni bering yoki qo'shimcha o'zgartirishlaringiz bo'lsa yozib qoldiring.
