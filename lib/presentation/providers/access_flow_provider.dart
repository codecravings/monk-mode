import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/usage_record.dart';

class AccessFlowState {
  final String packageName;
  final String appName;
  final AccessReason? selectedReason;
  final bool isEmergency;

  const AccessFlowState({
    required this.packageName,
    required this.appName,
    this.selectedReason,
    this.isEmergency = false,
  });

  AccessFlowState copyWith({
    AccessReason? selectedReason,
    bool? isEmergency,
  }) =>
      AccessFlowState(
        packageName: packageName,
        appName: appName,
        selectedReason: selectedReason ?? this.selectedReason,
        isEmergency: isEmergency ?? this.isEmergency,
      );
}

class AccessFlowNotifier extends StateNotifier<AccessFlowState?> {
  AccessFlowNotifier() : super(null);

  void startFlow(String packageName, String appName) {
    state = AccessFlowState(packageName: packageName, appName: appName);
  }

  void setReason(AccessReason reason) {
    if (state == null) return;
    state = state!.copyWith(selectedReason: reason);
  }

  void setEmergency() {
    if (state == null) return;
    state = state!.copyWith(isEmergency: true);
  }

  void clearFlow() {
    state = null;
  }
}

final accessFlowProvider =
    StateNotifierProvider<AccessFlowNotifier, AccessFlowState?>((ref) {
  return AccessFlowNotifier();
});
