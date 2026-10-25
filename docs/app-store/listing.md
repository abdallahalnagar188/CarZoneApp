# Wash Up — App Store listing (version 1.1.0)

Copy each field into App Store Connect → Wash Up → App Store → 1.1.0.
Primary language: Arabic. Add English (U.S.) as a second localization.

## App Information
| Field | Value |
|---|---|
| Name | Wash Up |
| Subtitle (AR) | احجز غسيل سيارتك بسهولة |
| Subtitle (EN) | Book a car wash near you |
| Primary category | Lifestyle |
| Secondary category | Utilities |
| Content rights | Does not contain third-party content |
| Age rating | 4+ (answer "No / None" to every question) |
| Price | Free |
| Privacy Policy URL | https://abdallahalnagar188.github.io/CarZoneApp/privacy.html |
| Support URL | https://abdallahalnagar188.github.io/CarZoneApp/support.html |

## Arabic (primary)
**Promotional text (170 max)**
احجز غسيل سيارتك في أقرب مغسلة خلال ثوانٍ، وتابع حالة سيارتك لحظة بلحظة حتى تصبح جاهزة.

**Keywords (100 max)**
غسيل سيارات,مغسلة,حجز,تنظيف,تلميع,عناية بالسيارة,غسيل داخلي,مغاسل قريبة,القاهرة,مصر

**Description**
واش أب هو أسهل طريقة لحجز غسيل سيارتك.

اكتشف المغاسل القريبة منك على الخريطة، قارن الخدمات والأسعار والتقييمات، واختر الموعد المناسب لك. بعد الحجز تتابع حالة سيارتك مباشرة: في الانتظار، قيد الخدمة، ثم جاهزة للاستلام.

المميزات:
• خريطة للمغاسل القريبة منك مع الأسعار والتقييمات
• حجز فوري واختيار الموعد والخدمة والإضافات
• متابعة حية لحالة السيارة وإشعارات عند كل خطوة
• حفظ سياراتك والمغاسل المفضلة لحجز أسرع
• تقييم المغسلة بعد انتهاء الخدمة
• الدفع في المغسلة نقدًا أو بالبطاقة
• عربي وإنجليزي

التصفح لا يحتاج حسابًا، وتسجّل فقط عند الحجز برقم الموبايل أو Apple أو Google. يمكنك حذف حسابك في أي وقت من داخل التطبيق.

## English (U.S.)
**Promotional text**
Book a wash at the nearest car wash in seconds, then follow your car live until it is ready.

**Keywords**
car wash,carwash,car care,detailing,booking,wash near me,cleaning,polish,interior,cairo,egypt

**Description**
Wash Up is the easiest way to book a car wash.

Find washes near you on the map, compare services, prices and ratings, and pick the time that suits you. After you book, follow your car live: waiting, in service, then ready for pickup.

Features:
• Map of nearby car washes with prices and ratings
• Instant booking: pick the time, service and extras
• Live status of your car and a notification at every step
• Save your cars and favorite washes to book faster
• Rate the wash after your service
• Pay at the wash in cash or by card
• Arabic and English

Browsing needs no account. You sign in only when you book, with your mobile number, Apple or Google. You can delete your account at any time inside the app.

## What's New (1.1.0)
- AR: تسجيل الدخول باستخدام Apple، وإمكانية حذف الحساب من داخل التطبيق، وتحسينات عامة.
- EN: Sign in with Apple, in-app account deletion, and general improvements.

## App Review Information
- Sign-in required: Yes
- Notes for the reviewer:
  > Browsing washes needs no account. To book, tap "Continue with Apple" on the login screen (or use the test phone number below), enter a name and any Egyptian mobile number (e.g. 01000000000) on the profile screen, then pick a wash and a time.
  > Payment for the car wash happens in person at the wash (a physical service), so there is no in-app purchase.
  > Account deletion: Profile → Delete account.
- Test phone number / code: add one in Supabase → Authentication → Providers → Phone → "Test phone numbers and OTPs", then put it here.
- Contact: your name, phone and email.

## App Privacy (App Store Connect → App Privacy)
Tracking: **No**. Everything below is used for **App Functionality**, is **linked to the user**, and is **not used for tracking**.

| Data type | Why |
|---|---|
| Contact Info → Name | Shown to the wash when it receives the car |
| Contact Info → Phone Number | Sign-in and booking contact |
| Contact Info → Email Address | Comes from Apple or Google sign-in |
| Identifiers → User ID | Account ID |
| Identifiers → Device ID | Push notification token |
| Purchases → Purchase History | Booking history |
| User Content → Other User Content | Car details (plate, make, color) and reviews |

Location: the app uses location on the device to pick the nearest area and show nearby washes on Google Maps. It is not saved on our servers. If you want to be extra safe, also declare Location → Precise Location (App Functionality, not linked to the user).

## Encryption
The build sets `ITSAppUsesNonExemptEncryption = false` (only standard HTTPS), so App Store Connect does not ask this question.

## Screenshots
6.9" iPhone (1320 × 2868): see `docs/app-store/screenshots/`. The app is iPhone-only, so no iPad screenshots are needed.
