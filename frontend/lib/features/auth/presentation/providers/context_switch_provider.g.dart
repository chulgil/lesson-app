// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'context_switch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contextSwitchRepositoryHash() =>
    r'1a7ced5c31570a5675011f3fc8ffb744a2024221';

/// Context switch repository — mock vs remote based on runtime data mode.
///
/// Remote: `academy_context.py` (GET /auth/context, POST /auth/context/switch).
///
/// Copied from [contextSwitchRepository].
@ProviderFor(contextSwitchRepository)
final contextSwitchRepositoryProvider =
    Provider<ContextSwitchRepository>.internal(
  contextSwitchRepository,
  name: r'contextSwitchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contextSwitchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ContextSwitchRepositoryRef = ProviderRef<ContextSwitchRepository>;
String _$currentContextHash() => r'32bd78b6bd3955526feba93e28a62d6fe38d82ca';

/// Current context + the contexts the user can toggle into (GET /auth/context).
///
/// Returns null callers nothing special — UI hides the toggle when
/// [ContextInfo.canToggle] is false (single-context users).
///
/// Copied from [currentContext].
@ProviderFor(currentContext)
final currentContextProvider = AutoDisposeFutureProvider<ContextInfo>.internal(
  currentContext,
  name: r'currentContextProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentContextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentContextRef = AutoDisposeFutureProviderRef<ContextInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
