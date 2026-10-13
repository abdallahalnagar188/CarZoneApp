import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/vehicle_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

class CarsController extends GetxController {
  final plateController = TextEditingController();
  final yearController = TextEditingController();

  final make = RxnString();
  final model = RxnString();
  final color = 'white'.obs;
  final errors = <String, String>{}.obs;
  final saving = false.obs;
  final editingId = RxnString();

  CarzoneDbService get _db => Get.find<CarzoneDbService>();
  SessionService get _session => Get.find<SessionService>();

  List<VehicleModel> get vehicles =>
      _db.vehicles.where((v) => v.customerId == _session.userId).toList();

  List<String> get models => make.value == null ? const [] : VehicleModel.makes[make.value] ?? const [];

  void openNew() => AuthGuard.run(() => Get.toNamed(Routes.carFormRoute));

  void openEdit(VehicleModel v) => Get.toNamed(Routes.carFormRoute, arguments: v.id);

  void prepareForm() {
    errors.clear();
    final id = Get.arguments is String ? Get.arguments as String : null;
    final v = id == null ? null : _db.vehicle(id);
    editingId.value = v?.id;
    make.value = v?.make;
    model.value = v?.model;
    color.value = v?.color ?? 'white';
    plateController.text = v?.plate ?? '';
    yearController.text = v?.year?.toString() ?? '';
  }

  void setMake(String value) {
    make.value = value;
    model.value = null;
    errors.remove('make');
  }

  void setModel(String value) {
    model.value = value;
    errors.remove('model');
  }

  void setColor(String value) => color.value = value;

  Future<void> save() async {
    final uid = _session.userId;
    if (uid == null) return;
    final plate = FormatHelper.normalizePlate(plateController.text);
    final e = <String, String>{};
    if (make.value == null) e['make'] = 'cars.required'.tr;
    if (model.value == null) e['model'] = 'cars.required'.tr;
    if (plate.isEmpty) e['plate'] = 'cars.required'.tr;
    if (plate.isNotEmpty &&
        vehicles.any((v) => v.id != editingId.value && FormatHelper.normalizePlate(v.plate) == plate)) {
      e['plate'] = 'cars.dup'.tr;
    }
    errors.assignAll(e);
    if (e.isNotEmpty) return;
    saving.value = true;
    await Future.delayed(const Duration(milliseconds: 350));
    final year = int.tryParse(yearController.text.trim());
    final existing = editingId.value == null ? null : _db.vehicle(editingId.value!);
    if (existing != null) {
      existing
        ..make = make.value!
        ..model = model.value!
        ..color = color.value
        ..plate = plate
        ..year = year;
      _db.vehicles.refresh();
      _db.saveVehicle(existing);
    } else {
      final newV = VehicleModel(
        id: 've_${DateTime.now().microsecondsSinceEpoch}',
        customerId: uid,
        make: make.value!,
        model: model.value!,
        color: color.value,
        plate: plate,
        year: year,
        isDefault: vehicles.isEmpty,
      );
      _db.vehicles.add(newV);
      _db.saveVehicle(newV);
    }
    saving.value = false;
    Get.back();
    Utils.getSnakBar(message: 'cars.saved'.tr, type: TosterTypes.sucsses);
  }

  void setDefault(VehicleModel v) {
    for (final x in vehicles) {
      x.isDefault = x.id == v.id;
      _db.saveVehicle(x);
    }
    _db.vehicles.refresh();
  }

  Future<void> delete(VehicleModel v) async {
    final blocked = _db.orders.any((o) => o.vehicleId == v.id && o.status.isUpcoming);
    if (blocked) {
      Utils.getSnakBar(message: 'cars.deleteBlocked'.tr, type: TosterTypes.warning);
      return;
    }
    final ok = await Utils.confirm(
      title: 'cars.deleteAsk'.tr,
      okText: 'cars.delete'.tr,
      danger: true,
    );
    if (!ok) return;
    final wasDefault = v.isDefault;
    _db.vehicles.remove(v);
    _db.deleteVehicle(v.id);
    if (wasDefault && vehicles.isNotEmpty) {
      vehicles.first.isDefault = true;
      _db.saveVehicle(vehicles.first);
    }
    _db.vehicles.refresh();
    if (Get.currentRoute == Routes.carFormRoute) Get.back();
  }

  @override
  void onClose() {
    plateController.dispose();
    yearController.dispose();
    super.onClose();
  }
}
