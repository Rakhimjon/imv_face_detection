import 'dart:convert';

/// This model is used in Blocs to track operation status.
/// It avoids the use of multiple raw booleans for loading, success, and failure.
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

  static const initial = BlocStatus();
  static const loading = BlocStatus(isInitial: false, isLoading: true);
  static const success = BlocStatus(isInitial: false, isSuccess: true);

  factory BlocStatus.fail([String? error]) => BlocStatus(
        isInitial: false,
        isFail: true,
        error: error ?? '',
      );

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
