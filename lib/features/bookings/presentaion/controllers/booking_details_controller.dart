import 'package:get/get.dart';

import '../../../../commons/models/branch_model.dart';
import '../../../../commons/models/order_model.dart';
import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../booking/presentaion/controllers/booking_controller.dart';
import '../widgets/cancel_sheet.dart';
import '../widgets/qr_fullscreen.dart';

class BookingDetailsController extends GetxController {
  final _orders = OrderService();

  final order = Rxn<OrderModel>();
  final cancelReason = 'cancel.r1'.obs;
  final cancelling = false.obs;
  final loading = false.obs;

  /// Why the order could not be loaded; shown only when nothing is cached.
  final error = RxnString();

  late final String orderId;
  Worker? _reconnect;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  BranchModel? get branch => order.value == null ? null : _db.branch(order.value!.branchId);

  VehicleModel? get vehicle => order.value == null ? null : _db.vehicle(order.value!.vehicleId);

  bool get hasReview => _db.reviews.any((r) => r.orderId == orderId);

  bool get lateWindow => order.value != null && _orders.insideFreeWindow(order.value!);

  bool get canReschedule => order.value != null && order.value!.status.canCancel && !lateWindow;

  bool get canReport => order.value != null &&
      const [OrderStatus.completed, OrderStatus.cancelled, OrderStatus.noShow].contains(order.value!.status);

  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments?.toString() ?? '';
    _sync();
    load();
    ever(_db.orders, (_) => _sync());
    ever(_db.reviews, (_) => order.refresh());
    // Status changes made while offline did not arrive over realtime.
    _reconnect = ConnectivityService.maybe?.onReconnect(load);
  }

  Future<void> load() async {
    if (orderId.isEmpty) return;
    loading.value = true;
    try {
      await _db.refreshOrder(orderId, throwOnError: true);
      // Opened from a notification: the branch may not be cached yet.
      final branchId = _db.order(orderId)?.branchId;
      if (branchId != null && _db.branch(branchId) == null) {
        await _db.fetchBranchDetails(branchId, throwOnError: true);
      }
      error.value = null;
    } catch (e) {
      error.value = ApiException.messageFor(e);
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    _reconnect?.dispose();
    super.onClose();
  }

  void _sync() {
    final prev = order.value?.status;
    final next = _db.order(orderId);
    order.value = next;
    order.refresh();
    if (prev != null && next != null && prev != next.status) {
      Utils.getSnakBar(message: 'status.${next.status.key}'.tr, type: TosterTypes.sucsses);
    }
  }

  void openQr() {
    final o = order.value;
    if (o == null || !o.showsQr) return;
    Get.dialog(QrFullscreen(code: o.code, number: o.number), useSafeArea: false);
  }

  void openCancel() {
    cancelReason.value = 'cancel.r1';
    AppBottomSheet.show(title: 'cancel.title'.tr, child: const CancelSheet());
  }

  void setReason(String key) => cancelReason.value = key;

  Future<void> confirmCancel() async {
    final o = order.value;
    if (o == null) return;
    cancelling.value = true;
    try {
      await _orders.cancel(o, cancelReason.value);
      Get.back();
      Utils.getSnakBar(message: 'toast.cancelled'.tr, type: TosterTypes.sucsses);
    } on BookingException catch (e) {
      Get.back();
      Utils.getSnakBar(
        message: (e.code == 'order_not_cancellable' ? 'cancel.notAllowed' : 'cancel.failed').tr,
        type: TosterTypes.failed,
      );
    } catch (e) {
      Utils.getSnakBar(message: ApiException.messageFor(e, fallback: 'cancel.failed'.tr), type: TosterTypes.failed);
    } finally {
      cancelling.value = false;
    }
  }

  void reschedule() {
    if (order.value == null) return;
    if (!canReschedule) {
      Utils.getSnakBar(message: 'reschedule.blocked'.tr, type: TosterTypes.warning);
      return;
    }
    Get.find<BookingController>().startReschedule(order.value!);
  }

  void bookAgain() {
    if (order.value != null) Get.find<BookingController>().bookAgain(order.value!);
  }

  void review() => Get.toNamed(Routes.reviewRoute, arguments: orderId);

  void report() => Get.toNamed(Routes.reportRoute, arguments: orderId);

  void contact() {
    if (branch != null) MapsService.call(branch!.phone);
  }

  void navigate() {
    if (branch != null) MapsService.openDirections(branch!.lat, branch!.lng);
  }

  void simulateAdvance() {
    if (order.value != null) _orders.advance(order.value!);
  }
}
