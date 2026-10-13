import 'package:get/get.dart';

import '../../../../commons/models/customer_model.dart';
import '../../../../core/services/carzone_db_service.dart';

class AuthRepo {
  static const String demoOtp = '123456';
  static const String expiredOtp = '000000';

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  Future<void> sendOtp(String phone) async {
    await Future.delayed(const Duration(milliseconds: 450));
  }

  Future<String?> verifyOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (code == expiredOtp) return 'otp.expired';
    if (code != demoOtp) return 'otp.invalid';
    return null;
  }

  CustomerModel? findCustomer(String phone) => _db.customerByPhone(phone);

  Future<CustomerModel> register(String phone, String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _db.registerCustomer(phone, name);
  }
}
