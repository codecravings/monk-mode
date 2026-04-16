import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_storage.dart';

final storageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});
