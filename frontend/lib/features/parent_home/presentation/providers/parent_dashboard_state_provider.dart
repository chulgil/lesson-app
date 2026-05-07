import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parent_dashboard_state_provider.g.dart';

/// Selected child provider for parent dashboard
@Riverpod(keepAlive: true)
class SelectedChildId extends _$SelectedChildId {
  @override
  String? build() => null;

  @override
  // ignore: invalid_use_of_visible_for_testing_member
  String? get state => super.state;

  @override
  // ignore: invalid_use_of_visible_for_testing_member
  set state(String? value) => super.state = value;
}
