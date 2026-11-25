# Invoicer — تطبيق الفواتير (Flutter + Firebase)

أندرويد • عربي/إنجليزي • مزامنة بين الأجهزة • PDF ومشاركة على واتساب

## 1) جهّز Firebase (مرة واحدة)
1. ادخل https://console.firebase.google.com ← **Add project** (مجاني).
2. **Authentication ← Sign-in method**: فعّل **Email/Password** و **Google**.
3. **Firestore Database ← Create database** (Production mode، أقرب منطقة).
   ثم تبويب **Rules** والصق محتوى ملف `firestore.rules` واضغط Publish.

## 2) جهّز المشروع (على الكمبيوتر، محتاج Flutter + Android Studio)
```bash
flutter create --org com.invoicer --platforms=android invoicer
# انسخ محتويات الفولدر ده فوق فولدر invoicer (وافق على الاستبدال):
#   lib/  assets/  pubspec.yaml  analysis_options.yaml
cd invoicer
flutter pub get
```

## 3) اربط Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure      # اختار مشروعك وplatform: android
```
الأمر بيكتب `lib/firebase_options.dart` و `android/app/google-services.json` لوحده.

افتح `android/app/build.gradle(.kts)` وخلي:  `minSdk = 23`

## 4) تسجيل الدخول بـ Google (SHA-1)
```bash
cd android && ./gradlew signingReport     # انسخ SHA-1 بتاع variant: debug
```
Firebase Console ← Project settings ← تطبيقك الأندرويد ← **Add fingerprint** والصق الـ SHA-1.
بعدها شغّل `flutterfire configure` تاني عشان يحدّث `google-services.json`.

## 5) ابنِ الـ APK
```bash
flutter build apk --release
```
الملف: `build/app/outputs/flutter-apk/app-release.apk` ← ابعته لموبايلك وثبّته
(فعّل "التثبيت من مصادر غير معروفة").

## ملاحظات
- **واتساب:** زر "إرسال عبر واتساب" بيعمل PDF ويفتح قائمة المشاركة؛ اختار واتساب ثم العميل.
  (واتساب مش بيسمح لتطبيق يبعت ملف لرقم بعينه تلقائياً.)
- **الخط في PDF:** `assets/fonts/pdf_regular.ttf` و `pdf_bold.ttf` (DejaVu Sans).
  لو عايز خط Cairo أو Tajawal استبدل الملفين بنفس الأسماء.
- **أوفلاين:** تقدر تعمل فواتير من غير نت وهتترفع لما النت يرجع.
- **الشعار** بيتخزن مصغّر داخل Firestore (مفيش Firebase Storage عشان تفضل على الخطة المجانية).
