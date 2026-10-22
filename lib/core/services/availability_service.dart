import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../commons/models/branch_model.dart';
import '../enums/enums.dart';
import '../helpers/format_helper.dart';
import '../network/api_call.dart';
import 'carzone_db_service.dart';
import 'supabase_service.dart';

class BranchTimeHelper {
  BranchTimeHelper._();

  /// Computes Egypt / Cairo timezone offset for [date] (defaults to current instant).
  /// Egypt DST: Starts last Friday of April, ends last Thursday of October (UTC+3 summer, UTC+2 winter).
  static Duration cairoOffset([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    final year = d.year;

    // Last Friday of April
    var lastFriApril = 30;
    while (DateTime.utc(year, 4, lastFriApril).weekday != DateTime.friday) {
      lastFriApril--;
    }
    final dstStart = DateTime.utc(year, 4, lastFriApril);

    // Last Thursday of October
    var lastThuOct = 31;
    while (DateTime.utc(year, 10, lastThuOct).weekday != DateTime.thursday) {
      lastThuOct--;
    }
    final dstEnd = DateTime.utc(year, 10, lastThuOct, 24);

    final isDst = d.isAfter(dstStart) && d.isBefore(dstEnd);
    return Duration(hours: isDst ? 3 : 2);
  }

  /// Current wall-clock time in Cairo
  static DateTime cairoNow() {
    final utc = DateTime.now().toUtc();
    return utc.add(cairoOffset(utc));
  }

  /// Converts a branch local wall-clock [DateTime] or [slot] to UTC [DateTime]
  static DateTime toUtcDateTime(DateTime slot) {
    if (slot.isUtc) return slot;
    final offset = cairoOffset(slot);
    return DateTime.utc(slot.year, slot.month, slot.day, slot.hour, slot.minute).subtract(offset);
  }

  /// Checks whether [slot] is in the past or within [leadTimeMin] from current instant
  static bool isSlotTooSoon(DateTime slot, int leadTimeMin) {
    final nowUtc = DateTime.now().toUtc();
    final earliestUtc = nowUtc.add(Duration(minutes: leadTimeMin));
    final slotUtc = toUtcDateTime(slot);
    return slotUtc.isBefore(earliestUtc);
  }

  /// Converts a branch local wall-clock [DateTime] or [slot] to exact ISO-8601 UTC string for Supabase RPC
  static String toUtcIsoString(DateTime slot) {
    return toUtcDateTime(slot).toIso8601String();
  }
}

class SlotModel {
  final DateTime start;
  final int free;
  final String? localTime; // e.g. "09:00"

  const SlotModel(this.start, this.free, {this.localTime});

  bool get fewLeft => free == 1;

  /// Every bay is booked at this time.
  bool get full => free <= 0;

  String formattedTime() {
    if (localTime != null && localTime!.contains(':')) {
      final parts = localTime!.split(':');
      final h = int.tryParse(parts[0]) ?? start.hour;
      final m = parts[1];
      final pm = h >= 12;
      final displayH = h % 12 == 0 ? 12 : h % 12;
      return FormatHelper.isAr ? '$displayH:$m ${pm ? 'م' : 'ص'}' : '$displayH:$m ${pm ? 'PM' : 'AM'}';
    }
    return FormatHelper.time(start);
  }
}

class AvailabilityService {
  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  static const _active = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.waiting,
    OrderStatus.inService,
  ];

  static String toUtcIsoString(DateTime slot) => BranchTimeHelper.toUtcIsoString(slot);

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
    bool includeFull = false,
  }) {
    if (!branch.bookable) return const [];
    final hours = branch.hoursFor(day);
    if (hours.closed) return const [];
    final open = FormatHelper.clockToMinutes(hours.open);
    final close = FormatHelper.clockToMinutes(hours.close);
    final result = <SlotModel>[];
    for (var m = open; m + durationMin <= close; m += branch.settings.slotIntervalMin) {
      final slotLocal = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
      final slotUtc = BranchTimeHelper.toUtcDateTime(slotLocal);
      if (BranchTimeHelper.isSlotTooSoon(slotUtc, branch.settings.leadTimeMin)) continue;

      final endUtc = slotUtc.add(Duration(minutes: durationMin));
      final used = _overlapping(branch.id, slotUtc, endUtc, excludeOrderId);
      final free = branch.capacity - used;
      if (free > 0 || includeFull) {
        final hh = (m ~/ 60).toString().padLeft(2, '0');
        final mm = (m % 60).toString().padLeft(2, '0');
        result.add(SlotModel(slotUtc, free > 0 ? free : 0, localTime: '$hh:$mm'));
      }
    }
    return result;
  }

  /// Live remote check against Postgres checking branch operating hours, blocked slots, and existing orders.
  /// Fully booked slots are returned too (free = 0) when [includeFull] is true.
  Future<List<SlotModel>> fetchRemoteSlots(
    BranchModel branch,
    DateTime day, {
    int durationMin = 30,
    String? excludeOrderId,
    bool includeFull = false,
  }) async {
    if (!branch.bookable) return const [];
    try {
      final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final params = {
        'p_branch_id': branch.id,
        'p_date': dateStr,
        'p_duration': durationMin,
        'p_exclude_order': excludeOrderId,
      };
      Future<dynamic> slotsRpc(Map<String, dynamic> p) =>
          ApiCall.read(() => SupabaseService.client.rpc('get_branch_slots', params: p), tag: 'get_branch_slots');
      dynamic res;
      if (includeFull) {
        try {
          res = await slotsRpc({...params, 'p_include_full': true});
        } on PostgrestException catch (e) {
          // Older database without p_include_full: full slots stay hidden.
          if (e.code != 'PGRST202') rethrow;
          res = await slotsRpc(params);
        }
      } else {
        res = await slotsRpc(params);
      }
      if (res is List) {
        final list = res.map((row) {
          final m = Map<String, dynamic>.from(row as Map);
          final startAt = DateTime.parse(m['start_at'].toString()).toUtc();
          final free = (m['free_capacity'] as num?)?.toInt() ?? 1;
          final localTime = m['local_time']?.toString();
          return SlotModel(startAt, free, localTime: localTime);
        }).toList();
        return list;
      }
    } catch (e) {
      dev.log('[AvailabilityService] fetchRemoteSlots RPC failed, using local: $e');
    }
    return slotsFor(branch, day,
        durationMin: durationMin, excludeOrderId: excludeOrderId, includeFull: includeFull);
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
