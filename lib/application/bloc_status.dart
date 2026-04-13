import 'dart:convert';

/// This mode is used in Blocs to know variable's status.
/// If you need to use to know success, loading, fail
///
/// Examples:
/// [in state]
/// ```dart
/// @freezed
/// class LocationState with _$LocationState {
///   const factory LocationState.initial({
///     @Default(VarStatus()) BlocStatus statusPosition,
///     Position? position,
///   }) = _Initial;
/// }
/// ```
/// [To emit in bloc]
/// ```dart
/// emit(state.copyWith(statusPosition: BlocStatus())); // initial
/// emit(state.copyWith(statusPosition: BlocStatus.loading()));
/// emit(state.copyWith(statusPosition: BlocStatus.success()));
/// emit(state.copyWith(statusPosition: BlocStatus.fail()));
/// ```

class BlocStatus {
  final bool isInitial;
  final bool isSuccess;
  final bool isLoading;
  final bool isFail;
  final String error;

  const BlocStatus({
    this.isInitial = true,
    this.isSuccess = false,
    this.isLoading = false,
    this.isFail = false,
    this.error = '',
  });

  factory BlocStatus.initial() => const BlocStatus();

  factory BlocStatus.loading() =>
      const BlocStatus(isInitial: false, isLoading: true);

  factory BlocStatus.fail([String? error]) =>
      BlocStatus(isInitial: false, isFail: true, error: error ?? '');

  factory BlocStatus.success() =>
      const BlocStatus(isInitial: false, isSuccess: true);

  @override
  String toString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
    "isInitial": isInitial,
    "isSuccess": isSuccess,
    "isLoading": isLoading,
    "isFail": isFail,
    "error": error,
  };
}
