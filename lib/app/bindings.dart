import 'package:get/get.dart';

import '../core/services/auth_service.dart';
import '../core/services/clipboard_service.dart';
import '../core/services/lock_service.dart';
import '../core/services/export_service.dart';
import '../core/services/password_generator_service.dart';
import '../core/storage/database.dart';

/// 全局依赖注入
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // 数据库
    Get.put<AppDatabase>(AppDatabase(), permanent: true);
    // 服务
    Get.put<AuthService>(AuthService.instance, permanent: true);
    Get.put<LockService>(LockService.instance, permanent: true);
    Get.put<ClipboardService>(ClipboardService.instance, permanent: true);
    Get.put<ExportService>(ExportService.instance, permanent: true);
    Get.put<PasswordGeneratorService>(PasswordGeneratorService.instance, permanent: true);
  }
}
