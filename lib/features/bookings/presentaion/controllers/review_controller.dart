import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/order_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/route_argument_stack.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/services/washup_db_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/utils/utils.dart';

class ReviewController extends GetxController with RouteArgumentStack {
  final _orders = OrderService();
  final commentController = TextEditingController();

  final stars = 0.obs;
  final tags = <String>[].obs;
  final sending = false.obs;
  final error = RxnString();

  /// The visit being rated; loaded from the server when it is not cached
  /// (a review push for an older order, GAP-038).
  final order = Rxn<OrderModel>();
  final loading = false.obs;

  /// Why the order could not be loaded.
  final loadError = RxnString();

  static const tagKeys = ['clean', 'fast', 'staff', 'value'];

  WashUpDbService get _db => Get.find<WashUpDbService>();

  String get orderId => activeArgument.value;

  String get branchName => order.value == null ? '' : (_db.branch(order.value!.branchId)?.name.value ?? '');

  @override
  void onInit() {
    super.onInit();
    initArgument(Get.arguments?.toString());
    load();
  }

  @override
  void onArgumentChanged() {
    stars.value = 0;
    tags.clear();
    commentController.clear();
    error.value = null;
    order.value = null;
    load();
  }

  Future<void> load() async {
    final id = orderId;
    if (id.isEmpty) return;
    order.value = _db.order(id);
    loadError.value = null;
    loading.value = true;
    try {
      // The cached copy may be missing or out of date (still "in service").
      await _db.refreshOrder(id, throwOnError: true);
      final fresh = _db.order(id);
      if (fresh != null) {
        if (_db.branch(fresh.branchId) == null) await _db.fetchBranchDetails(fresh.branchId);
        // Already rated on another device: submit says so instead of failing.
        await _db.fetchOrderReview(id);
      }
      if (id != orderId) return;
      order.value = fresh;
      if (fresh == null) loadError.value = 'review.unavailable'.tr;
    } catch (e) {
      if (id != orderId) return;
      if (order.value == null) loadError.value = ApiException.messageFor(e, fallback: 'review.unavailable'.tr);
    } finally {
      if (id == orderId) loading.value = false;
    }
  }

  void setStars(int v) {
    stars.value = v;
    error.value = null;
  }

  void toggleTag(String t) => tags.contains(t) ? tags.remove(t) : tags.add(t);

  Future<void> submit() async {
    final o = order.value;
    // Never a silent no-op: say why the review cannot be sent.
    if (o == null) {
      Utils.getSnakBar(message: loadError.value ?? 'review.unavailable'.tr, type: TosterTypes.failed);
      return;
    }
    if (o.status != OrderStatus.completed) {
      Utils.getSnakBar(message: 'review.notCompleted'.tr, type: TosterTypes.warning);
      return;
    }
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
