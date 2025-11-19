import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// StorageServiceをRiverpodで利用するためのプロバイダー
///
/// このプロバイダーはmain.dartで実際のインスタンスに差し替えられます。
/// 直接インスタンスを作らず、プロバイダー経由で取得することで、
/// テストやモックへの置き換えが容易になります。
final storageServiceProvider = Provider<StorageService>((ref) {
  // main.dartでoverridesを使って実際のインスタンスを注入するため、
  // ここに到達した場合はエラーを投げます
  throw UnimplementedError('StorageService must be overridden in main()');
});
