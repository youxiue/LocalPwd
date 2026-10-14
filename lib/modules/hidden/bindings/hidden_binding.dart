import 'package:get/get.dart';

import '../controllers/hidden_controller.dart';

class HiddenBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true —— 控制器被路由销毁后，Get.find 能自动重建，避免 "not found" 崩溃
    Get.lazyPut<HiddenController>(() => HiddenController(), fenix: true);
  }
}
