import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/utils/utils.dart';

class ReviewController extends GetxController {
  final _orders = OrderService();
  final commentController = TextEditingController();

  final stars = 0.obs;
  final tags = <String>[].obs;
  final sending = false.obs;
  final error = RxnString();

  static const tagKeys = ['clean', 'fast', 'staff', 'value'];

  OrderModel? order;

  WashUpDbService get _db => Get.find<WashUpDbService>();

  String get branchName => order == null ? '' : (_db.branch(order!.branchId)?.name.value ?? '');

  @override
  void onInit() {
    super.onInit();
    order = _db.order(Get.arguments?.toString() ?? '');
  }

  void setStars(int v) {
    stars.value = v;
    error.value = null;
  }

  void toggleTag(String t) => tags.contains(t) ? tags.remove(t) : tags.add(t);

  Future<void> submit() async {
    final o = order;
    if (o == null || o.status != OrderStatus.completed) return;
    if (stars.value == 0) {
      error.value = 'review.need'.tr;
      return;
    }
    // Saving needs the server, so it must not start offline.
    if (!ConnectivityService.online) {
      Utils.getSnakBar(message: 'offline.action'.tr, type: TosterTypes.warning);
      return;
    }
    // One review per visit.
    if (_db.reviews.any((r) => r.orderId == o.id)) {
      Get.back();
      Utils.getSnakBar(message: 'review.already'.tr, type: TosterTypes.warning);
      return;
    }
    sending.value = true;
    try {
      await _orders.review(o, stars.value, tags.toList(), commentController.text.trim());
    } catch (e) {
      Utils.getSnakBar(message: ApiException.messageFor(e, fallback: 'review.failed'.tr), type: TosterTypes.failed);
      return;
    } finally {
      sending.value = false;
    }
    Get.back();
    Utils.getSnakBar(message: 'review.done'.tr, type: TosterTypes.sucsses);
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
