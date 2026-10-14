import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../modules/unlock/bindings/unlock_binding.dart';
import '../modules/unlock/views/unlock_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/hidden/bindings/hidden_binding.dart';
import '../modules/hidden/views/hidden_home_view.dart';
import '../modules/hidden/category/bindings/hidden_category_binding.dart';
import '../modules/hidden/category/views/hidden_category_view.dart';
import '../modules/hidden/settings/bindings/hidden_settings_binding.dart';
import '../modules/hidden/settings/views/hidden_settings_view.dart';
import '../modules/hidden/entry_edit/bindings/hidden_entry_edit_binding.dart';
import '../modules/hidden/entry_edit/views/hidden_entry_edit_view.dart';
import '../modules/entry_edit/bindings/entry_edit_binding.dart';
import '../modules/entry_edit/views/entry_edit_view.dart';
import '../modules/category/bindings/category_binding.dart';
import '../modules/category/views/category_view.dart';
import '../modules/generator/bindings/generator_binding.dart';
import '../modules/generator/views/generator_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

abstract class AppRoutes {
  static const unlock = AppConstants.routeUnlock;
  static const home = AppConstants.routeHome;
  static const entryEdit = AppConstants.routeEntryEdit;
  static const categoryManage = AppConstants.routeCategoryManage;
  static const generator = AppConstants.routePasswordGenerator;
  static const settings = AppConstants.routeSettings;
  static const hidden = AppConstants.routeHidden;
  static const hiddenSettings = AppConstants.routeHiddenSettings;
  static const hiddenEntryEdit = AppConstants.routeHiddenEntryEdit;
  static const hiddenCategoryManage = AppConstants.routeHiddenCategoryManage;

  static final pages = [
    GetPage(
      name: unlock,
      page: () => const UnlockView(),
      binding: UnlockBinding(),
    ),
    GetPage(
      name: home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: entryEdit,
      page: () => const EntryEditView(),
      binding: EntryEditBinding(),
    ),
    GetPage(
      name: categoryManage,
      page: () => const CategoryView(),
      binding: CategoryBinding(),
    ),
    GetPage(
      name: generator,
      page: () => const GeneratorView(),
      binding: GeneratorBinding(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: hidden,
      page: () => const HiddenHomeView(),
      binding: HiddenBinding(),
    ),
    GetPage(
      name: hiddenSettings,
      page: () => const HiddenSettingsView(),
      binding: HiddenSettingsBinding(),
    ),
    GetPage(
      name: hiddenEntryEdit,
      page: () => const HiddenEntryEditView(),
      binding: HiddenEntryEditBinding(),
    ),
    GetPage(
      name: hiddenCategoryManage,
      page: () => const HiddenCategoryView(),
      binding: HiddenCategoryBinding(),
    ),
  ];
}
