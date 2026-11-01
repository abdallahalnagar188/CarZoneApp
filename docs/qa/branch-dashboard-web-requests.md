# تشغيل الفرع من لوحة المغسلة — المطلوب من الويب ديفلوبر

- اللوحة: `washup-vendor.vercel.app`
- تاريخ الملف: 1 نوفمبر 2026
- الملفات المرتبطة: `dashboards-issues.md` و`owner-app-push-web-request.md`

---

## القرار

موظف الاستقبال هيشتغل من **لوحة المغسلة** على تابلت أو كمبيوتر في الفرع. مفيش تطبيق تابلت حاليًا، ومفيش مسح QR.

موظف الاستقبال هيأكد الحجز ويسجل وصول العربية بنفسه، من قائمة حجوزات اليوم أو بالبحث باللوحة.

**الأولوية:** 🔴 لازم قبل تشغيل الفروع · 🟠 مهم في أول أسبوع · 🟡 تحسين

---

## الوضع الحالي

| الخطوة | الوضع |
|---|---|
| تأكيد الحجز وتسجيل الوصول | موجود |
| بدء الخدمة وإكمالها والتحصيل | موجود |
| فتح الوردية ونقدية البداية | **مفيش شاشة ولا عملية ظاهرة في كود اللوحة** |
| قفل الوردية وعد النقدية | **مفيش شاشة ولا عملية ظاهرة في كود اللوحة** |
| مراجعة الوردية | الشاشة موجودة، لكن مفيش ورديات تتراجع |
| إغلاق اليوم | موجود، ولسه ما اتستخدمش |

على production وقت الفحص: `staff_shifts` فيه 0 صف، و`day_closings` فيه 0 صف، وكل المدفوعات الأربعة سجلها المالك.

اللوحة كمان بتقول إن الموظف يدخل «تطبيق الموظفين». جربت مسارات `/api/v1/employee/*` على نفس الدومين ورجعت 404. **لو التطبيق أو الـ API موجودين في مكان تاني، قولّي قبل ما تبدأ.**

---

## 🔴 1. دخول الموظف للوحة

الموظف ومدير الفرع يدخلوا اللوحة بحساباتهم، بالموبايل وكلمة المرور.

| الصفحة | المالك | مدير الفرع | موظف الاستقبال |
|---|---|---|---|
| التشغيل المباشر، الحجوزات، الطلبات | ✅ | ✅ فرعه | ✅ فرعه |
| الجدول والسعة | ✅ | ✅ | عرض فقط |
| ورديتي | اختياري | ✅ | ✅ |
| مراجعة الورديات وإغلاق اليوم | ✅ | حسب `closeShift` | ❌ |
| الخدمات والعروض | ✅ | حسب الصلاحية | عرض فقط |
| الموظفون | ✅ | حسب `manageStaff` | ❌ |
| المالية والتقارير والعملاء والتقييمات والتدقيق والإعدادات | ✅ | حسب ما تحدده | ❌ |

### المطلوب

- القائمة تعرض الصفحات المسموحة بس.
- السيرفر يرفض العملية الممنوعة، مش الواجهة بس.
- الموظف يشوف فرعه بس.
- رئيسية الموظف تعرض شغل الوردية بدل أرقام المالية.
- عمولة المنصة وصافي المغسلة ما يظهروش للموظف.
- غيّر كل نصوص «تطبيق الموظفين» لـ «لوحة المغسلة».
- بعد إضافة موظف، اعرض رابط الدخول مع كلمة المرور المؤقتة.
- أول دخول بكلمة مؤقتة يطلب تغييرها.

---

## 🔴 2. فتح الوردية

**مكانها:** زر واضح أول ما الموظف يدخل، وصفحة جديدة «ورديتي».

- الموظف يدخل نقدية البداية الموجودة في الصندوق.
- السيرفر ينشئ صف في `staff_shifts` بالموظف والفرع و`opening_cash` و`actual_start` و`review_status = 'open'`.
- الموظف يكون له وردية مفتوحة واحدة بس.
- ممكن أكتر من وردية مفتوحة في نفس الفرع.
- تتسجل في سجل التدقيق باسم مقترح `shift.open`.

### العمليات المقترحة

- `GET /vendor/shifts/current`
- `POST /vendor/shifts/open` بـ `{ openingCash }`
- `POST /vendor/shifts/current/submit` بـ `{ actualCash, differenceReason }`

---

## 🔴 3. ربط التحصيل بالوردية

- **بدون وردية مفتوحة:** الموظف والمدير ما يقدروش يحصّلوا، وتظهر رسالة «افتح ورديتك الأول».
- **المالك:** يقدر يحصّل من غير وردية، لكن العملية تتعلم إنها خارج الوردية.
- ضيف `shift_id` لجدول `payments`، أو أي طريقة تربط كل دفعة بوردية واحدة بشكل مؤكد.
- ما تعتمدش على وقت التحصيل بس، لأن الورديات ممكن تتداخل.

---

## 🔴 4. قفل الوردية

### الخطوات

1. الموظف يضغط «قفل الوردية».
2. لو عنده طلبات شغالة أو غير محصّلة، تظهر له قبل القفل.
3. يعد النقدية ويدخل المبلغ الفعلي، **قبل** ما يشوف المبلغ المتوقع.
4. السيرفر يحسب:
   - `expected_cash` = نقدية البداية + النقدي المحصّل في الوردية − النقدي المسترد في الوردية
   - `difference` = `actual_cash` − `expected_cash`
5. لو فيه فرق، سبب الفرق يبقى مطلوب.
6. الوردية تبقى `submitted`، وتظهر في صفحة المراجعة.

### تفاصيل

- احفظ `cash_payments` و`card_payments` و`orders_completed` و`actual_end`.
- لو فيه فرق، ابعت إشعار `cash_difference` الموجود بالفعل.
- سجل `shift.submit` في التدقيق.
- بعد التسليم، الموظف ما يعدلش الوردية.

---

## 🔴 5. إغلاق اليوم

- ما ينفعش إغلاق اليوم وفي وردية مفتوحة في الفرع.
- لو موظف نسي يقفل، المالك أو المدير يقفل بالنيابة عنه بسبب، ويتسجل ده في التدقيق.
- الوردية المفتوحة أكتر من 16 ساعة تظهر في «يحتاج انتباهك».

---

## 🔴 6. تنبيه الحجز الجديد

ده مهم لأن الحجز غير المؤكد بيتلغي عند بداية موعده.

- صوت واضح عند وصول حجز جديد.
- المتصفح بيمنع الصوت قبل أي ضغطة، فأظهر زر «تفعيل الصوت» عند بداية الوردية.
- التنبيه يفضل ظاهر لحد ما الحجز يتأكد أو يترفض.
- عدد الحجوزات المنتظرة ظاهر في عنوان الصفحة والقائمة.
- لو النت قطع، تظهر رسالة واضحة، وما يتحفظش أي تحصيل وهميًا.

---

## 🔴 7. مشاكل بتوقف الفرع

من `dashboards-issues.md`، ولازم تتصلح قبل التشغيل:

- #1 الخصم بيمسح العلامة العشرية.
- #2 بدء الخدمة لو مفيش موظفين.
- #3 المواعيد الفايتة وبعد القفل في الحجز الهاتفي.
- #6 الحجز الهاتفي بيربط عربية غلط.
- #7 معاملة معلقة لطلب ما اتنفذش.
- #8 الطلب الملغي مكتوب «بانتظار الدفع».
- #10 طلبات «تم الوصول» المفتوحة للأبد.

---

## 🟠 8. اللوحة على التابلت

- تشتغل على تابلت بالعرض، من غير سكرول أفقي للصفحة.
- أقل مساحة للزر 44 بكسل.
- القائمة الجانبية تتطوي.
- الجداول تبقى كروت في الشاشات الضيقة.
- حقول المبالغ تفتح لوحة أرقام.
- البحث باللوحة أو الموبايل ظاهر في التشغيل المباشر.
- لوحة التشغيل المباشر تبان كاملة من غير تكبير أو تصغير.

---

## 🟡 9. بعد التشغيل

- إيصال مطبوع أو مشاركة الإيصال.
- ملخص الوردية للطباعة.
- ملخص يومي للمالك على التطبيق.

---

## اختبار التسليم

جرّب بحساب موظف على مغسلة تجريبية:

1. الموظف يدخل اللوحة، ويشوف الصفحات المسموحة بس.
2. يحاول يفتح رابط المالية مباشرة، فالسيرفر يرفض.
3. يحاول يحصّل من غير وردية، فيظهر المنع.
4. يفتح وردية بـ 500 ج.م.
5. يعمل طلب حضور مباشر ويكمله ويحصّل 100 ج.م نقدي.
6. يحصّل طلب تاني 50 ج.م بطاقة.
7. يقفل الوردية بعدّ 590 ج.م.
8. لازم المتوقع يطلع 600، والفرق −10، والسبب مطلوب.
9. الوردية تظهر للمالك في المراجعة، ويوصل إشعار فرق نقدية.
10. إغلاق اليوم يرفض لو فيه وردية تانية مفتوحة، وينجح بعد قفلها.
11. حجز جديد من تطبيق العميل يطلق الصوت ويفضل ظاهر لحد تأكيده.

---

## برومبت جاهز

لو بتستخدم مساعد AI في الكود، انسخ الجزء ده:

```text
Add branch staff operations to the vendor dashboard. Reception staff work from
this dashboard on a tablet or computer. There is no QR check-in and no employee app.

1. Staff login: owners, managers and employees sign in with phone and password.
   Show and allow pages by role and permissions, and enforce this on the server.
   Employees see only their own branch and no finance, commission or net figures.
   Replace all "employee app" wording with the vendor dashboard, and require a
   password change on first login.

2. Shifts: add a "My shift" page. Opening a shift records opening_cash and creates
   a staff_shifts row with review_status 'open'. One open shift per staff member.
   Add GET /vendor/shifts/current, POST /vendor/shifts/open and
   POST /vendor/shifts/current/submit.

3. Payments: link each payment to one shift, using a shift_id column or an
   equally exact link. Managers and employees need an open shift to collect.
   Owners may collect without one, and that payment is marked as outside a shift.

4. Closing a shift: warn about open and unpaid orders. Ask for counted cash before
   showing the expected amount. expected_cash = opening_cash + cash collected in the
   shift - cash refunded in the shift. difference = actual_cash - expected_cash.
   Require a reason when difference is not zero. Save card_payments, cash_payments,
   orders_completed and actual_end, set review_status to 'submitted', send a
   cash_difference notification when needed, and write audit entries.

5. Day closing: refuse while a shift is open. Owners and managers with closeShift
   can close another person's shift with a reason. Flag shifts open over 16 hours.

6. New bookings: play a sound, ask the user to enable sound at shift start because
   browsers block autoplay, keep the alert until the booking is handled, and show
   the waiting count.

7. Make the live board, bookings and orders usable on a landscape tablet with
   44px touch targets and no horizontal page scrolling.

Keep existing vendor API behavior for the owner mobile app. Do not break
/api/v1/vendor/* responses.
```

---

## المطلوب منك كرد

1. هل فيه تطبيق موظفين أو API ليه موجود بالفعل؟
2. جدول زمني لكل بند من 🔴.
3. أي قاعدة تشغيل شايف إنها محتاجة تتغير قبل ما تبدأ.
4. لما تضيف `shift_id` أو أي عملية جديدة، ابعتلي التفاصيل عشان تطبيق المالك يفضل مطابق.
