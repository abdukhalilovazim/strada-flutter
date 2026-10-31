# 🚀 Flutter → Play Store: To'liq Sozlash Qo'llanmasi

## 📁 Fayl joylashuvi
`.github/workflows/deploy.yml` ga ko'chiring

---

## 🔐 1-QADAM: Keystore yaratish (bir marta)

Agar keystore yo'q bo'lsa, terminalda:

```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias my-key-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Keystore'ni base64 ga o'tkazish:
```bash
base64 -i release.keystore | pbcopy   # Mac
base64 release.keystore | clip        # Windows
cat release.keystore | base64         # Linux
```

---

## 🔑 2-QADAM: GitHub Secrets sozlash

GitHub repo → Settings → Secrets and variables → Actions → New repository secret

| Secret nomi                    | Qiymati                                |
|-------------------------------|----------------------------------------|
| `KEYSTORE_BASE64`             | Yuqoridagi base64 chiqishi             |
| `KEYSTORE_PASSWORD`           | Keystore paroli                        |
| `KEY_PASSWORD`                | Key paroli                             |
| `KEY_ALIAS`                   | Key alias (masalan: my-key-alias)      |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google service account JSON (pastda) |

---

## 🌐 3-QADAM: Google Play Service Account yaratish

1. **Google Play Console** → Setup → API access
2. **Google Cloud Console** ga o'tish
3. Service Account yaratish:
   - IAM & Admin → Service Accounts → Create
   - Role: `Service Account User`
4. JSON key yaratish:
   - Service Account → Keys → Add Key → JSON
   - Yuklab olingan JSON ni `PLAY_STORE_SERVICE_ACCOUNT_JSON` ga joylashtirish
5. **Play Console'ga ruxsat berish**:
   - API access → Grant access → Service account'ni tanlash
   - Permission: Release manager yoki Admin

---

## 📱 4-QADAM: android/app/build.gradle sozlash

```gradle
android {
    ...
    signingConfigs {
        release {
            def keystorePropertiesFile = rootProject.file("key.properties")
            def keystoreProperties = new Properties()
            keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## 🏷️ 5-QADAM: Deploy qilish

```bash
# Yangi versiya chiqarish uchun:
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions avtomatik ishga tushadi! ✅
```

---

## 📊 Deploy yo'li (track)

| Track       | Izoh                              |
|-------------|-----------------------------------|
| `internal`  | Faqat test foydalanuvchilar (tavsiya) |
| `alpha`     | Alpha testerlar                   |
| `beta`      | Beta testerlar                    |
| `production`| Barcha foydalanuvchilar           |

**Tavsiya:** Avval `internal` → tekshirib → `production` ga ko'taring

---

## ❗ .gitignore ga qo'shish

```
android/key.properties
android/app/release.keystore
```