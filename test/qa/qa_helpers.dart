import 'dart:io';

import 'package:carzone/commons/models/branch_model.dart';
import 'package:carzone/commons/models/localized_text.dart';
import 'package:carzone/commons/models/wash_service_model.dart';
import 'package:carzone/core/enums/enums.dart';
import 'package:carzone/core/services/carzone_db_service.dart';
import 'package:get/get.dart';

/// Insert columns of a table, read from the generated Supabase types
/// (supabase/database.types.ts), so tests always check against the real schema.
class TableSchema {
  final Set<String> columns;
  final Set<String> required;

  const TableSchema(this.columns, this.required);
}

Map<String, TableSchema>? _schemaCache;

TableSchema schemaFor(String table) {
  _schemaCache ??= _parseSchema(File('supabase/database.types.ts').readAsLinesSync());
  final s = _schemaCache![table];
  if (s == null) throw StateError('table "$table" not found in database.types.ts');
  return s;
}

Map<String, TableSchema> _parseSchema(List<String> lines) {
  final result = <String, TableSchema>{};
  final tableRe = RegExp(r'^      ([a-z_]+): \{$');
  final colRe = RegExp(r'^          ([a-z_0-9]+)(\??):');
  String? table;
  var inInsert = false;
  var cols = <String>{};
  var req = <String>{};
  for (final line in lines) {
    final t = tableRe.firstMatch(line);
    if (t != null) {
      table = t.group(1);
      continue;
    }
    if (table == null) continue;
    if (line == '        Insert: {') {
      inInsert = true;
      cols = {};
      req = {};
      continue;
    }
    if (inInsert && line == '        }') {
      result[table] = TableSchema(cols, req);
      inInsert = false;
      continue;
    }
    if (inInsert) {
      final c = colRe.firstMatch(line);
      if (c != null) {
        cols.add(c.group(1)!);
        if (c.group(2)!.isEmpty) req.add(c.group(1)!);
      }
    }
  }
  return result;
}

/// Registers a fresh, offline CarzoneDbService (no Supabase calls on startup).
CarzoneDbService freshDb() {
  Get.reset();
  return Get.put(CarzoneDbService());
}

const _ln = LocalizedText('x', 'x');

BranchModel branchFixture({
  String id = 'br_test',
  int capacity = 2,
  List<WorkingDay>? hours,
  BranchSettings settings = const BranchSettings(slotIntervalMin: 30, leadTimeMin: 0, maxAdvanceDays: 7),
  bool active = true,
  bool businessActive = true,
}) {
  return BranchModel(
    id: id,
    businessId: 'biz_test',
    name: _ln,
    areaId: 'nasr',
    address: _ln,
    lat: 30,
    lng: 31,
    phone: '0100',
    amenities: const [],
    capacity: capacity,
    workingHours: hours ?? List.generate(7, (_) => const WorkingDay('09:00', '12:00')),
    photoSeed: 0,
    settings: settings,
    active: active,
    businessActive: businessActive,
  );
}

WashServiceModel serviceFixture({
  required String id,
  String branchId = 'br_test',
  ServiceType type = ServiceType.primary,
  int price = 100,
  int durationMin = 30,
  String category = 'exterior',
}) {
  return WashServiceModel(
    id: id,
    branchId: branchId,
    type: type,
    category: category,
    name: _ln,
    description: _ln,
    price: price,
    durationMin: durationMin,
  );
}

/// A day far enough in the future that lead time never hides slots.
DateTime futureDay([int daysAhead = 2]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + daysAhead);
}
