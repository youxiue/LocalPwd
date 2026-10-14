import 'package:get/get.dart';

import '../controllers/hidden_category_controller.dart';

class HiddenCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HiddenCategoryController>(() => HiddenCategoryController());
  }
}
