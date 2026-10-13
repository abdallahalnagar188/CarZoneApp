import 'package:get/get.dart';

import '../../commons/models/area_model.dart';
import '../../commons/models/customer_model.dart';
import '../enums/enums.dart';
import '../local/cache_controller.dart';
import 'carzone_db_service.dart';

class SessionService extends GetxService {
  final user = Rxn<CustomerModel>();
  final areaId = 'nasr'.obs;

  String? returnRoute;
  dynamic returnArguments;
  void Function()? pendingAction;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  bool get isLoggedIn => user.value != null;

  String? get userId => user.value?.id;

  AreaModel get area => _db.area(areaId.value);

  double get lat => area.lat;

  double get lng => area.lng;

  SessionService init() {
    final cache = CacheController();
    final id = cache.getter(key: CacheKeys.userId);
    if (id is String) user.value = _db.customerById(id);
    final cachedArea = cache.getter(key: CacheKeys.areaId);
    if (cachedArea is String) areaId.value = cachedArea;
    return this;
  }

  Future<void> signIn(CustomerModel customer) async {
    user.value = customer;
    await CacheController().setter(key: CacheKeys.userId, value: customer.id);
    await CacheController().setter(key: CacheKeys.loggedIn, value: true);
  }

  Future<void> signOut() async {
    user.value = null;
    await CacheController().logout();
  }

  Future<void> setArea(String id) async {
    areaId.value = id;
    await CacheController().setter(key: CacheKeys.areaId, value: id);
  }

  void rememberReturn(String route, {dynamic arguments, void Function()? action}) {
    returnRoute = route;
    returnArguments = arguments;
    pendingAction = action;
  }

  void clearReturn() {
    returnRoute = null;
    returnArguments = null;
    pendingAction = null;
  }
}
