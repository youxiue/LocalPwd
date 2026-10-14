import 'package:get/get.dart';

import '../controllers/unlock_controller.dart';

class UnlockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UnlockController>(() => UnlockController());
  }
}
