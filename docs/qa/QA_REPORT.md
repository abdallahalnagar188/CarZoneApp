# تقرير QA: تطبيق CarZone للعملاء وربطه بـ Supabase

**التاريخ:** 19 أكتوبر 2026 · **الفرع:** `Work` (بعد دمج `Home`، commit `bc81130`) · **مشروع Supabase:** `tbcmgdwzarfdgzzmmele`

---

## 1. الخلاصة

- **الربط بـ Supabase شغّال، والأداء ممتاز.** على 50 مستخدم متزامن: 2,781 طلب، 0% أخطاء، p95 = 155ms. كل شاشات التطبيق بتحمّل في أقل من 400ms عند p95.
- **الأمان من برّه (للزائر غير المسجّل) سليم.** 39 من 40 فحص نجحوا. الثغرة الوحيدة إن الـ `branch_shares` view بيكشف `user_id`.
- **المشكلة الحقيقية في كتابة البيانات ومنطق التطبيق، مش في القراءة:**
  - **4 مشاكل Critical:** سرقة حساب عن طريق رقم التليفون، Edge Function للـ SMS من غير حماية، العميل يقدر يعدّل سعر وحالة الطلب بنفسه، والحجوزات الجديدة غالبًا مش بتتحفظ والتطبيق بيقول "تم بنجاح".
  - **8 مشاكل High:** التقييمات والشكاوى مش بتتحفظ، الخصومات مش بتتطبّق، فرق توقيت 2–3 ساعات في المواعيد، وغيرها.
- **الأخطاء بتتبلع في صمت.** كل عمليات الكتابة تقريبًا محطوطة في `try/catch` بيعمل `dev.log` بس، فالمستخدم يشوف نجاح والبيانات ماتتحفظش. ده سبب إن المشاكل دي ماظهرتش قبل كده.

| المستوى | العدد |
|---|---|
| Critical | 4 |
| High | 8 |
| Medium | 16 |
| Low | 9 |

---

## الحالة الحالية

> **آخر تحديث: 19 أكتوبر 2026.** مرحلة الأمان الأولى (C1 و C2 و C3) اتصلّحت في الكود في commit `528e1df` على فرع `Work`، لكنها **لسه ماتعملهاش push ولا deploy**، فالثغرات لسه مفتوحة على السيرفر الـ live. من 37 مشكلة: 8 اتصلّحوا، و 6 اتصلّح جزء منهم، و 23 لسه. أول خطوة مطلوبة هي الـ deploy (القسم 6).

| ID | الحالة | اللي اتعمل | اللي فاضل |
|---|---|---|---|
| C1 | ✅ اتصلّحت | الربط بالرقم اللي اتأكد بالـ OTP بس، والعميل مايقدرش يغيّر رقمه أو حالته | الـ deploy، والتحقق من الرقم بالـ OTP لمستخدمي Google |
| C2 | ✅ اتصلّحت | توقيع إجباري، fail closed، فحص الـ OTP والرقم | الـ deploy بعد ضبط `SEND_SMS_HOOK_SECRET` |
| C3 | ✅ اتصلّحت | RPCs للحجز والإلغاء وإعادة الجدولة، وRESTRICTIVE policies | الـ deploy + نسخة تطبيق جديدة |
| C4 | ✅ اتصلّحت | السيرفر بيولّد رقم الطلب | الـ deploy |
| H12 | ✅ اتصلّحت | العميل الوهمي اتشال، والخطأ بيظهر للمستخدم | — |
| M6 | ✅ اتصلّحت | trigger بيمنع العميل يغيّر `status` | الـ deploy |
| M8 | ✅ اتصلّحت | مفيش `branch!` في الحجز، والـ spinner بيقف مع أي خطأ | — |
| Low | ✅ اتصلّحت | `sync_customer_profile` مابقاش يتنفّذ من anon | الـ deploy |
| H8 | ◐ جزئي | السيرفر بيرفض أي حجز مخالف، فمفيش overbooking | قايمة المواعيد اللي بتظهر لسه بتتحسب على الموبايل |
| H9 | ◐ جزئي | السيرفر بيطبّق الخصم وقت الحجز | الشاشة بتعرض السعر من غير خصم |
| H10 | ◐ جزئي | الحجوزات الجديدة بتتسجّل وتتعرض صح | تصحيح الحجوزات القديمة في الداتابيز |
| H11 | ◐ جزئي | الإلغاء وإعادة الجدولة بيعدّلوا الأعمدة المطلوبة بس | Realtime |
| M7 | ◐ جزئي | الـ timeline بيتقري صح | ملاحظة الحجز لسه بتضيع |
| M13 | ◐ جزئي | الـ OTP مابقاش بيتسجّل، والـ simulation بإذن صريح | rate limit |

**لسه ماتعملش (23):** H5، H6، H7، M1، M2، M3، M4، M5، M9، M10، M11، M12، M14، M15، M16، و 8 من الـ Low.

**التستات الحالية:** تستات الـ migration على PGlite نجحت 22/22 (`npm run test:db`)، وتستات الـ SMS hook نجحت 12/12 (`deno test`)، وفي `test/qa` 19 نجحوا و 4 فشلوا (H6 و H7 و H9).

---


## 2. اللي اتعمل

| # | النشاط | الأداة | النتيجة |
|---|---|---|---|
| 1 | دمج `Home` في `Work` | git | fast-forward، 132 ملف، من غير conflicts (ماتعملّوش push) |
| 2 | مراجعة كود الربط: init، auth، session، كل استدعاءات `.from()` و`.rpc()` | مراجعة يدوية + agent | 37 ملاحظة (تحت) |
| 3 | مراجعة الـ migrations والـ RLS policies والـ RPCs | مراجعة SQL | ثغرات Critical في `sync_customer_profile` وفي صلاحيات الـ UPDATE على الـ orders |
| 4 | مراجعة الـ Edge Functions (`send-sms-whatsapp`، `share-wash`) | مراجعة كود | الـ webhook من غير توقيع إجباري، XSS، تسجيل الـ OTP في الـ logs |
| 5 | فحص صلاحيات الزائر على 61 جدول/view (قراءة فقط) | curl + Node test | الكتالوج مفتوح، وكل البيانات الشخصية والمالية مقفولة ✅ |
| 6 | Load test لرحلات المستخدم (Home، Search، Details، Map) | **k6** | 0% أخطاء، p95 = 155ms على 50 VU |
| 7 | Benchmark لكل endpoint لوحده | **autocannon** | أبطأ query: reviews (p99 = 1.36s) |
| 8 | Profiling لطبقة البيانات | **Clinic.js Doctor** | I/O bound، الوقت كله انتظار شبكة، مفيش مشكلة CPU أو memory |
| 9 | `flutter analyze` | Flutter | 0 issues ✅ |
| 10 | التستات الموجودة (الـ offline بس) | flutter test | 12/12 نجحوا ✅ |
| 11 | **تستات جديدة لسدّ الفجوات** | flutter test + node:test | 27 تست Flutter، و40 تست للزائر، و17 تست RLS للعميل المسجّل |

> **ملحوظة عن Clinic.js:** الأداة بتحلّل processes بتاعة Node.js بس، والنظام مافيهوش Node (Flutter + Supabase + Deno). عشان كده عملت harness بـ Node (`qa/profiling/app_data_layer_server.js`) بينفّذ نفس الـ queries ونفس الـ mapping اللي في `CarzoneDbService` بالظبط، وحلّلته. اكتشفت كمان إن Clinic بيقف في صمت لأنه بيستنى موافقة على الـ analytics. الحل `NO_INSIGHT=1`، وهو متضاف في الـ scripts.

---

## 3. نتايج الأداء

### k6: رحلات المستخدم (`qa/load/k6_app_journeys.js`، profile: light، 0→50 VU في دقيقتين)

| الشاشة | avg | med | p95 | p99 | max |
|---|---|---|---|---|---|
| Home (4 queries بالتوازي) | 183ms | 118ms | **353ms** | 1.26s | 1.97s |
| Search (branches + services) | 236ms | 205ms | **357ms** | 779ms | 2.25s |
| Wash details (3 queries) | 152ms | 109ms | **267ms** | 996ms | 1.72s |
| Map (60 فرع) | 116ms | 100ms | **153ms** | 585ms | 965ms |
| **كل الطلبات** | 118ms | 101ms | **155ms** | 710ms | 1.98s |

كل الـ thresholds نجحت: 0 failed requests من 2,781، والـ schema_ok كان 100%.

### autocannon: كل endpoint لوحده (10 connections × 10 ثواني)

| Endpoint | req/s | p50 | p99 | max | KB/req |
|---|---|---|---|---|---|
| app_health | 98 | 96ms | 243ms | 330ms | 1.0 |
| areas | 97 | 98ms | 238ms | 369ms | 2.5 |
| branches limit 10 | 73 | 99ms | **1042ms** | 1950ms | 7.0 |
| offers + offer_branches | 96 | 100ms | 219ms | 261ms | 3.1 |
| services limit 25 | 92 | 103ms | 222ms | 331ms | 8.9 |
| branches limit 60 | 96 | 100ms | 223ms | 398ms | 8.8 |
| branch by id | 97 | 96ms | 269ms | 520ms | 1.6 |
| services by branch | 97 | 99ms | 232ms | 338ms | 3.2 |
| **reviews by branch (ordered)** | **62** | 103ms | **1356ms** | 2597ms | **10.9** |

### Clinic.js Doctor

- **التشخيص:** `issueCategory = io`، والـ event loop delay = none، والـ memory = none.
- يعني الـ client بيقضي وقته كله تقريبًا مستني الشبكة. الحل تقليل عدد الـ round trips، مش تحسين الكود المحلي.

### توصيات الأداء

1. **Index على `reviews(branch_id, created_at desc)`**، لأن ده أبطأ query وأتقل payload.
2. **`select=*` في كل الـ queries.** اختار الأعمدة اللي محتاجها بس، والـ reviews بالذات 10.9KB لكل طلب.
3. **الـ Home بيعمل 4 round trips.** RPC واحد (`get_home_feed`) يرجّع كل حاجة هيقلّل الوقت للنص تقريبًا على شبكات الموبايل.
4. **البيانات بتتحمّل مرتين عند فتح التطبيق:** مرة من `CarzoneDbService.init` ومرة من الـ splash.

---

## 4. المشاكل (مرتّبة حسب الخطورة)

> ✅ = اتأكدت منها بالتشغيل أو الكود بنفسي · 🧪 = عليها تست بيفشل لحد ما تتصلّح

### 🔴 Critical

**QA-C1 · سرقة حساب عن طريق `sync_customer_profile`** ✅
`supabase/migrations/20261016183000_customer_app_integration.sql:303-316`. الـ RPC بيربط أي عميل رقمه يساوي `p_phone` بالـ `auth.uid()` الحالي، من غير ما يتأكد إن الرقم ده بتاع المستخدم (`auth.jwt()->>'phone'`) وإن الصف مش مربوط بحد تاني (`user_id IS NULL`). في الـ Google flow المستخدم بيكتب الرقم بإيده (`auth_controller.dart:263-280`)، فأي حد يسجّل بـ Google ويكتب رقم عميل تاني ياخد حجوزاته وعربياته.
**الحل:** استخدم الرقم من الـ JWT بس، واربط بس لو `user_id IS NULL`.

**QA-C2 · Edge Function الـ SMS بتقبل طلبات من غير توقيع** ✅
`supabase/functions/send-sms-whatsapp/index.ts:31-46`. التوقيع بيتراجع بس لو الـ secret والـ header موجودين مع بعض، ولو مش موجودين بيعمل `JSON.parse` مباشرة. وقيمة `otp` بتتحط في نص الرسالة زي ما هي. النتيجة إن أي حد يقدر يبعت أي نص لأي رقم من حساب واتساب الشركة. والتست `test/edge_function_test.dart` نفسه بيثبت إن production بيقبل payload من غير توقيع.
**الحل:** التوقيع إجباري دايمًا، و`otp` لازم يطابق `^\d{6}$`.

**QA-C3 · العميل يقدر يعدّل أي عمود في الطلب** ✅
الـ migration نفسه (`:136`، `:145-154`): `GRANT UPDATE ON orders` والـ policy بتتحقق من صاحب الصف بس، مش الأعمدة. أي عميل يقدر من الـ API يعمل `total=0` أو `status='completed'` أو `payment_status='paid'`. والتطبيق نفسه بيعمل كده في `OrderService.advance()` (`order_service.dart:152-172`، زرار debug). كمان السعر والخصم بيتحسبوا على الموبايل وبيتبعتوا زي ما هم.
**الحل:** شيل الـ UPDATE المباشر، واعمل RPCs (`create_order` / `cancel_order` / `reschedule_order`) تحسب السعر وتتحقق من الحالة على السيرفر.

**QA-C4 · الحجوزات الجديدة غالبًا مش بتتحفظ، والمستخدم يشوف نجاح** ✅ 🧪
رقم الطلب `CZ-#####` بيتولّد على الموبايل من الطلبات اللي يشوفها العميل (طلباته هو بس بسبب الـ RLS)، فكل عميل جديد بيبدأ من `CZ-10001`. لكن `orders.number` عليه UNIQUE، فالـ insert يفشل، و`saveOrder` بيبلع الخطأ (`carzone_db_service.dart:545`)، وشاشة النجاح بتظهر. نفس الكلام في رقم الشكوى `TK-501`.
**التأكيد النهائي:** تست `order lifecycle` في `qa/rls/customer_rls.test.mjs`.
**الحل:** السيرفر هو اللي يولّد الرقم (`next_order_number`) والكود (`gen_check_in_code`)، والأخطاء لازم تظهر للمستخدم.

### 🟠 High

| ID | المشكلة | المكان | الحل |
|---|---|---|---|
| QA-H5 | الـ **access JWT بتاع Supabase بيتحفظ كـ push token** في `push_devices`، وبيتضاف صف جديد مع كل refresh، وماحدش بيمسحه عند الـ logout | `carzone_db_service.dart:600-609`، `session_service.dart:57-63,169` | خزّن FCM token، واعمل upsert على `(user_id, token)`، وامسحه عند الـ logout |
| QA-H6 🧪 | **التقييمات مش بتتحفظ:** بيتبعت `customer_name` و`service_name` (مش أعمدة)، وناقص `business_id` و`customer_id`. الخطأ بيتبلع والمستخدم يشوف "تم" | `review_model.dart:51-62` | صحّح الـ payload، أو اعمل RPC `submit_review` |
| QA-H7 🧪 | **الشكاوى مش بتتحفظ:** `ticket_number` و`reason` و`details` مش أعمدة، وناقص `branch_id` و`business_id` و`category` و`description`. والتذكرة دايمًا `TK-501` | `order_service.dart:134-143` | صحّح الـ payload، والسيرفر يولّد رقم التذكرة |
| QA-H8 | **المواعيد المتاحة بتتحسب على الموبايل:** بيعدّ طلبات العميل بس، وبيتجاهل `branch_working_hours` (كل الأيام 09:00–22:00) و`branch_blocked_slots`. النتيجة overbooking وحجز في أيام الإجازة | `availability_service.dart:38-44`، `branch_model.dart:114-135` | RPC `get_available_slots` على السيرفر |
| QA-H9 🧪 | **العروض مش بتتطبّق خالص:** الكود بيقرأ `service_ids` وده مش موجود (الربط عن طريق `offer_categories`)، فالخصم دايمًا 0 | `offer_model.dart:59-60`، `pricing_service.dart:42-45` | اربط العرض بالـ categories، والخصم يتحسب على السيرفر |
| QA-H10 🧪 | **فرق التوقيت:** `scheduled_at` بيتبعت من غير timezone، فميعاد القاهرة يتسجّل كأنه UTC وصاحب المغسلة يشوفه متأخر 2–3 ساعات | `order_model.dart:190,199`، `format_helper.dart:31-35` | `.toUtc()` عند الكتابة و`.toLocal()` عند القراءة |
| QA-H11 | **الإلغاء أو إعادة الجدولة بيمسح تحديثات الموظفين:** `saveOrder` بيعمل upsert للصف كله من النسخة المحلية القديمة، ومفيش Realtime | `carzone_db_service.dart:503` | update للأعمدة المطلوبة بس + Realtime على `orders` |
| QA-H12 | **fallback لعميل وهمي `id = auth uid`:** كل الكتابات بعده بتترفض من الـ RLS في صمت | `auth_repo.dart:225-236` | امسح الـ fallback، واعرض خطأ للمستخدم |

### 🟡 Medium

| ID | المشكلة | المكان |
|---|---|---|
| QA-M1 | `fetchHomeData` بيفلتر الطلبات بـ `auth uid` بدل `customers.id`، فكارت الحجز النشط فاضي دايمًا | `carzone_db_service.dart:226` |
| QA-M2 | الإشعارات مابتتقراش من السيرفر خالص (مفيش select على `customer_notifications`) | — |
| QA-M3 | Race في الـ login: الـ listener و`verify()` الاتنين بيعملوا navigate، فـ profile-setup بيفتح مرتين | `session_service.dart:72-88`، `auth_controller.dart:226-245` |
| QA-M4 | مفضلة الزائر بتضيع، و`migrateGuestFavorites` بيلفّ على RxSet بيتغيّر وقت الـ loop | `carzone_db_service.dart:457` |
| QA-M5 | تعديل الاسم في البروفايل مش بيتحفظ على السيرفر | `profile_controller.dart:53-54` |
| QA-M6 | العميل الموقوف يقدر يرجّع `status='active'` بنفسه (الـ UPDATE policy) | migration `:105-109` |
| QA-M7 | ملاحظة الحجز (`note`) بتضيع، والـ timeline فاضي (`key` بدل `status`) | `order_model.dart:47` |
| QA-M8 | Crashes: `_db.branch(id)!` في reschedule و"احجز تاني"، و`confirming` بيفضل true عند أي خطأ غير `SlotTaken` | `order_service.dart:37,102`، `booking_controller.dart:251` |
| QA-M9 | Shimmer لا نهائي لو الفرع مش موجود، و`branch!` في الـ gallery | `wash_details_page.dart:32`، `gallery_viewer_page.dart:39` |
| QA-M10 | Workers `ever()` على lists دايمة من غير dispose (memory leak محتمل، لم يُتحقق) | `booking_details_controller.dart:46`، `wash_details_controller.dart:49`، `bookings_controller.dart:23` |
| QA-M11 | العربيات: بتتضاف محليًا قبل نجاح الحفظ ومن غير rollback، والحذف بيبلع الأخطاء | `cars_controller.dart:116-125`، `carzone_db_service.dart:567` |
| QA-M12 | `share-wash`: XSS من اسم وعنوان الفرع، والـ query بيطلب `photo_seed` اللي مش موجود، و`pathPrefix` في Android مش مطابق | `share-wash/index.ts:65-71,174-178` |
| QA-M13 | دالة الـ OTP بتسجّل الكود والرقم في الـ logs، وبترجّع 200 "simulated" لو الـ credentials ناقصة، ومفيش rate limit | `send-sms-whatsapp/index.ts:52-69,139` |
| QA-M14 | Migration `140100` مكسور: بيشاور على جداول مش موجودة (`user_roles`، `branch_staff`، `notifications`...)، والـ trigger هيكسر كل UPDATE على الـ orders لو اتطبّق | `20261015140100_*.sql` |
| QA-M15 ✅ | **`branch_shares` view بيكشف `user_id` للزوار**، ومعاه `GRANT INSERT TO anon` بيعدّي الـ RLS. اتأكدت منه live: 4 UUIDs ظاهرة | migration `:260-262` |
| QA-M16 | الـ services محدودة بـ 25 لكل التطبيق، فأغلب الفروع بتظهر من غير سعر، والتقييم المحلي بيغطي على `branches.rating` | `carzone_db_service.dart:190`، `discovery_service.dart:66` |

### ⚪ Low

- الـ token محفوظ كمان في SharedPreferences عادي (`session_service.dart:155`).
- مفتاح Google Maps مكتوب في الكود في 4 أماكن. اقفله بقيود (bundle id و SHA-1).
- `sync_customer_profile` قابل للتنفيذ من `anon` (الـ grant الافتراضي لـ PUBLIC ماتشالش). محمي بشرط `auth.uid()`، بس الأفضل `REVOKE`.
- Dio و`ApiService` dead code.
- الـ HTTP logger في debug بيطبع الـ OTP والـ refresh tokens.
- كل الـ order events بتاخد `createdAt`، وحدث الـ reschedule مابيتسجّلش (نفس الـ id).
- `counts[r.stars-1]` يكراش لو التقييم خارج 1–5 (`wash_details_controller.dart:76`).
- اسم `insideFreeWindow` عكس معناه.
- الـ release build موقّع بـ debug key، و`applicationId = com.example.carzone`.

---

## 5. التستات اللي اتضافت

### Flutter (`test/qa/`): offline، مابتلمسش السيرفر

| الملف | التستات | النتيجة |
|---|---|---|
| `availability_service_test.dart` | 7: الـ slots، الإغلاق، الـ capacity، الـ lead time، إعادة الجدولة | ✅ 7/7 |
| `pricing_service_test.dart` | 7: المجموع، الخصم %، الخصم الثابت، أفضل عرض، العروض المنتهية | ✅ 7/7 |
| `schema_contract_test.dart` | 9: كل payload بيتكتب لـ Supabase مقارَن بـ `database.types.ts` | ✅ 7/9 · ❌ reviews، complaints |
| `known_bugs_test.dart` | 4: regression للـ bugs | ❌ 4/4 (متوقَّع، H9 و H10 و C4 و H7) |

**الإجمالي: 27 تست، 21 نجحوا. الـ 6 اللي فشلوا هم الـ bugs المؤكدة، وهيبقوا أخضر لما تتصلّح.**

### Supabase (`qa/`): Node + k6

| الملف | الوظيفة | الحالة |
|---|---|---|
| `qa/rls/anon_access.test.mjs` | 40 فحص: صلاحيات الزائر، سلامة الكتالوج، تطابق التقييمات | ✅ 39/40 (الفاشل: M15) |
| `qa/rls/customer_rls.test.mjs` | 17 تست للعميل المسجّل: عزل البيانات، cross-customer، tampering، round-trips | ⏳ **محتاج تشغّله أنت** (تحت) |
| `qa/load/k6_app_journeys.js` | profiles: `smoke` / `light` / `stress` | ✅ smoke + light |
| `qa/load/autocannon_endpoints.js` | benchmark لكل endpoint | ✅ |
| `qa/profiling/app_data_layer_server.js` | harness لـ Clinic.js | ✅ doctor |

**أوامر التشغيل** (من مجلد `qa/` بعد `npm install`):

```bash
npm run test:anon
```
```bash
npm run k6:light
```
```bash
npm run bench
```
```bash
npm run clinic:doctor
```
```bash
flutter test test/qa
```

---

## 6. المطلوب دلوقتي بالترتيب

أول خطوة هي deploy مرحلة الأمان الأولى، لأن التصليحات مالهاش أي تأثير لحد ما توصل للسيرفر. بعدها نكمّل الأمان، وبعدين الحجز، وبعدين الجودة.

### 1. Deploy مرحلة الأمان الأولى (الترتيب مهم)

- [ ] في SQL Editor: اتأكد إن `staff.user_id` و `admin_users.user_id` بيشاوروا على `auth.users`، وراجع تعريف `next_order_number()`. الـ migration مبني من الـ types مش من الـ SQL الحقيقي
- [ ] طبّق `supabase/migrations/20261019120000_security_phase1.sql`
- [ ] حط `SEND_SMS_HOOK_SECRET` في secrets الـ function (من Auth ← Hooks). من غيره الـ function هترفض كل الطلبات
- [ ] Deploy لـ `send-sms-whatsapp`
- [ ] طلّع نسخة التطبيق الجديدة بعد الـ migration على طول، لأن النسخ القديمة هيفشل معاها الحجز
- [ ] اتأكد من اللي اتطبّق: `npm run test:rls` بحسابين test، و `flutter test test/edge_function_test.dart`
- [ ] رجّع `pubspec.lock` (اتغيّر من التستات وبينزّل 38 package)، واعمل push لفرع `Work`

### 2. نكمّل الأمان

- [ ] H5: وقف تخزين الـ JWT في `push_devices`، وامسح الصفوف الموجودة
- [ ] M15: `branch_shares` يبقى `security_invoker` من غير `user_id`، وشيل الـ INSERT من anon
- [ ] M12: XSS في `share-wash`
- [ ] التحقق من الرقم بالـ OTP لمستخدمي Google (باقي C1)
- [ ] M13: rate limit لطلبات الـ OTP
- [ ] M14: امسح أو صلّح migration `20261015140100` المكسور قبل ما حد يطبّقه

### 3. الحجز يشتغل صح

- [ ] H8: RPC `get_available_slots`، والشاشة تعرض المواعيد من السيرفر
- [ ] H9: الشاشة تعرض السعر والخصم زي السيرفر بالظبط
- [ ] H6 و H7: RPCs للتقييم والشكوى
- [ ] H10: تصحيح الحجوزات القديمة اللي اتسجّلت بتوقيت غلط
- [ ] M1 و M2: الحجز النشط في الـ Home، والإشعارات من السيرفر
- [ ] M7: ملاحظة الحجز في `order_notes`

### 4. الجودة والأداء

- [ ] H11: Realtime على `orders` و `customer_notifications`
- [ ] Index على `reviews(branch_id, created_at)`، وتحديد الأعمدة، وRPC للـ Home، وشيل التحميل المكرر
- [ ] M3 و M4 و M5 و M9 و M10 و M11 و M16
- [ ] الـ Low الباقيين (8)

### 5. فجوات التستات

| المهمة | ليه ماتعملتش | المطلوب |
|---|---|---|
| Stress test (200 VU) | اخترت light بس | `npm run k6:stress` على staging |
| Supabase Advisors | المشروع على حساب غير اللي متوصل بالـ MCP | وصّل الحساب الصح أو شغّلها من الـ Dashboard |
| فحص الكتابة كـ anon | الـ auto-mode رفض الكتابة على production | على staging أو local Supabase |
| E2E على المحاكي | خارج نطاق المرحلة دي | `integration_test` لرحلة الحجز |
| تستات بتكتب على production | `seed_supabase_test` و `supabase_phone_auth_test` | انقلهم لـ staging أو احذفهم |
| تستات `share-wash` | ماتعملتش في المرحلة دي | تبقى مع تصليح M12 |

**معيار النجاح:** `flutter test test/qa` و `npm run test:anon` و `npm run test:db` و `npm run test:rls` كلهم أخضر على السيرفر الـ live.
