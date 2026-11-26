// GAP-062: the wash page reads reviews through branch_reviews(), which never returns the order or customer id.
// Those rows must not erase what "my reviews" already loaded, or the rate prompts would reappear.
import 'package:flutter_test/flutter_test.dart';
import 'package:washup/commons/models/review_model.dart';

import 'qa_helpers.dart';

void main() {
  test('a public review row keeps the order and customer of the cached own review', () {
    final db = freshDb();
    db.upsertReviews([
      ReviewModel.fromJson({
        'id': 'rev_1',
        'order_id': 'or_1',
        'customer_id': 'cu_1',
        'branch_id': 'br_1',
        'stars': 4,
        'comment': {'ar': 'جيد', 'en': 'Good'},
        'created_at': '2026-11-20T10:00:00Z',
      }),
    ]);

    db.upsertReviews([
      ReviewModel.fromJson({
        'id': 'rev_1',
        'branch_id': 'br_1',
        'stars': 4,
        'comment': {'ar': 'جيد', 'en': 'Good'},
        'reply': 'شكرًا',
        'created_at': '2026-11-20T10:00:00Z',
      }),
    ]);

    final r = db.reviews.single;
    expect(r.orderId, 'or_1');
    expect(r.customerId, 'cu_1');
    expect(r.reply, 'شكرًا');
  });

  test('a review that is not cached yet is added as it comes', () {
    final db = freshDb();
    db.upsertReviews([
      ReviewModel.fromJson({'id': 'rev_2', 'branch_id': 'br_1', 'stars': 5, 'comment': '', 'created_at': '2026-11-21T10:00:00Z'}),
    ]);
    expect(db.reviews.single.orderId, isNull);
  });
}
