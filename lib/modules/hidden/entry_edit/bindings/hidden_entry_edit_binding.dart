import 'package:get/get.dart';

import '../controllers/hidden_entry_edit_controller.dart';

class HiddenEntryEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HiddenEntryEditController>(() => HiddenEntryEditController());
  }
}
