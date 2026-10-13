import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/utils/utils.dart';

class ReportController extends GetxController {
  final _orders = OrderService();
  final descriptionController = TextEditingController();

  final category = 'quality'.obs;
  final sending = false.obs;
  final error = RxnString();

  static const categories = ['quality', 'pricing', 'booking', 'behavior', 'refund', 'other'];

  OrderModel? order;

  @override
  void onInit() {
    super.onInit();
    order = Get.find<CarzoneDbService>().order(Get.arguments?.toString() ?? '');
  }

  void setCategory(String c) => category.value = c;

  Future<void> submit() async {
    final o = order;
    if (o == null) return;
    if (descriptionController.text.trim().length < 20) {
      error.value = 'report.min'.tr;
      return;
    }
    error.value = null;
    sending.value = true;
    final ticket = await _orders.report(o, category.value, descriptionController.text.trim());
    sending.value = false;
    Get.back();
    Utils.getSnakBar(
      message: '${'report.done'.tr} · ${'report.ticket'.trParams({'n': ticket})}',
      type: TosterTypes.sucsses,
    );
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
