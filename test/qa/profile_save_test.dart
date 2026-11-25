// GAP-018: "Edit profile" must not claim a name change the server did not save.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/commons/models/customer_model.dart';
import 'package:washup/core/services/session_service.dart';
import 'package:washup/features/profile/presentaion/controllers/profile_controller.dart';

import 'qa_helpers.dart';

void main() {
  test('a name the server did not save stays unchanged locally', () async {
    final db = freshDb();
    final session = Get.put(SessionService());
    final me = CustomerModel(id: 'cu_1', name: 'Old Name', phone: '+201000000000');
    db.customers.add(me);
    session.user.value = me;

    final controller = ProfileController();
    controller.nameController.text = 'New Name';
    // No Supabase in unit tests: the write fails like a refused request.
    await controller.saveName();

    expect(session.user.value!.name, 'Old Name');
    expect(controller.saving.value, isFalse);
    Get.reset();
  });

  test('a too-short name is refused before any request', () async {
    freshDb();
    final session = Get.put(SessionService());
    session.user.value = CustomerModel(id: 'cu_1', name: 'Old Name', phone: '+201000000000');
    final controller = ProfileController();
    controller.nameController.text = 'A';
    await controller.saveName();
    expect(controller.nameError.value, isNotNull);
    expect(session.user.value!.name, 'Old Name');
    Get.reset();
  });
}
