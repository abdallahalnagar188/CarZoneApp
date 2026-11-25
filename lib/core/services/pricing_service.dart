import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../commons/models/offer_model.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/wash_service_model.dart';
import '../network/api_call.dart';
import 'supabase_service.dart';
import 'washup_db_service.dart';

class PriceQuote {
  final List<OrderItem> items;
  final num subtotal;
  final num discount;
  final OfferModel? offer;
  final int durationMin;

  const PriceQuote({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.offer,
    required this.durationMin,
  });

  num get total => subtotal - discount;

  static const empty = PriceQuote(
    items: [],
    subtotal: 0,
    discount: 0,
    offer: null,
    durationMin: 0,
  );
}

class PricingService {
  WashUpDbService get _db => Get.find<WashUpDbService>();

  List<OfferModel> liveOffers([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return _db.offers.where((o) => o.isLive(ref)).toList();
  }

  /// The offer create_order would apply to [serviceId] (GAP-034): a live offer
  /// linked to this branch (offer_branches), for the service's category when
  /// it is limited to some (offer_categories), on a primary service only; the
  /// biggest discount wins, ties by offer id.
  OfferModel? offerFor(String branchId, String serviceId) {
    final service = _db.service(serviceId);
    if (service == null || !service.isPrimary) return null;
    final list = liveOffers()
        .where((o) =>
            o.branchIds.contains(branchId) &&
            (o.categoryIds.isEmpty || o.categoryIds.contains(service.category)) &&
            (o.serviceIds.isEmpty || o.serviceIds.contains(serviceId)))
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) {
      final byAmount = b.discountFor(service.price).compareTo(a.discountFor(service.price));
      return byAmount != 0 ? byAmount : a.id.compareTo(b.id);
    });
    return list.first.discountFor(service.price) > 0 ? list.first : null;
  }

  /// The price create_order will charge, from the quote_order RPC (GAP-034).
  /// Null while the database does not have that RPC yet (the caller keeps the
  /// local [quote]); other failures are thrown.
  Future<PriceQuote?> serverQuote({
    required String branchId,
    required String primaryId,
    List<String> addonIds = const [],
  }) async {
    final local = quote(branchId: branchId, primaryId: primaryId, addonIds: addonIds);
    try {
      final res = await ApiCall.read(
        () => SupabaseService.client.rpc('quote_order', params: {
          'p_branch_id': branchId,
          'p_primary_service_id': primaryId,
          'p_addon_service_ids': addonIds,
        }),
        tag: 'quote_order',
      );
      return fromServer(Map<String, dynamic>.from(res as Map), local);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') return null;
      rethrow;
    }
  }

  /// A quote_order answer with the item lines of [local].
  PriceQuote fromServer(Map<String, dynamic> json, PriceQuote local) {
    final offerId = json['offer_id']?.toString();
    final discount = (json['discount'] as num?) ?? 0;
    return PriceQuote(
      items: local.items,
      subtotal: (json['subtotal'] as num?) ?? local.subtotal,
      discount: discount,
      offer: discount > 0 && offerId != null ? _db.offers.firstWhereOrNull((o) => o.id == offerId) : null,
      durationMin: (json['duration_min'] as num?)?.toInt() ?? local.durationMin,
    );
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
    final subtotal = all.fold<num>(0, (sum, s) => sum + s.price);
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

  num? fromPrice(String branchId, {String? category}) {
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
