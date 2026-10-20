# إشعارات تطبيق العميل (CarZone)

كل الإشعارات اللي المفروض تطبيق العميل يستقبلها من **المغسلة** أو **الأدمن** أو **النظام**، ومعاها حالة كل واحد النهارده (موجود ولا ناقص).

> اتعمل بمراجعة كود التطبيق وقاعدة البيانات الحقيقية (مشروع `tbcmgdwzarfdgzzmmele`) يوم 2026-10-20.

---

## 1. الإشعار بيوصل للعميل إزاي

في طريقين، والمفروض كل إشعار يمشي في الاتنين:

| الطريق | بيتخزن فين | العميل بيشوفه فين | الحالة |
|---|---|---|---|
| **قائمة الإشعارات جوه التطبيق** | جدول `customer_notifications` | صفحة الإشعارات + عداد غير المقروء في الرئيسية | ✅ شغال |
| **Push على الموبايل** (FCM) | التوكن في جدول `push_devices` | إشعار على شاشة الموبايل حتى والتطبيق مقفول | ⚠️ التطبيق جاهز يستقبل، **بس السيرفر مش بيبعت** |

> **⚠️ أهم ملاحظة:** مفيش حاجة على السيرفر بتبعت Push دلوقتي. مفيش trigger ولا Edge Function ولا Database Webhook على `customer_notifications` بتكلم FCM. يعني الإشعارات بتظهر في صفحة الإشعارات بس، **ومش بتظهر على شاشة الموبايل**. المطلوب: Edge Function (مثلًا `send-push`) تشتغل مع كل صف جديد في `customer_notifications`، تجيب توكنات العميل من `push_devices` (بالـ `user_id` بتاع العميل) وتبعت لـ FCM بنفس المحتوى (شوف قسم 2).

---

## 2. شكل البيانات (العقد بين السيرفر والتطبيق)

### صف في `customer_notifications`

| العمود | النوع | ملاحظات |
|---|---|---|
| `id` | text | فريد. للطلبات بنستخدم `cn_<order_id>_<type>` عشان الإشعار ما يتكررش |
| `customer_id` | text | `customers.id` |
| `type` | text | لازم يكون من الأنواع المسموحة في `customer_notifications_type_check` (قسم 4) |
| `title` | jsonb | `{"ar": "...", "en": "..."}`، الاتنين إجباريين |
| `body` | jsonb | `{"ar": "...", "en": "..."}` |
| `href` | text | مثال `/booking_details?id=<order_id>`، التطبيق مش بيقراه حاليًا |
| `order_id` | text | اختياري، ولو موجود الضغط بيفتح الطلب |
| `read` | boolean | `false` في الأول |
| `created_at` | timestamptz | |

### الـ `data` في رسالة FCM (Push)

التطبيق ([notification_service.dart](../lib/core/services/notification_service.dart)) بيقرا المفاتيح دي:

```json
{
  "id": "cn_<order_id>_confirmed",
  "type": "confirmed",
  "order_id": "<order_id>",
  "title_ar": "تم تأكيد الحجز",
  "title_en": "Booking Confirmed",
  "body_ar": "تم تأكيد حجزك رقم #CZ-00123 بنجاح",
  "body_en": "Your booking #CZ-00123 is confirmed"
}
```

- لازم `id` يبقى **نفس** id الصف في `customer_notifications`، عشان التطبيق ما يعرضش الإشعار مرتين.
- ابعت كمان `notification.title` و `notification.body` بلغة العميل (`customers.locale`) عشان iOS يعرض الإشعار والتطبيق مقفول.

### الضغط على الإشعار بيفتح إيه

| الحالة | الصفحة |
|---|---|
| فيه `order_id` والنوع `review_reminder` | صفحة تقييم الطلب `/booking_review` |
| فيه `order_id` (أي نوع تاني) | تفاصيل الحجز `/booking` |
| النوع `offer` من غير `order_id` | صفحة العروض `/offers` |
| غير كده | صفحة الإشعارات `/notifications` |

---

## 3. كل أنواع الإشعارات

**المصدر:** 🏪 المغسلة (تطبيق/لوحة المغسلة) · 🛡️ الأدمن (لوحة التحكم) · ⚙️ النظام (تلقائي)

**الحالة:** ✅ شغال · 🟡 النوع موجود بس مفيش حاجة بتبعته · ❌ ناقص (محتاج نوع جديد + كود يبعته)

### أ) دورة حياة الحجز

| # | `type` | المصدر | بيتبعت إمتى | العنوان (ع / En) | النص (ع) | الضغط بيفتح | الحالة |
|---|---|---|---|---|---|---|---|
| 1 | `created` | ⚙️ | طلب جديد اتعمل (`INSERT` على `orders`) | تم إنشاء الحجز بنجاح / Booking Created | طلبك رقم #CZ-00123 قيد المراجعة في الفرع | تفاصيل الحجز | ✅ trigger |
| 2 | `confirmed` | 🏪 | المغسلة أكدت الحجز (`status → confirmed`) | تم تأكيد الحجز / Booking Confirmed | تم تأكيد حجزك رقم #CZ-00123 بنجاح | تفاصيل الحجز | ✅ trigger |
| 3 | `waiting` | 🏪 | العربية وصلت الفرع (`status → waiting`) | في قائمة الانتظار / In Queue | وصلت سيارتك للفرع وجارٍ تجهيز مسار الغسيل | تفاصيل الحجز | ✅ trigger |
| 4 | `in_service` | 🏪 | بدأ الغسيل (`status → in_service`) | بدء الخدمة / Washing In Progress | بدأ العمل على سيارتك الآن | تفاصيل الحجز | ✅ trigger |
| 5 | `completed` | 🏪 | الخدمة خلصت (`status → completed`) | سيارتك جاهزة! / Vehicle Ready! | اكتملت الخدمة! سيارتك جاهزة للاستلام | تفاصيل الحجز | ✅ trigger |
| 6 | `cancelled` | 🏪 / 🛡️ / ⚙️ | الحجز اتلغى (`status → cancelled`) | تم إلغاء الحجز / Booking Cancelled | تم إلغاء الحجز رقم #CZ-00123 | تفاصيل الحجز | ✅ trigger (محتاج تحسين ⬇️) |
| 7 | `no_show` | 🏪 | المغسلة سجلت إن العميل ما جاش (`status → no_show`) | لم يتم الحضور / Missed Booking | فاتك موعد حجزك رقم #CZ-00123. احجز موعد جديد بسهولة | تفاصيل الحجز | ❌ الحالة موجودة في `order_status` بس الـ trigger مش بيبعت حاجة، والنوع مش مسموح في الـ constraint |
| 8 | `rescheduled` | 🏪 / 🛡️ | المغسلة أو الأدمن غيروا ميعاد الحجز (`scheduled_at` اتغير ومش العميل اللي غيره) | تم تغيير موعد الحجز / Booking Rescheduled | تم نقل حجزك رقم #CZ-00123 إلى {اليوم} الساعة {الوقت} | تفاصيل الحجز | ❌ نوع جديد |
| 9 | `payment_refunded` | 🏪 / 🛡️ | تم رد المبلغ (`payment_status → refunded`) | تم استرداد المبلغ / Payment Refunded | تم رد {المبلغ} ج.م للطلب رقم #CZ-00123 | تفاصيل الحجز | ❌ نوع جديد |

**تحسين مطلوب لـ `cancelled` (6):** النص الحالي واحد في كل الحالات. المفروض يختلف حسب `cancelled_by_type`، ويظهر `cancel_reason` لو المغسلة أو الأدمن هما اللي لغوا:
- `staff` (المغسلة): «اعتذرت المغسلة عن حجزك رقم #CZ-00123. السبب: {cancel_reason}»
- `admin`: «تم إلغاء حجزك رقم #CZ-00123 من إدارة CarZone. السبب: {cancel_reason}»
- `customer`: «تم إلغاء حجزك رقم #CZ-00123 بناءً على طلبك». ممكن ما يتبعتش Push هنا، لأن العميل هو اللي عمل الإلغاء.
- `system`: «تم إلغاء الحجز رقم #CZ-00123 تلقائيًا»، مثلًا لو المغسلة ما أكدتش في الوقت.

### ب) التذكيرات (مجدولة من النظام)

| # | `type` | المصدر | بيتبعت إمتى | العنوان (ع / En) | النص (ع) | الضغط بيفتح | الحالة |
|---|---|---|---|---|---|---|---|
| 10 | `booking_reminder` | ⚙️ | قبل الميعاد بساعة (للحجوزات `confirmed`) | تذكير بموعدك / Booking Reminder | موعد غسيل سيارتك في {اسم الفرع} الساعة {الوقت}. لا تتأخر! | تفاصيل الحجز | 🟡 محتاج `pg_cron` |
| 11 | `review_reminder` | ⚙️ | بعد ساعتين من `completed` لو العميل ما قيّمش | قيّم تجربتك / Rate your wash | كيف كانت تجربتك في {اسم الفرع}؟ تقييمك يساعد غيرك | صفحة التقييم | 🟡 محتاج `pg_cron` (فيه صف واحد قديم بس) |

> الأفضل يتعملوا بـ `pg_cron` كل 5 دقايق، والـ `id` الثابت (`cn_<order_id>_booking_reminder`) يمنع التكرار.

### ج) من المغسلة (مش مرتبطة بحالة الطلب)

| # | `type` | المصدر | بيتبعت إمتى | العنوان (ع / En) | النص (ع) | الضغط بيفتح | الحالة |
|---|---|---|---|---|---|---|---|
| 12 | `review_reply` | 🏪 | المغسلة ردت على تقييم العميل (`reviews.reply` اتملى) | رد على تقييمك / Reply to your review | ردت {اسم الفرع} على تقييمك: «{أول 80 حرف من الرد}» | تفاصيل الحجز (`order_id`) | ❌ نوع جديد |
| 13 | `offer` | 🏪 | المغسلة نشرت عرض (`offers.scope = wash` و `status → active`) للعملاء اللي مفضّلين فروعها أو حجزوا عندها قبل كده | عرض جديد من {اسم المغسلة} / New offer | خصم {القيمة} على غسيل سيارتك حتى {تاريخ الانتهاء} | صفحة العروض | 🟡 النوع موجود، مفيش حاجة بتبعته |

### د) من الأدمن (CarZone)

| # | `type` | المصدر | بيتبعت إمتى | العنوان (ع / En) | النص (ع) | الضغط بيفتح | الحالة |
|---|---|---|---|---|---|---|---|
| 14 | `offer` | 🛡️ | عرض عام اتنشر (`offers.scope = platform` و `status → active`) لكل العملاء | عرض خاص من CarZone / CarZone Offer | {عنوان العرض}: {وصف العرض} | صفحة العروض | 🟡 النوع موجود، مفيش حاجة بتبعته |
| 15 | `complaint_update` | 🛡️ | حالة شكوى العميل اتغيرت (`complaints.status` → `in_review` / `waiting` / `resolved` / `closed`) | تحديث على شكواك / Complaint Update | شكواك رقم {ticket}: {الحالة}. ولو اتحلت: {resolution} | تفاصيل الحجز لو فيه `order_id`، غير كده الإشعارات | 🟡 النوع موجود، مفيش trigger |
| 16 | `account_status` | 🛡️ | الأدمن وقف الحساب أو رجّعه (`customers.status` اتغير) | تحديث على حسابك / Account Update | تم إيقاف حسابك مؤقتًا. السبب: {status_reason}. للمساعدة تواصل معنا | الإشعارات | ❌ نوع جديد |
| 17 | `review_hidden` | 🛡️ | الأدمن خبّى تقييم العميل (`reviews.status → hidden`) | تم إخفاء تقييمك / Review Hidden | تم إخفاء تقييمك لـ {اسم الفرع} لمخالفته الإرشادات. السبب: {hidden_reason} | الإشعارات | ❌ نوع جديد (اختياري) |
| 18 | `system` | 🛡️ | رسالة عامة يبعتها الأدمن يدويًا (صيانة، تحديث للتطبيق، إعلان) | يكتبه الأدمن | يكتبه الأدمن | الإشعارات | 🟡 النوع موجود، مفيش شاشة في لوحة الأدمن تبعته |

### هـ) أنواع قديمة (ما تتبعتش تاني)

موجودة في الـ constraint والتطبيق بيعرضها، بس المفروض ما نبعتهاش في أي كود جديد:

| `type` القديم | استخدم بداله |
|---|---|
| `booking_confirmed` | `confirmed` |
| `booking_cancelled` | `cancelled` |
| `order_ready` | `completed` |
| `reminder` | `booking_reminder` |

---

## 4. المطلوب عشان الأنواع الجديدة تشتغل

1. **قاعدة البيانات:** ضيف الأنواع الجديدة للـ constraint `customer_notifications_type_check`:
   `no_show`, `rescheduled`, `payment_refunded`, `review_reply`, `account_status`, `review_hidden`
2. **Triggers:**
   - كمّل `handle_order_status_notification` بحالة `no_show`، ونص الإلغاء حسب `cancelled_by_type`، وتغيير `scheduled_at` (`rescheduled`)، و `payment_status → refunded`.
   - trigger على `reviews` (لما `reply` يتملى، ولما `status → hidden`).
   - trigger على `complaints` (لما `status` يتغير).
   - trigger على `customers` (لما `status` يتغير).
   - trigger على `offers` (لما `status → active`)، بيبعت للفئة المستهدفة حسب `scope`.
3. **Cron:** `booking_reminder` و `review_reminder` بـ `pg_cron`.
4. **Push:** Edge Function `send-push` تتنده مع كل `INSERT` على `customer_notifications` (Database Webhook) وتبعت FCM بالشكل اللي في قسم 2.
5. **التطبيق:** أيقونات للأنواع الجديدة في [notification_tile.dart](../lib/features/notifications/presentaion/widgets/notification_tile.dart). من غيرها هتظهر بالأيقونة العامة. التوجيه عند الضغط شغال من غير أي تعديل لأنه بيعتمد على `order_id`.

---

## 5. ملخص سريع

| الحالة | العدد | الأنواع |
|---|---|---|
| ✅ شغال (قائمة جوه التطبيق بس، من غير Push) | 6 | `created`, `confirmed`, `waiting`, `in_service`, `completed`, `cancelled` |
| 🟡 النوع موجود ومفيش حاجة بتبعته | 5 | `booking_reminder`, `review_reminder`, `offer`, `complaint_update`, `system` |
| ❌ ناقص | 6 | `no_show`, `rescheduled`, `payment_refunded`, `review_reply`, `account_status`, `review_hidden` |
| 🔴 Push على الموبايل | — | مش متعمل على السيرفر خالص |
