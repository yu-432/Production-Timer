import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'storage_provider.dart';

final appSettingsProvider = Provider<AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.settings;
});
