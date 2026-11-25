// GAP-069: no made-up local slots when the server cannot answer, and clocks
// change at local midnight (not UTC midnight).
import 'package:flutter_test/flutter_test.dart';
import 'package:washup/core/services/availability_service.dart';

import 'qa_helpers.dart';

void main() {
  test('a failed get_branch_slots call is an error, not local slots', () async {
    freshDb();
    // No Supabase in unit tests: the RPC fails like a lost connection.
    await expectLater(
      AvailabilityService().fetchRemoteSlots(branchFixture(), futureDay()),
      throwsA(anything),
    );
  });

  test('Egypt summer time starts at 00:00 local on the last Friday of April', () {
    // 2026: last Friday of April is the 24th; 00:00 UTC+2 = 22:00 UTC on the 23rd.
    expect(BranchTimeHelper.cairoOffset(DateTime.utc(2026, 4, 23, 21, 59)), const Duration(hours: 2));
    expect(BranchTimeHelper.cairoOffset(DateTime.utc(2026, 4, 23, 22)), const Duration(hours: 3));
  });

  test('Egypt summer time ends at 24:00 local on the last Thursday of October', () {
    // 2026: last Thursday of October is the 29th; 24:00 UTC+3 = 21:00 UTC.
    expect(BranchTimeHelper.cairoOffset(DateTime.utc(2026, 10, 29, 20, 59)), const Duration(hours: 3));
    expect(BranchTimeHelper.cairoOffset(DateTime.utc(2026, 10, 29, 21)), const Duration(hours: 2));
  });

  test('Lebanon changes at local midnight on the last Sundays of March and October', () {
    // 2026: 29 March and 25 October are the last Sundays.
    expect(BranchTimeHelper.offsetFor('Asia/Beirut', DateTime.utc(2026, 3, 28, 21, 59)), const Duration(hours: 2));
    expect(BranchTimeHelper.offsetFor('Asia/Beirut', DateTime.utc(2026, 3, 28, 22)), const Duration(hours: 3));
    expect(BranchTimeHelper.offsetFor('Asia/Beirut', DateTime.utc(2026, 10, 24, 20, 59)), const Duration(hours: 3));
    expect(BranchTimeHelper.offsetFor('Asia/Beirut', DateTime.utc(2026, 10, 24, 21)), const Duration(hours: 2));
  });

  test('fixed-offset zones are unaffected', () {
    expect(BranchTimeHelper.offsetFor('Asia/Riyadh', DateTime.utc(2026, 7, 1)), const Duration(hours: 3));
    expect(BranchTimeHelper.offsetFor('Asia/Dubai', DateTime.utc(2026, 1, 1)), const Duration(hours: 4));
  });
}
