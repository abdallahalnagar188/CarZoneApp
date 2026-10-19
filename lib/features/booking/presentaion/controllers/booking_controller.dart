import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/branch_model.dart';
import '../../../../commons/models/order_model.dart';
import '../../../../commons/models/vehicle_model.dart';
import '../../../../commons/models/wash_service_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/availability_service.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

class BookingController extends GetxController {
  final _pricing = PricingService();
  final _availability = AvailabilityService();
  final _orders = OrderService();
  final noteController = TextEditingController();

  final branchId = ''.obs;
  final primaryId = RxnString();
  final addonIds = <String>[].obs;
  final vehicleId = RxnString();
  final day = DateTime.now().obs;
  final slot = Rxn<DateTime>();
  final slots = <SlotModel>[].obs;
  final loadingSlots = false.obs;
  final confirming = false.obs;
  final createdOrder = Rxn<OrderModel>();
  final rescheduleOrder = Rxn<OrderModel>();

  bool _selectNewCar = false;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get _session => Get.find<SessionService>();

  BranchModel? get branch => _db.branch(branchId.value);

  List<WashServiceModel> get primaries =>
      _db.servicesFor(branchId.value).where((s) => s.isPrimary).toList();

  List<WashServiceModel> get addons =>
      _db.servicesFor(branchId.value).where((s) => s.type == ServiceType.addon).toList();

  List<VehicleModel> get vehicles =>
      _db.vehicles.where((v) => v.customerId == _session.userId).toList();

  PriceQuote get quote => _pricing.quote(
        branchId: branchId.value,
        primaryId: primaryId.value,
        addonIds: addonIds,
      );

  int get durationMin => rescheduleOrder.value?.durationMin ?? quote.durationMin;

  bool get isReschedule => rescheduleOrder.value != null;

  VehicleModel? get vehicle => vehicleId.value == null ? null : _db.vehicle(vehicleId.value!);

  List<DateTime> get days {
    final now = DateTime.now();
    final max = branch?.settings.maxAdvanceDays ?? 7;
    return List.generate(max + 1, (i) => DateTime(now.year, now.month, now.day + i));
  }

  bool isClosedDay(DateTime d) => branch == null || _availability.isClosedDay(branch!, d);

  @override
  void onInit() {
    super.onInit();
    ever(_db.vehicles, (_) {
      if (_selectNewCar && vehicles.isNotEmpty) {
        vehicleId.value = vehicles.last.id;
        _selectNewCar = false;
      }
    });
  }

  void _reset(String id) {
    branchId.value = id;
    primaryId.value = null;
    addonIds.clear();
    vehicleId.value = null;
    slot.value = null;
    noteController.clear();
    rescheduleOrder.value = null;
    createdOrder.value = null;
    final now = DateTime.now();
    day.value = DateTime(now.year, now.month, now.day);
  }

  void clearDraft() => _reset(branchId.value);

  void start(String id, {String? serviceId, DateTime? slot}) {
    _reset(id);
    primaryId.value = serviceId;
    if (slot != null) {
      day.value = DateTime(slot.year, slot.month, slot.day);
      this.slot.value = slot;
    }
    Get.toNamed(Routes.bookServiceRoute);
  }

  void bookAgain(OrderModel order) {
    _reset(order.branchId);
    primaryId.value = order.primary.serviceId;
    addonIds.assignAll(order.addons.map((a) => a.serviceId));
    vehicleId.value = order.vehicleId;
    loadSlots();
    AuthGuard.run(() => Get.toNamed(Routes.bookSlotRoute));
  }

  void startReschedule(OrderModel order) {
    _reset(order.branchId);
    rescheduleOrder.value = order;
    day.value = DateTime(order.scheduledAt.year, order.scheduledAt.month, order.scheduledAt.day);
    loadSlots();
    Get.toNamed(Routes.bookSlotRoute);
  }

  bool get hasDraft => primaryId.value != null || addonIds.isNotEmpty;

  Future<bool> confirmDiscard() async {
    if (!hasDraft) return true;
    return Utils.confirm(
      title: 'book.discard'.tr,
      body: 'book.discardBody'.tr,
      okText: 'book.discardYes'.tr,
      cancelText: 'book.keep'.tr,
      danger: true,
    );
  }

  Future<void> leaveFlow() async {
    if (await confirmDiscard()) {
      _reset(branchId.value);
      Get.back();
    }
  }

  void selectPrimary(String id) => primaryId.value = id;

  void toggleAddon(String id) {
    if (addonIds.contains(id)) {
      addonIds.remove(id);
    } else {
      addonIds.add(id);
    }
  }

  void continueFromService() {
    if (primaryId.value == null) return;
    AuthGuard.run(() {
      if (vehicleId.value == null || _db.vehicle(vehicleId.value!) == null) {
        final list = vehicles;
        vehicleId.value = (list.firstWhereOrNull((v) => v.isDefault) ?? list.firstOrNull)?.id;
      }
      Get.toNamed(Routes.bookCarRoute);
    });
  }

  void selectVehicle(String id) => vehicleId.value = id;

  void addCar() {
    _selectNewCar = true;
    Get.toNamed(Routes.carFormRoute);
  }

  void continueFromCar() {
    if (vehicleId.value == null) return;
    loadSlots();
    Get.toNamed(Routes.bookSlotRoute);
  }

  void selectDay(DateTime d) {
    if (isClosedDay(d)) return;
    day.value = d;
    if (slot.value != null && !FormatHelper.sameDay(slot.value!, d)) slot.value = null;
    loadSlots();
  }

  Future<void> loadSlots() async {
    final b = branch;
    if (b == null) return;
    loadingSlots.value = true;
    // Immediate fallback slots so UI is never blank
    slots.assignAll(_availability.slotsFor(
      b,
      day.value,
      durationMin: durationMin,
      excludeOrderId: rescheduleOrder.value?.id,
    ));

    try {
      final remote = await _availability.fetchRemoteSlots(
        b,
        day.value,
        durationMin: durationMin,
        excludeOrderId: rescheduleOrder.value?.id,
      );
      if (remote.isNotEmpty || slots.isEmpty) {
        slots.assignAll(remote);
      }
    } catch (_) {
    } finally {
      loadingSlots.value = false;
      if (slot.value != null &&
          !slots.any((s) =>
              s.start.isAtSameMomentAs(slot.value!) ||
              s.start == slot.value ||
              (s.start.year == slot.value!.year &&
                  s.start.month == slot.value!.month &&
                  s.start.day == slot.value!.day &&
                  s.start.hour == slot.value!.hour &&
                  s.start.minute == slot.value!.minute))) {
        slot.value = null;
      }
    }
  }

  void seeTomorrow() {
    final next = days.skip(1).where((d) => !isClosedDay(d)).firstOrNull;
    if (next != null) selectDay(next);
  }

  void selectSlot(DateTime s) => slot.value = s;

  Future<void> continueFromSlot() async {
    if (slot.value == null) return;
    if (isReschedule) {
      await _confirmReschedule();
      return;
    }
    Get.toNamed(Routes.bookSummaryRoute);
  }

  Future<void> _confirmReschedule() async {
    final order = rescheduleOrder.value!;
    confirming.value = true;
    try {
      await _orders.reschedule(order, slot.value!);
      confirming.value = false;
      Get.back();
      Utils.getSnakBar(message: 'reschedule.done'.tr, type: TosterTypes.sucsses);
    } on SlotTooSoonException {
      confirming.value = false;
      slot.value = null;
      loadSlots();
      Utils.getSnakBar(
        message: FormatHelper.isAr
            ? 'الموعد المحدد قد فات بالفعل أو قريب جداً. يرجى اختيار موعد قادم أو حجز ليوم غد.'
            : 'The selected slot has passed or is too soon. Please select an upcoming slot or choose tomorrow.',
        type: TosterTypes.warning,
      );
    } on SlotOutsideHoursException {
      confirming.value = false;
      slot.value = null;
      loadSlots();
      Utils.getSnakBar(
        message: FormatHelper.isAr
            ? 'الموعد المحدد خارج ساعات العمل للمغسلة. يرجى اختيار موعد متاح.'
            : 'The selected slot is outside branch operating hours. Please pick an available time.',
        type: TosterTypes.warning,
      );
    } on SlotTakenException {
      confirming.value = false;
      loadSlots();
      Utils.getSnakBar(message: 'book.slotTaken'.tr, type: TosterTypes.warning);
    } catch (e) {
      confirming.value = false;
      Utils.getSnakBar(message: _bookingError(e, 'reschedule.failed'), type: TosterTypes.failed);
    }
  }

  void editStep(String route) => Get.until((r) => r.settings.name == route);

  Future<void> confirm() async {
    final uid = _session.userId;
    if (uid == null || primaryId.value == null || vehicleId.value == null || slot.value == null) return;
    confirming.value = true;
    try {
      final order = await _orders.create(
        branchId: branchId.value,
        primaryId: primaryId.value!,
        addonIds: addonIds.toList(),
        vehicleId: vehicleId.value!,
        slot: slot.value!,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
      confirming.value = false;
      createdOrder.value = order;
      Get.offNamedUntil(
        Routes.bookSuccessRoute,
        (r) => r.settings.name == Routes.mainRoute || r.settings.name == Routes.washDetailsRoute,
      );
    } on SlotTooSoonException {
      confirming.value = false;
      slot.value = null;
      loadSlots();
      Utils.getSnakBar(
        message: FormatHelper.isAr
            ? 'الموعد المحدد قد فات بالفعل أو قريب جداً. يرجى اختيار موعد قادم أو حجز ليوم غد.'
            : 'The selected slot has passed or is too soon. Please select an upcoming slot or choose tomorrow.',
        type: TosterTypes.warning,
      );
      Get.until((r) => r.settings.name == Routes.bookSlotRoute);
    } on SlotOutsideHoursException {
      confirming.value = false;
      slot.value = null;
      loadSlots();
      Utils.getSnakBar(
        message: FormatHelper.isAr
            ? 'الموعد المحدد خارج ساعات العمل للمغسلة. يرجى اختيار موعد متاح.'
            : 'The selected slot is outside branch operating hours. Please pick an available time.',
        type: TosterTypes.warning,
      );
      Get.until((r) => r.settings.name == Routes.bookSlotRoute);
    } on SlotTakenException {
      confirming.value = false;
      slot.value = null;
      loadSlots();
      Utils.getSnakBar(message: '${'book.slotTaken'.tr}\n${'book.slotTakenBody'.tr}', type: TosterTypes.warning);
      Get.until((r) => r.settings.name == Routes.bookSlotRoute);
    } catch (e) {
      confirming.value = false;
      Utils.getSnakBar(message: _bookingError(e, 'book.failed'), type: TosterTypes.failed);
    }
  }

  String _bookingError(Object e, String fallbackKey) => switch (e) {
        BookingException(code: 'branch_unavailable') => 'book.unavailable'.tr,
        BookingException(code: 'account_suspended') => 'book.suspended'.tr,
        _ => fallbackKey.tr,
      };

  void viewCreated() {
    final order = createdOrder.value;
    if (order == null) return;
    Get.offNamedUntil(Routes.bookingDetailsRoute, (r) => r.settings.name == Routes.mainRoute, arguments: order.id);
  }

  void backHome() => Get.until((r) => r.settings.name == Routes.mainRoute);

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
