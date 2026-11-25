import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/discovery_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

class FavoritesController extends GetxController {
  final _discovery = DiscoveryService();

  WashUpDbService get _db => Get.find<WashUpDbService>();

  SessionService get _session => Get.find<SessionService>();

  RxSet<String> get ids => _db.favorites;

  bool isFavorite(String branchId) => _db.favorites.contains(branchId);

  /// The heart flips at once; it flips back with a toast when the server
  /// call fails, and is not touched at all while offline. Favorites belong to
  /// the account: a guest signs in first and the wash is then added (GAP-037).
  Future<void> toggle(String branchId) async {
    final uid = _session.userId;
    if (uid == null) {
      AuthGuard.run(() {
        if (!isFavorite(branchId)) toggle(branchId);
      });
      return;
    }
    if (!ConnectivityService.online) {
      Utils.getSnakBar(message: 'offline.action'.tr, type: TosterTypes.warning);
      return;
    }
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
