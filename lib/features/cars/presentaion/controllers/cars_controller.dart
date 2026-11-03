import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/car_catalog.dart';
import '../../../../commons/models/vehicle_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/helpers/phone_helper.dart';
import '../../../../core/helpers/plate_helper.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

class CarsController extends GetxController {
  final plateCode = TextEditingController();
  final plateDigits = TextEditingController();
  final yearController = TextEditingController();

  /// The country whose plate rules apply, the customer's own by default.
  final plateCountry = Rx<PhoneCountry>(PhoneHelper.defaultCountry);

  /// An older free-text plate that is not a code and a number: kept as it is
  /// unless the customer types a new one.
  String _legacyPlate = '';

  final make = RxnString();
  final model = RxnString();
  final color = 'white'.obs;
  final errors = <String, String>{}.obs;
  final saving = false.obs;
  final editingId = RxnString();

  WashUpDbService get _db => Get.find<WashUpDbService>();
  SessionService get _session => Get.find<SessionService>();

  List<VehicleModel> get vehicles =>
      _db.vehicles.where((v) => v.customerId == _session.userId).toList();

  List<String> get models => CarCatalog.modelsOf(make.value);

  @override
  void onInit() {
    super.onInit();
    refreshVehicles();
    ever(_session.user, (_) => refreshVehicles());
  }

  Future<void> refreshVehicles() async {
    final uid = _session.userId;
    if (uid != null) {
      await _db.fetchVehicles(uid);
    }
  }

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
    final plate = v?.plate ?? '';
    final parts = PlateHelper.parse(plate);
    final own = PhoneHelper.fromE164(_session.user.value?.phone ?? '') ?? PhoneHelper.defaultCountry;
    plateCountry.value = PlateHelper.countryFor(plate, own);
    final code = parts?.code ?? '';
    plateCode.text = PlateHelper.isArabic(code) ? code.split('').join(' ') : code;
    plateDigits.text = parts?.digits ?? '';
    _legacyPlate = parts == null ? plate : '';
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

  void setPlateCountry(PhoneCountry country) {
    if (PlateHelper.lettered(country) != PlateHelper.lettered(plateCountry.value)) plateCode.clear();
    plateCountry.value = country;
    errors.remove('plate');
  }

  bool get _plateEmpty => plateCode.text.trim().isEmpty && plateDigits.text.trim().isEmpty;

  /// The plate as stored and shown, or empty when nothing is typed.
  String get _plate {
    if (_plateEmpty) return _legacyPlate;
    return PlateHelper.format(plateCode.text, plateDigits.text);
  }

  Future<void> save() async {
    final uid = _session.userId;
    if (uid == null) return;
    final plate = _plate;
    final key = FormatHelper.normalizePlate(plate);
    final yearText = FormatHelper.latinDigits(yearController.text.trim());
    final year = int.tryParse(yearText);
    final e = <String, String>{};
    if (make.value == null) e['make'] = 'cars.required'.tr;
    if (model.value == null) e['model'] = 'cars.required'.tr;
    if (yearText.isNotEmpty && (year == null || year < 1960 || year > DateTime.now().year + 1)) {
      e['year'] = 'cars.badYear'.trParams({'max': '${DateTime.now().year + 1}'});
    }
    if (key.isEmpty) {
      e['plate'] = 'cars.required'.tr;
    } else if (!_plateEmpty && !PlateHelper.isValid(plateCountry.value, plateCode.text, plateDigits.text)) {
      e['plate'] = (PlateHelper.lettered(plateCountry.value) ? 'cars.badPlateLetters' : 'cars.badPlateCode')
          .trParams({'max': '${PlateHelper.maxDigits(plateCountry.value)}'});
    } else if (vehicles.any((v) => v.id != editingId.value && FormatHelper.normalizePlate(v.plate) == key)) {
      e['plate'] = 'cars.dup'.tr;
    }
    errors.assignAll(e);
    if (e.isNotEmpty) return;
    if (!ConnectivityService.online) {
      Utils.getSnakBar(message: 'offline.action'.tr, type: TosterTypes.warning);
      return;
    }
    saving.value = true;
    // The list shows the change at once; it is undone if the server refuses it.
    final existing = editingId.value == null ? null : _db.vehicle(editingId.value!);
    final before = existing == null ? null : VehicleModel.fromJson(existing.toJson());
    VehicleModel? added;
    try {
      if (existing != null) {
        existing
          ..make = make.value!
          ..model = model.value!
          ..color = color.value
          ..plate = plate
          ..year = year;
        _db.vehicles.refresh();
        await _db.saveVehicle(existing);
      } else {
        added = VehicleModel(
          id: 've_${DateTime.now().microsecondsSinceEpoch}',
          customerId: uid,
          make: make.value!,
          model: model.value!,
          color: color.value,
          plate: plate,
          year: year,
          isDefault: vehicles.isEmpty,
        );
        _db.vehicles.add(added);
        await _db.saveVehicle(added);
      }
      saving.value = false;
      Get.back();
      Utils.getSnakBar(message: 'cars.saved'.tr, type: TosterTypes.sucsses);
    } catch (e) {
      saving.value = false;
      dev.log('[CarsController] Error saving vehicle: $e');
      if (added != null) _db.vehicles.remove(added);
      if (existing != null && before != null) {
        existing
          ..make = before.make
          ..model = before.model
          ..color = before.color
          ..plate = before.plate
          ..year = before.year;
        _db.vehicles.refresh();
      }
      Utils.getSnakBar(message: ApiException.messageFor(e, fallback: 'cars.saveFailed'.tr), type: TosterTypes.failed);
    }
  }

  Future<void> setDefault(VehicleModel v) async {
    if (!ConnectivityService.online) {
      Utils.getSnakBar(message: 'offline.action'.tr, type: TosterTypes.warning);
      return;
    }
    final previous = vehicles.firstWhereOrNull((x) => x.isDefault);
    for (final x in vehicles) {
      x.isDefault = x.id == v.id;
    }
    _db.vehicles.refresh();
    try {
      await _db.saveVehicle(v);
    } catch (e) {
      dev.log('[CarsController] Error setting default car: $e');
      for (final x in vehicles) {
        x.isDefault = x.id == previous?.id;
      }
      _db.vehicles.refresh();
      Utils.getSnakBar(message: ApiException.messageFor(e, fallback: 'cars.saveFailed'.tr), type: TosterTypes.failed);
    }
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
    if (!ConnectivityService.online) {
      Utils.getSnakBar(message: 'offline.action'.tr, type: TosterTypes.warning);
      return;
    }
    final wasDefault = v.isDefault;
    final index = _db.vehicles.indexOf(v);
    _db.vehicles.remove(v);
    if (!await _db.deleteVehicle(v.id)) {
      _db.vehicles.insert(index.clamp(0, _db.vehicles.length), v);
      Utils.getSnakBar(message: 'cars.deleteFailed'.tr, type: TosterTypes.failed);
      return;
    }
    if (wasDefault && vehicles.isNotEmpty) {
      vehicles.first.isDefault = true;
      try {
        await _db.saveVehicle(vehicles.first);
      } catch (e) {
        dev.log('[CarsController] Error moving default car: $e');
      }
    }
    _db.vehicles.refresh();
    if (Get.currentRoute == Routes.carFormRoute) Get.back();
  }

  @override
  void onClose() {
    plateCode.dispose();
    plateDigits.dispose();
    yearController.dispose();
    super.onClose();
  }
}
