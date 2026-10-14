import 'package:get/get.dart';

import '../controllers/entry_edit_controller.dart';

class EntryEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntryEditController>(() => EntryEditController());
  }
}
