# 🚦 State Management (Semantic Core)

## 🏢 Platform: BLoC (Business Logic Component)

We use `flutter_bloc` combined with `freezed` for immutable states and events. This ensures predictable state transitions and easy debugging.

---

## 💎 The `BlocStatus` Standard

**CRITICAL RULE**: Never use raw booleans (like `isLoading`) to track async states. It leads to "Boolean Hell" and missed edge cases.

Always use the `BlocStatus` class from `lib/application/bloc_status.dart`.

### 1. Enum-based tracking
- `initial`: The starting state.
- `loading`: Async operation in progress.
- `success`: Operation completed successfully.
- `fail`: Operation failed (contains an error message).

### 2. Implementation Pattern

```dart
@freezed
class MyState with _$MyState {
  const factory MyState({
    @Default(BlocStatus.initial()) BlocStatus status,
    @Default([]) List<DataModel> data,
  }) = _MyState;
}
```

### 3. Usage in Emitter
```dart
Future<void> _onFetch(_Fetch event, Emitter<MyState> emit) async {
  emit(state.copyWith(status: const BlocStatus.loading()));
  
  final result = await _facade.getData();
  
  result.fold(
    (l) => emit(state.copyWith(status: BlocStatus.fail(ErrorHelper.errorStr(l)))),
    (r) => emit(state.copyWith(status: const BlocStatus.success(), data: r)),
  );
}
```

---

## 🎭 Handling Side Effects (Navigation, Toast)

We follow the principle: **States are for UI rebuilds, Listeners are for side effects.**

1.  **UI Listener**: Use `BlocListener` in the Presentation layer to react to `status.isSuccess` or `status.isFail`.
2.  **Navigation**: Trigger `Navigator.push` inside the `BlocListener`, not in the BLoC.

---

## 🔗 References
- [Architecture Wiki](./architecture.md)
- [UI Standards Wiki](./ui_standards.md)
- [OneID Episodic Case Study](../episodic/001_oneid_sso_integration.md)
