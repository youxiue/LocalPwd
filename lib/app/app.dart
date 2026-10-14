import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'routes.dart';
import 'bindings.dart';
import '../core/services/lock_service.dart';
import '../core/services/secure_window_service.dart';

class LocalPwdApp extends StatefulWidget {
  const LocalPwdApp({super.key});

  @override
  State<LocalPwdApp> createState() => _LocalPwdAppState();
}

class _LocalPwdAppState extends State<LocalPwdApp> {
  @override
  void initState() {
    super.initState();
    LockService.instance.init();
    SecureWindowService.instance.apply();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '密码管理',
      debugShowCheckedModeBanner: false,
      theme: () {
        final cs = ColorScheme.fromSeed(
          seedColor: const Color(0xFF37BC6E),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF37BC6E),
        );
        return ThemeData(
          useMaterial3: true,
          colorScheme: cs,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.white,
            foregroundColor: cs.onSurface,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            contentTextStyle: TextStyle(
              fontSize: 14,
              color: cs.onSurface,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
          ),
        );
      }(),
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.unlock,
      getPages: AppRoutes.pages,
      builder: (context, child) {
        return Obx(() => Stack(
              children: [
                child!,
                if (LockService.instance.isMasked.value)
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/icon/app_icon.png', width: 80, height: 80),
                          const SizedBox(height: 16),
                          Text(
                            '密码管理',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ));
      },
    );
  }
}
