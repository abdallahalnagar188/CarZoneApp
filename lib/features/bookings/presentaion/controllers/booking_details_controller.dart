import 'package:get/get.dart';

import '../../../../commons/models/branch_model.dart';
import '../../../../commons/models/order_model.dart';
import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/widgets/sheets/app_bottom_sheet.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
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

  late final String orderId;

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
    ever(_db.orders, (_) => _sync());
    ever(_db.reviews, (_) => order.refresh());
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
    await _orders.cancel(o, cancelReason.value);
    cancelling.value = false;
    Get.back();
    Utils.getSnakBar(message: 'toast.cancelled'.tr, type: TosterTypes.sucsses);
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

  void contact() => Utils.getSnakBar(message: 'toast.call'.tr, type: TosterTypes.warning);

  void navigate() => Utils.getSnakBar(message: 'toast.maps'.tr, type: TosterTypes.warning);

  void simulateAdvance() {
    if (order.value != null) _orders.advance(order.value!);
  }
}
