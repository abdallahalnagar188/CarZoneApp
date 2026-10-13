import 'package:get/get.dart';

import '../enums/enums.dart';
import '../utils/utils.dart';

mixin DataCheckerHelper {
  bool checkText({
    required String text,
    int? minLength,
    required String errorMessage,
  }) {
    if (text.trim().isEmpty ||
        (minLength != null && text.trim().length < minLength)) {
      error(errorMessage.tr);
      return false;
    }
    return true;
  }

  bool checkObject({required dynamic object, required String message}) {
    if (object == null) {
      error(message.tr);
      return false;
    }
    return true;
  }

  void error(String errorMessage) {
    Utils.getSnakBar(message: errorMessage, type: TosterTypes.warning);
  }
}
