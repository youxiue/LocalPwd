import 'package:get/get.dart';

import '../controllers/hidden_settings_controller.dart';

class HiddenSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HiddenSettingsController>(() => HiddenSettingsController());
  }
}
