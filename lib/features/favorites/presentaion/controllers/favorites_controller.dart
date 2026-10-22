import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/local/cache_controller.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/utils.dart';

class FavoritesController extends GetxController {
  final _discovery = DiscoveryService();

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  SessionService get _session => Get.find<SessionService>();

  RxSet<String> get ids => _db.favorites;

  bool isFavorite(String branchId) => _db.favorites.contains(branchId);

  String resolveEffectiveUserId() {
    final sessionUid = _session.userId ?? SupabaseService.client.auth.currentUser?.id;
    if (sessionUid != null && sessionUid.isNotEmpty) return sessionUid;

    final cachedUid = CacheController().getter(key: CacheKeys.userId);
    if (cachedUid is String && cachedUid.isNotEmpty) return cachedUid;

    var guestId = CacheController().getter(key: CacheKeys.guestUserId);
    if (guestId is! String || guestId.isEmpty) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      CacheController().setter(key: CacheKeys.guestUserId, value: guestId);
    }
    return guestId;
  }

  /// The heart flips at once; it flips back with a toast when the server
  /// call fails, and is not touched at all while offline.
  Future<void> toggle(String branchId) async {
    if (!ConnectivityService.online) {
      Utils.getSnakBar(message: 'offline.action'.tr, type: TosterTypes.warning);
      return;
    }
    final uid = resolveEffectiveUserId();
    final saved = await _db.toggleFavorite(branchId, uid);
    if (!saved) Utils.getSnakBar(message: 'fav.failed'.tr, type: TosterTypes.failed);
  }

  List<BranchListingModel> get rows => _db.favorites
      .map(_db.branch)
      .whereType<BranchModel>()
      .map((b) => _discovery.decorate(b))
      .toList();

  void openWash(String branchId) => Get.toNamed(Routes.washDetailsRoute, arguments: branchId);

  void explore() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});
}
