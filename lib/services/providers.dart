import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import 'data_service.dart';
import '../models/category.dart';
import '../models/business.dart';
import '../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance);
final dataServiceProvider = Provider<DataService>((ref) => DataService.instance);

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  try {
    return await ref.watch(authServiceProvider).fetchMe();
  } catch (_) {
    return null;
  }
});

final categoriesProvider = FutureProvider<List<AppCategory>>((ref) async {
  return ref.watch(dataServiceProvider).getCategories();
});

final businessesProvider = FutureProvider<List<Business>>((ref) async {
  return ref.watch(dataServiceProvider).getBusinesses();
});

final searchQueriesProvider = StateProvider<String>((ref) => '');

final mainShellIndexProvider = StateProvider<int>((ref) => 0);

final selectedCategoryNameProvider = StateProvider<String?>((ref) => null);

final filteredBusinessesProvider = Provider<AsyncValue<List<Business>>>((ref) {
  final businessesAsync = ref.watch(businessesProvider);
  final query = ref.watch(searchQueriesProvider).toLowerCase();

  return businessesAsync.whenData((businesses) {
    if (query.isEmpty) return businesses;
    return businesses.where((b) {
      return b.name.toLowerCase().contains(query) ||
          b.categoryName.toLowerCase().contains(query);
    }).toList();
  });
});
