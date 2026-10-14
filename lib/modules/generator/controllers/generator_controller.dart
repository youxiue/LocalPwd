import 'package:get/get.dart';

import '../../../core/services/clipboard_service.dart';
import '../../../core/services/password_generator_service.dart';
import '../../../core/utils/app_notification.dart';

class GeneratorController extends GetxController {
  final _generator = PasswordGeneratorService.instance;
  final _clipboard = ClipboardService.instance;

  final length = 16.obs;
  final useLowercase = true.obs;
  final useUppercase = true.obs;
  final useNumbers = true.obs;
  final useSymbols = true.obs;
  final generatedPassword = ''.obs;
  final strength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    generate();
  }

  void generate() {
    final pwd = _generator.generate(
      length: length.value,
      useLowercase: useLowercase.value,
      useUppercase: useUppercase.value,
      useNumbers: useNumbers.value,
      useSymbols: useSymbols.value,
    );
    generatedPassword.value = pwd;
    strength.value = _generator.strength(pwd);
  }

  void copy() {
    if (generatedPassword.value.isEmpty) return;
    _clipboard.copy(generatedPassword.value);
    AppNotification.info('已复制', '将在 30 秒后自动清除');
  }

  void usePassword() {
    if (generatedPassword.value.isNotEmpty) {
      Get.back(result: generatedPassword.value);
    }
  }
}
