# إشعارات تطبيق المالك — المطلوب من الويب ديفلوبر

- التطبيق: Wash Up Owner، على TestFlight، النسخة 1.0.0 (1)
- Bundle ID: `com.alnagar.washup.owner` على iOS وAndroid
- تاريخ الملف: 1 نوفمبر 2026

---

## الخلاصة

إشعارات المغسلة لازم توصل موبايل المالك والتطبيق مقفول أو الموبايل مقفول.

مطلوب تعديلين في سيرفر لوحة المغسلة:

1. `POST /vendor/push/register` يحفظ نوع الجهاز اللي التطبيق بيبعته.
2. إرسال الإشعارات يبعت لأجهزة `ios` و`android` رسالة فيها `notification`.

**الويب مش هيتغير:** أجهزة `web` تفضل على رسائل `data` بس زي دلوقتي.

---

## الوضع الحالي

| الموضوع | اللي لقيناه |
|---|---|
| تسجيل الجهاز | التطبيق بيبعت `{ token, appVersion: "1.0.0", platform: "ios" }` |
| اللي بيتحفظ | الصف اتحفظ في `push_devices` بـ `app = 'partner'` و`app_version = '1.0.0'` لكن `platform = 'web'` |
| شكل الرسالة | حسب تعليق `push-sw.js`: رسالة `data` بس فيها `id, type, title, body, href, app` |
| النتيجة على iPhone | iOS مش بيعرض رسالة `data` بس والتطبيق مقفول |
| Firebase | المشروع `chatapp-188`، والتطبيق متسجل على iOS وAndroid |
| APNs | المفتاح `VFQ5R97ZH7` مرفوع في خانتي Development وProduction، والفريق `CNLLPVC2WT` |

مفيش حاجة مطلوبة منك في Apple أو Firebase. كمان `notify_wash` و`panel_push` يفضلوا زي ما هم، والتعديل في السيرفر اللي بيستقبل `panel_push_vendor_url`.

---

## التعديل 1: حفظ نوع الجهاز

**المكان:** `POST /api/v1/vendor/push/register`

- اقبل حقل `platform` بالقيم `ios` أو `android` أو `web`.
- لو الحقل مش موجود، خليه `web`، عشان اللوحة تفضل شغالة من غير تعديل.
- لو التوكن موجود قبل كده، حدّث `platform` و`app_version` و`last_seen_at`. عمود `token` عليه `UNIQUE`.

**الصفوف الموجودة:** التطبيق بيسجل جهازه عند كل فتح بعد الدخول، فالصف هيتصلح لوحده بعد التعديل. ومفيش صف محتاج تصليح يدوي.

---

## التعديل 2: رسالة الموبايل

**المكان:** الكود اللي بيبعت الإشعار لتوكنات `app = 'partner'`.

قسّم التوكنات حسب `platform`:

- `web`: نفس الرسالة الحالية من غير تغيير.
- `ios` و`android`: ابعت الرسالة دي بـ FCM HTTP v1، لكل توكن.

```json
{
  "message": {
    "token": "<FCM_TOKEN>",
    "notification": {
      "title": "<TITLE>",
      "body": "<BODY>"
    },
    "data": {
      "id": "<VENDOR_NOTIFICATION_ID>",
      "type": "new_booking",
      "title": "<TITLE>",
      "body": "<BODY>",
      "href": "/orders/<ORDER_ID>",
      "app": "partner"
    },
    "apns": {
      "headers": {
        "apns-push-type": "alert",
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    },
    "android": {
      "priority": "high",
      "notification": {
        "channel_id": "washup_owner_orders",
        "sound": "default"
      }
    }
  }
}
```

### لازم تلتزم بالآتي

- كل قيم `data` تكون نصوص، زي ما FCM بيطلب.
- `data.id` هو نفس `id` الإشعار. التطبيق بيستخدمه عشان ما يعرضش الإشعار مرتين.
- `data.href` يفضل بنفس الشكل الحالي. لو بدأ بـ `/orders/<id>` التطبيق بيفتح الطلب، وغير كده بيفتح صفحة الإشعارات.
- العنوان والنص بالعربي حاليًا. `notify_wash` بتخزن نفس النص في `ar` و`en`، فاستخدم `ar`.
- لو FCM رجّع `UNREGISTERED`، امسح صف التوكن من `push_devices`.
- فشل توكن واحد ما يوقفش الإرسال لباقي التوكنات.
- ما تبعتش للموبايل نسختين: رسالة `data` القديمة ورسالة `notification` الجديدة. كل توكن موبايل ياخد الرسالة الجديدة بس.

### تأكيد مطلوب

مين بيستلم إشعار المغسلة حاليًا: مالك المغسلة بس، ولا مدير الفرع والموظف كمان؟ التطبيق بيسجل الجهاز باسم المستخدم اللي داخل، فنفس قاعدة الاستلام تنطبق على الموبايل.

---

## شكل التطبيق بعد التعديل

مش مطلوب منك تعديل في التطبيق. للعلم، التطبيق بيعمل الآتي:

| الحالة | iPhone | Android |
|---|---|---|
| التطبيق مقفول أو في الخلفية | النظام يعرض الإشعار | النظام يعرض الإشعار |
| التطبيق مفتوح | التطبيق يعرضه مرة واحدة ويحدّث البيانات | نفس الكلام |
| الضغط على الإشعار | يفتح الطلب من `href` | يفتح الطلب من `href` |
| تسجيل الخروج | يبعت `POST /vendor/push/unregister` | نفس الكلام |

---

## اختبار التسليم

جرّب على موبايل حقيقي، مش محاكي، وعلى مغسلة تجريبية.

1. نزّل Wash Up Owner من TestFlight، سجل دخول بحساب مالك، ووافق على الإشعارات.
2. شغّل الاستعلام ده. لازم آخر صف يرجع `ios` أو `android`، مش `web`:

   ```sql
   select platform, app_version, last_seen_at
   from push_devices
   where app = 'partner'
   order by last_seen_at desc
   limit 5;
   ```

3. اقفل التطبيق تمامًا، واعمل حجز من تطبيق العميل على نفس المغسلة. لازم الإشعار يظهر خلال ثوانٍ.
4. كرر نفس الخطوة والموبايل مقفول.
5. اضغط على الإشعار. لازم يفتح تفاصيل الطلب الصح.
6. افتح التطبيق واعمل حجز تاني. لازم الإشعار يظهر مرة واحدة بس.
7. افتح لوحة المغسلة. لازم إشعار الويب يفضل شغال زي الأول.
8. سجل خروج من التطبيق، واعمل حجز تالت. لازم مفيش إشعار يوصل الموبايل، وصف التوكن يتمسح.

---

## طلب أمان منفصل

صفحة الدخول في لوحة المغسلة فيها قيم افتراضية مكتوبة في الكود للموبايل وكلمة المرور. الكود ده بيوصل لأي حد يفتح الموقع.

- شيل القيم الافتراضية من فورم الدخول.
- اتأكد إن مفيش حساب حقيقي بيستخدم كلمة المرور دي.
- غيّرها في أي حساب تجريبي شغال على production.

---

## برومبت جاهز

لو بتستخدم مساعد AI في الكود، انسخ الجزء ده:

```text
Update the vendor dashboard's push notifications so they reach the Wash Up Owner
iOS and Android app while it is closed.

1. POST /api/v1/vendor/push/register: accept an optional `platform` of ios,
   android or web, defaulting to web. On an existing token, update platform,
   app_version and last_seen_at. The token column is unique.

2. In the code that sends vendor notifications to push_devices rows with
   app = 'partner', split tokens by platform:
   - web: keep the current data-only message.
   - ios and android: send one FCM HTTP v1 message per token with:
     notification { title, body };
     data { id, type, title, body, href, app: "partner" }, all strings;
     apns.headers { apns-push-type: alert, apns-priority: "10" };
     apns.payload.aps { sound: default };
     android { priority: high, notification { channel_id: washup_owner_orders,
     sound: default } }.
   Use the Arabic title and body. Keep href unchanged.

3. Delete a token when FCM answers UNREGISTERED. One failed token must not stop
   the others. A mobile token must get only the new message, not the old
   data-only one as well.

Do not change the web push behavior, notify_wash or panel_push.
```

---

## المطلوب منك كرد

1. موعد تنفيذ التعديلين.
2. مين بيستلم إشعارات المغسلة.
3. نتيجة خطوات الاختبار، أو أي خطوة فشلت.
