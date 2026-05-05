import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<ProviderObserver> providerObservers() {
  if (!kDebugMode && !kProfileMode) return const [];
  return const [_ProviderLifecycleLogger()];
}

class _ProviderLifecycleLogger extends ProviderObserver {
  const _ProviderLifecycleLogger();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    debugPrint('[Provider] add ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('[Provider] update ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    debugPrint('[Provider] dispose ${provider.name ?? provider.runtimeType}');
  }
}
