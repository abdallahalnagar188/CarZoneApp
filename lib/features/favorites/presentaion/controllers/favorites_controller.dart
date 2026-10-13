import 'package:get/get.dart';

import '../../../../commons/models/branch_listing_model.dart';
import '../../../../commons/models/branch_model.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/discovery_service.dart';

class FavoritesController extends GetxController {
  final _discovery = DiscoveryService();

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  RxSet<String> get ids => _db.favorites;

  bool isFavorite(String branchId) => _db.favorites.contains(branchId);

  void toggle(String branchId) {
    AuthGuard.run(() {
      if (_db.favorites.contains(branchId)) {
        _db.favorites.remove(branchId);
      } else {
        _db.favorites.add(branchId);
      }
    });
  }

  List<BranchListingModel> get rows => _db.favorites
      .map(_db.branch)
      .whereType<BranchModel>()
      .map((b) => _discovery.decorate(b))
      .toList();

  void openWash(String branchId) => Get.toNamed(Routes.washDetailsRoute, arguments: branchId);

  void explore() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'nearby'});
}
