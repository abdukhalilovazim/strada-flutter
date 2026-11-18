# 🚀 Pizza Strada Deploy va Build Qo'llanmasi

## 🤖 Android Release Build

### 1. AppBundle (Google Play Store uchun)
```bash
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter build appbundle --release --obfuscate --split-debug-info=build/debug-symbols/android --android-skip-build-dependency-validation
```

---

## 🍏 iOS Release Build (App Store / TestFlight)

### 1. IPA (App Store Connect uchun)
```bash
flutter clean && flutter pub get && cd ios && pod update && cd .. && dart run build_runner build --delete-conflicting-outputs && flutter build ipa --release --obfuscate --split-debug-info=build/debug-symbols/ios
```
