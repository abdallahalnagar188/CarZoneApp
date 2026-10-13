import 'dart:math' as math;

import 'package:get/get.dart';

import '../../commons/models/area_model.dart';
import '../../commons/models/branch_model.dart';
import '../../commons/models/customer_model.dart';
import '../../commons/models/localized_text.dart';
import '../../commons/models/notification_model.dart';
import '../../commons/models/offer_model.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/review_model.dart';
import '../../commons/models/vehicle_model.dart';
import '../../commons/models/wash_service_model.dart';
import '../enums/enums.dart';

class CarzoneDbService extends GetxService {
  final areas = <AreaModel>[];
  final branches = <BranchModel>[];
  final services = <WashServiceModel>[];
  final offers = <OfferModel>[];
  final reviews = <ReviewModel>[].obs;
  final customers = <CustomerModel>[];
  final vehicles = <VehicleModel>[].obs;
  final orders = <OrderModel>[].obs;
  final notifications = <NotificationModel>[].obs;
  final favorites = <String>{}.obs;
  final complaints = <Map<String, dynamic>>[];

  int _nextNumber = 10001;
  int _nextTicket = 501;
  final _codes = ['5K8P2', 'H7Q3M', 'R2N8T', 'B9X4L', 'W6C5Z', 'J3V7K'];

  static const _names = [
    'Ahmed Hassan', 'Mona Salah', 'Omar Fathy', 'Nour Adel', 'Hassan Magdy',
    'Layla Mostafa', 'Youssef Kamal', 'Farah Nabil', 'Mahmoud Eid',
    'Salma Hassan', 'Karim Tarek', 'Hana Osama', 'Tamer Shawky', 'Dina Hany',
    'Ali Gaber', 'Mariam Samir', 'Sherif Lotfy', 'Aya Khaled', 'Hossam Reda',
    'Nada Fouad',
  ];

  static const _comments = [
    LocalizedText('شغل نظيف والموعد كان مظبوط.', 'Clean work and the slot was on time.'),
    LocalizedText('الداخلية رجعت جديدة.', 'The interior looks new again.'),
    LocalizedText('كويس بس الانتظار زاد شوية.', 'Good, though the wait ran a bit long.'),
    LocalizedText('سعر واضح وتعامل محترم.', 'Clear price and polite staff.'),
  ];

  CarzoneDbService init() {
    _seed(DateTime.now());
    return this;
  }

  DateTime _at(DateTime now, int dayOffset, int hour, [int minute = 0]) =>
      DateTime(now.year, now.month, now.day + dayOffset, hour, minute);

  List<WorkingDay> _week(String open, String close, [List<int> closed = const []]) =>
      List.generate(7, (i) => WorkingDay(open, close, closed: closed.contains(i)));

  void _seed(DateTime now) {
    areas.addAll(const [
      AreaModel(id: 'nasr', name: LocalizedText('مدينة نصر', 'Nasr City'), lat: 30.0566, lng: 31.3301),
      AreaModel(id: 'helio', name: LocalizedText('مصر الجديدة', 'Heliopolis'), lat: 30.091, lng: 31.322),
      AreaModel(id: 'nc', name: LocalizedText('التجمع', 'New Cairo'), lat: 30.0074, lng: 31.4913),
      AreaModel(id: 'maadi', name: LocalizedText('المعادي', 'Maadi'), lat: 29.9602, lng: 31.2497),
      AreaModel(id: 'zamalek', name: LocalizedText('الزمالك', 'Zamalek'), lat: 30.0626, lng: 31.2194),
      AreaModel(id: 'moh', name: LocalizedText('المهندسين', 'Mohandessin'), lat: 30.0554, lng: 31.2001),
      AreaModel(id: 'zayed', name: LocalizedText('الشيخ زايد', 'Sheikh Zayed'), lat: 30.0278, lng: 30.9746),
      AreaModel(id: 'oct', name: LocalizedText('٦ أكتوبر', '6th of October'), lat: 29.972, lng: 30.944),
    ]);

    final defs = <List<dynamic>>[
      ['br_nasr', 'biz_carzen', 'nasr', 'كارزن ووش – مدينة نصر', 'Carzen Wash – Nasr City', 30.0642, 31.348, 6, false, _week('09:00', '24:00'), ['waiting', 'ac', 'wifi', 'card', 'coffee', 'covered'], 1.0],
      ['br_helio', 'biz_carzen', 'helio', 'كارزن ووش – مصر الجديدة', 'Carzen Wash – Heliopolis', 30.0872, 31.3195, 4, false, _week('09:00', '24:00'), ['waiting', 'ac', 'card'], 1.0],
      ['br_nile_maadi', 'biz_nile', 'maadi', 'بريق النيل – المعادي', 'Nile Sparkle – Maadi', 29.9628, 31.258, 5, true, _week('08:00', '22:00'), ['waiting', 'wifi', 'coffee'], 1.1],
      ['br_nile_zam', 'biz_nile', 'zamalek', 'بريق النيل – الزمالك', 'Nile Sparkle – Zamalek', 30.0602, 31.2215, 3, false, _week('10:00', '22:00'), ['ac', 'card', 'covered'], 1.2],
      ['br_palm_nc', 'biz_palm', 'nc', 'رغوة النخيل – التجمع', 'Palm Foam – New Cairo', 30.013, 31.478, 6, true, _week('09:00', '23:00'), ['waiting', 'ac', 'wifi', 'card'], 1.0],
      ['br_palm_oct', 'biz_palm', 'oct', 'رغوة النخيل – ٦ أكتوبر', 'Palm Foam – 6th of October', 29.969, 30.952, 4, false, _week('09:00', '21:00'), ['waiting', 'covered'], 0.9],
      ['br_lotus_moh', 'biz_lotus', 'moh', 'لوتس – المهندسين', 'Lotus Auto Spa – Mohandessin', 30.0518, 31.203, 3, false, _week('11:00', '23:00', [5]), ['ac', 'wifi', 'coffee', 'card'], 1.3],
      ['br_corniche_zam', 'biz_corniche', 'zamalek', 'الكورنيش – الزمالك', 'Corniche Clean – Zamalek', 30.066, 31.224, 4, false, _week('09:00', '20:00', [5]), ['waiting', 'card'], 1.0],
      ['br_pyramid_zay', 'biz_pyramid', 'zayed', 'بولش الهرم – الشيخ زايد', 'Pyramid Polish – Sheikh Zayed', 30.031, 30.982, 5, false, _week('09:00', '22:00'), ['waiting', 'ac', 'covered'], 0.95],
      ['br_pyramid_oct', 'biz_pyramid', 'oct', 'بولش الهرم – ٦ أكتوبر', 'Pyramid Polish – 6th of October', 29.981, 30.961, 4, false, _week('09:00', '21:00'), ['waiting', 'card'], 0.9],
      ['br_oasis_nasr', 'biz_oasis', 'nasr', 'لمعان الواحة – مدينة نصر', 'Oasis Shine – Nasr City', 30.0488, 31.339, 5, true, _week('08:00', '24:00'), ['waiting', 'ac', 'wifi', 'coffee', 'card'], 1.0],
      ['br_golden_hel', 'biz_golden', 'helio', 'الإطار الذهبي – مصر الجديدة', 'Golden Tire Wash – Heliopolis', 30.0944, 31.333, 4, false, _week('09:00', '23:00'), ['card', 'covered', 'waiting'], 1.05],
      ['br_dune_maadi', 'biz_dune', 'maadi', 'كثبان حمراء – المعادي', 'Red Dune Wash – Maadi', 29.955, 31.27, 3, false, _week('10:00', '20:00'), ['waiting'], 0.8],
    ];

    for (var i = 0; i < defs.length; i++) {
      final d = defs[i];
      final area = areas.firstWhere((a) => a.id == d[2]);
      branches.add(BranchModel(
        id: d[0],
        businessId: d[1],
        areaId: d[2],
        name: LocalizedText(d[3], d[4]),
        address: LocalizedText('${area.name.ar}، القاهرة', '${area.name.en}, Cairo'),
        lat: d[5],
        lng: d[6],
        capacity: d[7],
        featured: d[8],
        workingHours: d[9],
        amenities: List<String>.from(d[10]),
        phone: '+20 2 555 0142',
        photoSeed: i,
        businessActive: d[1] != 'biz_dune',
        settings: BranchSettings(autoConfirm: d[0] == 'br_oasis_nasr'),
      ));
      final mult = d[11] as double;
      int price(int n) => d[0] == 'br_nasr' ? n : math.max(20, (n * mult).round());
      void svc(String key, ServiceType type, String cat, LocalizedText name, int p, int dur) {
        services.add(WashServiceModel(
          id: 'svc_${d[0]}_$key',
          branchId: d[0],
          type: type,
          category: cat,
          name: name,
          description: type == ServiceType.addon
              ? const LocalizedText('إضافة اختيارية على الخدمة الأساسية.', 'Optional extra on the main service.')
              : const LocalizedText('خدمة غسيل بمعايير كارزن.', 'A Carzen-standard wash service.'),
          price: price(p),
          durationMin: dur,
        ));
      }

      svc('ext', ServiceType.primary, 'exterior', const LocalizedText('غسيل خارجي', 'Exterior Wash'), 100, 20);
      svc('int', ServiceType.primary, 'interior', const LocalizedText('غسيل داخلي', 'Interior Wash'), 100, 25);
      svc('full', ServiceType.primary, 'full', const LocalizedText('غسيل داخلي وخارجي', 'Interior + Exterior'), 180, 40);
      svc('deep', ServiceType.primary, 'deep', const LocalizedText('تنظيف عميق (بخار)', 'Deep Cleaning (Steam)'), 300, 60);
      svc('tire', ServiceType.addon, 'exterior', const LocalizedText('تنظيف الإطارات', 'Tire Cleaning'), 30, 5);
      svc('air', ServiceType.addon, 'interior', const LocalizedText('معطر جو', 'Air Freshener'), 20, 2);
      svc('wax', ServiceType.addon, 'exterior', const LocalizedText('تلميع بالشمع', 'Wax Polish'), 60, 15);
    }

    offers.addAll([
      OfferModel(
        id: 'of_platform',
        platform: true,
        branchIds: branches.map((b) => b.id).toList(),
        serviceIds: services.where((s) => s.category == 'exterior' && s.isPrimary).map((s) => s.id).toList(),
        title: const LocalizedText('خصم ١٥٪ على الغسيل الخارجي', '15% off exterior washes'),
        description: const LocalizedText('على كل المغاسل المشاركة هذا الأسبوع.', 'At participating washes this week.'),
        discountType: DiscountType.percent,
        discountValue: 15,
        startAt: _at(now, -1, 0),
        endAt: _at(now, 5, 23),
        status: 'active',
        featured: true,
        photoIndex: 0,
      ),
      OfferModel(
        id: 'of_deep',
        platform: false,
        branchIds: const ['br_nasr'],
        serviceIds: const ['svc_br_nasr_deep'],
        title: const LocalizedText('تنظيف عميق بخصم ١٥٪', '15% off deep cleaning'),
        description: const LocalizedText('على التنظيف بالبخار في مدينة نصر.', 'Steam cleaning at Nasr City.'),
        discountType: DiscountType.percent,
        discountValue: 15,
        startAt: _at(now, -2, 0),
        endAt: _at(now, 6, 23),
        status: 'active',
        photoIndex: 1,
      ),
      OfferModel(
        id: 'of_nile',
        platform: false,
        branchIds: const ['br_nile_maadi'],
        serviceIds: const ['svc_br_nile_maadi_full'],
        title: const LocalizedText('٢٠ ج.م على الغسيل الكامل', '20 EGP off a full wash'),
        description: const LocalizedText('في فرع المعادي.', 'At the Maadi branch.'),
        discountType: DiscountType.fixed,
        discountValue: 20,
        startAt: _at(now, -1, 0),
        endAt: _at(now, 4, 23),
        status: 'active',
        photoIndex: 2,
      ),
    ]);

    customers.add(CustomerModel(id: 'cu_ahmed', name: 'Ahmed Hassan', phone: '+20 100 123 4567'));
    for (var i = 1; i < _names.length; i++) {
      final n = 1100000000 + i * 137;
      final s = n.toString();
      customers.add(CustomerModel(
        id: 'cu_$i',
        name: _names[i],
        phone: '+20 ${s.substring(0, 3)} ${s.substring(3, 6)} ${s.substring(6)}',
      ));
    }

    vehicles.addAll([
      VehicleModel(id: 've_corolla', customerId: 'cu_ahmed', make: 'Toyota', model: 'Corolla', year: 2021, color: 'white', plate: 'ABC123', isDefault: true),
      VehicleModel(id: 've_sportage', customerId: 'cu_ahmed', make: 'Kia', model: 'Sportage', year: 2023, color: 'black', plate: 'KLM482'),
    ]);

    final full = services.firstWhere((s) => s.id == 'svc_br_nasr_full');
    final fullItem = OrderItem(serviceId: full.id, name: full.name, type: full.type, price: full.price, durationMin: full.durationMin);
    const ahmedDays = [14, 17, 19, 21, 23, 25, 27];
    for (var i = 0; i < ahmedDays.length; i++) {
      final at = _at(now, -ahmedDays[i], 11);
      orders.add(OrderModel(
        id: 'ord_ahmed_$i',
        number: 'CZ-${9800 + i}',
        code: 'A${i}K7P',
        customerId: 'cu_ahmed',
        vehicleId: 've_corolla',
        branchId: 'br_nasr',
        items: [fullItem],
        subtotal: 180,
        discount: 0,
        total: 180,
        durationMin: 40,
        scheduledAt: at,
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.paid,
        createdAt: at.subtract(const Duration(days: 1)),
        timeline: [
          TimelineEntry('pending', at.subtract(const Duration(days: 1))),
          TimelineEntry('confirmed', at.subtract(const Duration(hours: 20))),
          TimelineEntry('waiting', at.subtract(const Duration(minutes: 5))),
          TimelineEntry('in_service', at.add(const Duration(minutes: 2))),
          TimelineEntry('completed', at.add(const Duration(minutes: 42))),
        ],
      ));
    }
    final ns = _at(now, -30, 16);
    orders.add(OrderModel(
      id: 'ord_ahmed_ns',
      number: 'CZ-9790',
      code: 'N5S2W',
      customerId: 'cu_ahmed',
      vehicleId: 've_corolla',
      branchId: 'br_nasr',
      items: [fullItem],
      subtotal: 180,
      discount: 0,
      total: 180,
      durationMin: 40,
      scheduledAt: ns,
      status: OrderStatus.noShow,
      createdAt: ns.subtract(const Duration(days: 1)),
      timeline: [
        TimelineEntry('pending', ns.subtract(const Duration(days: 1))),
        TimelineEntry('confirmed', ns.subtract(const Duration(hours: 22))),
        TimelineEntry('no_show', ns.add(const Duration(minutes: 15))),
      ],
    ));

    final ext = services.firstWhere((s) => s.id == 'svc_br_nasr_ext');
    final busy = [10, 10, 11, 12, 13, 13, 14, 15, 18, 19, 19, 20];
    for (var i = 0; i < busy.length; i++) {
      final at = _at(now, 0, busy[i], i.isEven ? 0 : 30);
      orders.add(OrderModel(
        id: 'ord_bg_$i',
        number: 'CZ-${9700 + i}',
        code: 'BG${i}XX',
        customerId: customers[1 + i % 19].id,
        vehicleId: '',
        branchId: 'br_nasr',
        items: [OrderItem(serviceId: ext.id, name: ext.name, type: ext.type, price: ext.price, durationMin: ext.durationMin)],
        subtotal: ext.price,
        discount: 0,
        total: ext.price,
        durationMin: 40,
        scheduledAt: at,
        status: OrderStatus.confirmed,
        createdAt: at.subtract(const Duration(hours: 5)),
      ));
    }

    final nasrReviews = <ReviewModel>[];
    for (var i = 0; i < 6; i++) {
      nasrReviews.add(ReviewModel(
        id: 'rv_ahmed_$i',
        orderId: 'ord_ahmed_${i + 1}',
        customerName: 'Ahmed Hassan',
        branchId: 'br_nasr',
        serviceName: full.name,
        stars: 5,
        comment: _comments[i % 4].value,
        tags: const ['clean'],
        createdAt: _at(now, -ahmedDays[i + 1], 15),
      ));
    }
    for (var i = 0; i < 14; i++) {
      final stars = i < 10 ? 5 : 4;
      nasrReviews.add(ReviewModel(
        id: 'rv_host_$i',
        customerName: _names[1 + i % 19],
        branchId: 'br_nasr',
        serviceName: ext.name,
        stars: stars,
        comment: (stars == 4 ? _comments[2] : _comments[i % 2 == 0 ? 0 : 1]).ar,
        tags: stars == 5 ? const ['clean'] : const ['value'],
        reply: i == 2 ? 'شكراً لتقييمك، ننتظرك مرة أخرى!' : null,
        createdAt: _at(now, -(2 + i), 18),
      ));
    }
    reviews.addAll(nasrReviews);

    final rnd = math.Random(20261008);
    for (final b in branches.where((b) => b.id != 'br_nasr')) {
      final count = 4 + rnd.nextInt(14);
      for (var i = 0; i < count; i++) {
        final stars = 3 + rnd.nextInt(3);
        reviews.add(ReviewModel(
          id: 'rv_${b.id}_$i',
          customerName: _names[rnd.nextInt(_names.length)],
          branchId: b.id,
          serviceName: services.firstWhere((s) => s.branchId == b.id && s.isPrimary).name,
          stars: stars,
          comment: _comments[rnd.nextInt(4)].ar,
          createdAt: _at(now, -(1 + rnd.nextInt(28)), 12 + rnd.nextInt(8)),
        ));
      }
    }

    notifications.addAll([
      NotificationModel(
        id: 'nt_ahmed_review',
        userId: 'cu_ahmed',
        type: 'review_reminder',
        title: const LocalizedText('قيّم زيارتك الأخيرة', 'Rate your last visit'),
        body: const LocalizedText('غسيل داخلي وخارجي في كارزن ووش – مدينة نصر.', 'Interior + Exterior at Carzen Wash – Nasr City.'),
        orderId: 'ord_ahmed_0',
        createdAt: _at(now, -1, 18),
      ),
      NotificationModel(
        id: 'nt_ahmed_offer',
        userId: 'cu_ahmed',
        type: 'offer',
        title: const LocalizedText('خصم على الغسيل الخارجي', 'Exterior wash offer'),
        body: const LocalizedText('١٥٪ هذا الأسبوع على الغسيل الخارجي.', '15% off exterior washes this week.'),
        createdAt: _at(now, 0, 9),
      ),
    ]);
  }

  BranchModel? branch(String id) => branches.firstWhereOrNull((b) => b.id == id);

  AreaModel area(String id) => areas.firstWhere((a) => a.id == id, orElse: () => areas.first);

  WashServiceModel? service(String id) => services.firstWhereOrNull((s) => s.id == id);

  OrderModel? order(String id) => orders.firstWhereOrNull((o) => o.id == id);

  VehicleModel? vehicle(String id) => vehicles.firstWhereOrNull((v) => v.id == id);

  CustomerModel? customerByPhone(String phone) =>
      customers.firstWhereOrNull((c) => c.phone == phone);

  CustomerModel? customerById(String? id) =>
      id == null ? null : customers.firstWhereOrNull((c) => c.id == id);

  List<WashServiceModel> servicesFor(String branchId) =>
      services.where((s) => s.branchId == branchId && s.active).toList();

  List<ReviewModel> reviewsFor(String branchId) =>
      reviews.where((r) => r.branchId == branchId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  ({double rating, int count}) ratingFor(String branchId) {
    final list = reviews.where((r) => r.branchId == branchId).toList();
    if (list.isEmpty) return (rating: 0, count: 0);
    final avg = list.fold<int>(0, (s, r) => s + r.stars) / list.length;
    return (rating: avg, count: list.length);
  }

  CustomerModel registerCustomer(String phone, String name) {
    final row = CustomerModel(id: 'cu_new_${customers.length}', name: name, phone: phone);
    customers.add(row);
    return row;
  }

  String nextNumber() => 'CZ-${_nextNumber++}';

  String nextCode() => _codes[(_nextNumber - 10002) % _codes.length];

  String nextTicket() => 'TK-${_nextTicket++}';

  void notify({
    required String userId,
    required String type,
    required LocalizedText title,
    required LocalizedText body,
    String? orderId,
  }) {
    notifications.insert(
      0,
      NotificationModel(
        id: 'nt_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        type: type,
        title: title,
        body: body,
        orderId: orderId,
        createdAt: DateTime.now(),
      ),
    );
  }
}
