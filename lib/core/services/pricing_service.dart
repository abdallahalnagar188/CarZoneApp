import 'package:get/get.dart';

import '../../commons/models/offer_model.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/wash_service_model.dart';
import 'carzone_db_service.dart';

class PriceQuote {
  final List<OrderItem> items;
  final int subtotal;
  final int discount;
  final OfferModel? offer;
  final int durationMin;

  const PriceQuote({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.offer,
    required this.durationMin,
  });

  int get total => subtotal - discount;

  static const empty = PriceQuote(
    items: [],
    subtotal: 0,
    discount: 0,
    offer: null,
    durationMin: 0,
  );
}

class PricingService {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  List<OfferModel> liveOffers([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return _db.offers.where((o) => o.isLive(ref)).toList();
  }

  OfferModel? offerFor(String branchId, String serviceId) {
    final list = liveOffers()
        .where((o) => o.branchIds.contains(branchId) && o.serviceIds.contains(serviceId))
        .toList();
    if (list.isEmpty) return null;
    final service = _db.service(serviceId);
    if (service == null) return list.first;
    list.sort((a, b) => b.discountFor(service.price).compareTo(a.discountFor(service.price)));
    return list.first;
  }

  PriceQuote quote({
    required String branchId,
    String? primaryId,
    List<String> addonIds = const [],
  }) {
    if (primaryId == null) return PriceQuote.empty;
    final primary = _db.service(primaryId);
    if (primary == null) return PriceQuote.empty;
    final addons = addonIds.map(_db.service).whereType<WashServiceModel>().toList();
    final all = [primary, ...addons];
    final items = all
        .map((s) => OrderItem(
              serviceId: s.id,
              name: s.name,
              type: s.type,
              price: s.price,
              durationMin: s.durationMin,
            ))
        .toList();
    final subtotal = all.fold<int>(0, (sum, s) => sum + s.price);
    final duration = all.fold<int>(0, (sum, s) => sum + s.durationMin);
    final offer = offerFor(branchId, primary.id);
    final discount = offer?.discountFor(primary.price) ?? 0;
    return PriceQuote(
      items: items,
      subtotal: subtotal,
      discount: discount,
      offer: offer,
      durationMin: duration,
    );
  }

  int? fromPrice(String branchId, {String? category}) {
    final list = _db
        .servicesFor(branchId)
        .where((s) => s.isPrimary && (category == null || s.category == category))
        .map((s) => s.price)
        .toList();
    if (list.isEmpty) return null;
    list.sort();
    return list.first;
  }
}
