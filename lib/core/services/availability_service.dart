import 'package:get/get.dart';

import '../../commons/models/branch_model.dart';
import '../enums/enums.dart';
import '../helpers/format_helper.dart';
import 'carzone_db_service.dart';

class SlotModel {
  final DateTime start;
  final int free;

  const SlotModel(this.start, this.free);

  bool get fewLeft => free == 1;
}

class AvailabilityService {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  static const _active = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.waiting,
    OrderStatus.inService,
  ];

  bool isOpenNow(BranchModel branch, [DateTime? now]) {
    final ref = now ?? DateTime.now();
    final day = branch.hoursFor(ref);
    if (day.closed || !branch.bookable) return false;
    final mins = ref.hour * 60 + ref.minute;
    return mins >= FormatHelper.clockToMinutes(day.open) &&
        mins < FormatHelper.clockToMinutes(day.close);
  }

  bool isClosedDay(BranchModel branch, DateTime day) => branch.hoursFor(day).closed;

  int _overlapping(String branchId, DateTime start, DateTime end, String? excludeId) {
    return _db.orders.where((o) {
      if (o.branchId != branchId || o.id == excludeId) return false;
      if (!_active.contains(o.status)) return false;
      return o.scheduledAt.isBefore(end) && o.endsAt.isAfter(start);
    }).length;
  }

  List<SlotModel> slotsFor(
    BranchModel branch,
    DateTime day, {
    int durationMin = 30,
    String? excludeOrderId,
  }) {
    if (!branch.bookable) return const [];
    final hours = branch.hoursFor(day);
    if (hours.closed) return const [];
    final now = DateTime.now();
    final earliest = now.add(Duration(minutes: branch.settings.leadTimeMin));
    final open = FormatHelper.clockToMinutes(hours.open);
    final close = FormatHelper.clockToMinutes(hours.close);
    final base = DateTime(day.year, day.month, day.day);
    final result = <SlotModel>[];
    for (var m = open; m + durationMin <= close; m += branch.settings.slotIntervalMin) {
      final start = base.add(Duration(minutes: m));
      if (start.isBefore(earliest)) continue;
      final end = start.add(Duration(minutes: durationMin));
      final used = _overlapping(branch.id, start, end, excludeOrderId);
      final free = branch.capacity - used;
      if (free > 0) result.add(SlotModel(start, free));
    }
    return result;
  }

  bool isAvailable(BranchModel branch, DateTime start, int durationMin, {String? excludeOrderId}) {
    return slotsFor(branch, start, durationMin: durationMin, excludeOrderId: excludeOrderId)
        .any((s) => s.start == start);
  }

  List<SlotModel> nextSlots(BranchModel branch, {int count = 3, int durationMin = 30}) {
    final today = DateTime.now();
    for (var i = 0; i <= branch.settings.maxAdvanceDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final slots = slotsFor(branch, day, durationMin: durationMin);
      if (slots.isNotEmpty) return slots.take(count).toList();
    }
    return const [];
  }

  DateTime? nextSlot(BranchModel branch) {
    final list = nextSlots(branch, count: 1);
    return list.isEmpty ? null : list.first.start;
  }
}
