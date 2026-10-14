import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<CategoryEntry>> getAll() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Stream<List<CategoryEntry>> watchAll() {
    return (select(categories)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<CategoryEntry?> getById(String id) {
    return (select(categories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> addCategory(CategoriesCompanion c) => into(categories).insert(c);

  Future<bool> updateCategory(CategoriesCompanion c) =>
      (update(categories)..where((t) => t.id.equals(c.id.value)))
          .write(c)
          .then((r) => r > 0);

  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  Future<void> updateSortOrder(List<String> ids) async {
    await batch((b) {
      for (var i = 0; i < ids.length; i++) {
        b.update(
          categories,
          CategoriesCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(ids[i]),
        );
      }
    });
  }
}
