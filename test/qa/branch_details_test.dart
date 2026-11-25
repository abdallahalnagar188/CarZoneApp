// GAP-016: hours, amenities and photos come from the branch's related tables
// (never a made-up 09:00-22:00); GAP-033: ratings are the database aggregates.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/commons/models/branch_model.dart';
import 'package:washup/core/services/availability_service.dart';
import 'package:washup/core/services/discovery_service.dart';
import 'package:washup/core/services/session_service.dart';

import 'qa_helpers.dart';

Map<String, dynamic> _row({bool related = true}) => {
      'id': 'br_1',
      'business_id': 'biz_1',
      'name': {'ar': 'مغسلة', 'en': 'Wash'},
      'area_id': 'nasr',
      'address': {'ar': '', 'en': ''},
      'lat': 30.0,
      'lng': 31.0,
      'phone': '0100',
      'capacity': 3,
      'active': true,
      'rating': 4.3,
      'review_count': 40,
      if (related) ...{
        'branch_working_hours': [
          {'weekday': 0, 'opens_at': '09:00:00', 'closes_at': '22:00:00', 'closed': false},
          {'weekday': 1, 'opens_at': '09:00:00', 'closes_at': '22:00:00', 'closed': false},
          {'weekday': 2, 'opens_at': '09:00:00', 'closes_at': '22:00:00', 'closed': false},
          {'weekday': 3, 'opens_at': '09:00:00', 'closes_at': '22:00:00', 'closed': false},
          {'weekday': 4, 'opens_at': '18:00:00', 'closes_at': '02:00:00', 'closed': false},
          {'weekday': 5, 'opens_at': '09:00:00', 'closes_at': '22:00:00', 'closed': true},
          // No Saturday row: closed, as the booking RPCs treat it.
        ],
        'branch_amenities': [
          {'amenity_id': 'wifi', 'amenities': {'name': {'ar': 'واي فاي', 'en': 'Wi-Fi'}}},
          {'amenity_id': 'retired', 'amenities': null},
        ],
        'branch_photos': [
          {'storage_path': 'br_1/b.jpg', 'position': 2},
          {'storage_path': 'https://cdn.example.com/a.jpg', 'position': 1},
        ],
      },
    };

// 2030-01-06 is a Sunday.
DateTime _day(int weekday) => DateTime(2030, 1, 6 + weekday);

void main() {
  test('hours come from branch_working_hours; missing and closed days are closed', () {
    final b = BranchModel.fromJson(_row());
    expect(b.hoursKnown, isTrue);
    expect(b.hoursFor(_day(0)).open, '09:00');
    expect(b.hoursFor(_day(0)).close, '22:00');
    expect(b.hoursFor(_day(5)).closed, isTrue, reason: 'Friday closed in the portal');
    expect(b.hoursFor(_day(6)).closed, isTrue, reason: 'no Saturday row');
  });

  test('a branch row without related tables has unknown hours, never 09:00-22:00', () {
    final b = BranchModel.fromJson(_row(related: false));
    expect(b.hoursKnown, isFalse);
    expect(b.hoursFor(_day(0)).closed, isTrue);
    expect(b.amenities, isEmpty);
    expect(b.photos, isEmpty);
  });

  test('a discover row keeps the related rows already loaded', () {
    final full = BranchModel.fromJson(_row());
    final bare = BranchModel.fromJson(_row(related: false));
    final merged = BranchModel.keepRelated(bare, full);
    expect(merged.hoursKnown, isTrue);
    expect(merged.amenities, ['wifi']);
    expect(BranchModel.keepRelated(full, bare).hoursKnown, isTrue);
    expect(bare.withRelated(_row()).hoursKnown, isTrue);
  });

  test('amenities switched off by the platform are left out; names are kept', () {
    final b = BranchModel.fromJson(_row());
    expect(b.amenities, ['wifi']);
    expect(b.amenityNames['wifi']?.en, 'Wi-Fi');
  });

  test('photos are in position order, storage paths become public URLs', () {
    final b = BranchModel.fromJson(_row());
    expect(b.photos.first, 'https://cdn.example.com/a.jpg');
    expect(b.photos.last, endsWith('/storage/v1/object/public/branch-photos/br_1/b.jpg'));
  });

  test('hours past midnight close the next day', () {
    final b = BranchModel.fromJson(_row());
    final thursday = b.hoursFor(_day(4));
    expect(thursday.openMin, 18 * 60);
    expect(thursday.closeMin, 26 * 60);
    freshDb();
    final svc = AvailabilityService();
    // Thursday 23:00 and Friday 01:00 are open; Friday 03:00 is not.
    expect(svc.isOpenNow(b, DateTime(2030, 1, 10, 23)), isTrue);
    expect(svc.isOpenNow(b, DateTime(2030, 1, 11, 1)), isTrue);
    expect(svc.isOpenNow(b, DateTime(2030, 1, 11, 3)), isFalse);
  });

  test('ratings are the database aggregates; unrated washes are not 5.0', () {
    final db = freshDb();
    Get.put(SessionService());
    final rated = BranchModel.fromJson(_row(related: false));
    final unrated = BranchModel.fromJson({..._row(related: false), 'id': 'br_2', 'rating': 0, 'review_count': 0});
    db.branches.addAll([rated, unrated]);
    final discovery = DiscoveryService();
    final r = discovery.decorate(rated);
    expect(r.rating, 4.3);
    expect(r.reviewCount, 40);
    final u = discovery.decorate(unrated);
    expect(u.rating, 0);
    expect(u.reviewCount, 0);
    Get.reset();
  });
}
