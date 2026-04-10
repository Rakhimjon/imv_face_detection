---
name: flutter-guidelines
description: Expert Flutter development guidelines for the Xizmat Safari project, covering Clean Architecture, BLoC state management, widget usage, and testing best practices.
---

## 🏗️ Core Architecture (Clean Architecture)

The project is divided into four main layers:

- **lib/domain**: Pure Dart logic. Contains Entities, abstract Facade definitions, and Value Objects. No dependencies on Flutter or Infrastructure.
- **lib/infrastructure**: Implementations of Facades, DTOs (@json_serializable), and API/Local storage providers (Dio, Hive).
- **lib/application**: State management (BLoC/Cubit) and Logic. Uses `freezed` for states and events.
- **lib/presentation**: UI Layer. Contains Pages, Widgets, Styles, and Localization.

---

## 🚦 State Management (BLoC & BlocStatus)

**CRITICAL RULE**: Never use raw booleans (e.g., `isLoading`) in States.
**ALWAYS** use the `BlocStatus` class from `lib/application/bloc_status.dart`.

### Cubit vs Bloc Decision

| Situation | Use |
|---|---|
| Simple state, no events needed | `Cubit` |
| Complex flows, event traceability needed | `Bloc` |
| Advanced event processing (debounce, throttle) | `Bloc` with event transformers |

**Default to `Cubit`. Refactor to `Bloc` only when requirements grow.**

### Event Naming (Bloc only)
- Named in **past tense**: `LoginButtonPressed`, `UserProfileLoaded`.
- Format: `BlocSubject` + optional noun + verb.
- Initial load event: `BlocSubjectStarted` (e.g., `AuthenticationStarted`).
- Base event class: `BlocSubjectEvent`.

### State Approaches

**Primary (this project)**: Use `freezed` + `BlocStatus`:

```dart
@freezed
class MyState with _$MyState {
  const factory MyState.initial({
    @Default(BlocStatus.initial()) BlocStatus status,
    @Default([]) List<DataModel> data,
  }) = _Initial;
}
```

**Alternative reference — Sealed classes** (when states are mutually exclusive with subclass-specific properties):

```dart
@immutable
sealed class LoginState extends Equatable {
  const LoginState();
}
final class LoginInitial extends LoginState { ... }
final class LoginInProgress extends LoginState { ... }
final class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);
  final User user;
}
final class LoginFailure extends LoginState {
  const LoginFailure(this.message);
  final String message;
}
```

**Alternative reference — Single class with status enum** (when many shared properties across states):

```dart
enum LoginStatus { initial, loading, success, failure }

@immutable
class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.errorMessage,
  });
  final LoginStatus status;
  final User? user;
  final String? errorMessage;

  LoginState copyWith({ ... }) => LoginState( ... );
  @override
  List<Object?> get props => [status, user, errorMessage];
}
```

### State Rules (all approaches)
- Extend `Equatable` (or use `freezed`) and include all relevant fields in equality.
- Annotate with `@immutable`.
- Always emit a **new instance**; never reuse the same state object.
- Duplicate states are ignored by bloc — ensure meaningful state changes.

### Event Handling Pattern

```dart
Future<void> _onFetchData(_FetchData event, Emitter<MyState> emit) async {
  emit(state.copyWith(status: BlocStatus.loading()));
  final result = await _facade.fetchData();
  result.fold(
    (error) => emit(state.copyWith(status: BlocStatus.fail(ErrorHelper.errorStr(error)))),
    (data) => emit(state.copyWith(status: BlocStatus.success(), data: data)),
  );
}
```

### Bloc Implementation Rules
- Trigger state changes via `bloc.add(Event())`, not custom public methods.
- Keep event handler methods private (`_onEventName`).
- Only call `emit` inside the Cubit/Bloc.
- Public methods return `void` or `Future<void>` only.
- Keep business logic out of UI.
- No direct bloc-to-bloc communication. Use `BlocListener` in the UI to bridge blocs.
- For shared data, inject the same repository/facade into multiple blocs.

---

## 🧩 Flutter Bloc Widgets

| Widget | Use |
|---|---|
| `BlocProvider` | Provide a bloc to a subtree |
| `MultiBlocProvider` | Provide multiple blocs without nesting |
| `BlocBuilder` | Rebuild UI on state change |
| `BlocListener` | Side effects only (navigation, dialogs, snackbars) |
| `MultiBlocListener` | Listen to multiple blocs without nesting |
| `BlocConsumer` | Rebuild UI + side effects together |
| `BlocSelector` | Rebuild only when a selected slice of state changes |
| `RepositoryProvider` | Provide a repository to the widget tree |

```dart
BlocProvider(
  create: (context) => LoginCubit(context.read<AuthRepository>()),
  child: LoginView(),
);

BlocBuilder<LoginCubit, LoginState>(
  builder: (context, state) {
    return switch (state.status) {
      BlocStatus.loading() => const CircularProgressIndicator(),
      BlocStatus.success() => const HomeView(),
      BlocStatus.fail() => Text(state.status.message ?? 'Error'),
      _ => const LoginForm(),
    };
  },
);

BlocListener<LoginCubit, LoginState>(
  listener: (context, state) {
    if (state.status is BlocStatusFail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.status.message ?? 'Login failed')),
      );
    }
  },
  child: LoginForm(),
);
```

### Context Extension Rules
- Use `context.read<T>()` in callbacks (not in `build`).
- Use `context.watch<T>()` in `build` only when necessary; prefer `BlocBuilder`.
- Never call `context.watch` or `context.select` at the root of `build` — scope with `Builder`.
- Handle **all** possible states in the UI (initial, loading, success, failure).

---

## 🧪 Testing Best Practices

### 1. Unit Testing (Domain & Application)
- **Tooling**: Use `bloc_test` for Blocs/Cubits and `mocktail` for dependency mocking.
- **Pattern**: Follow the **Arrange-Act-Assert (AAA)** pattern.
- **Bloc Tests**: Use `blocTest` to verify state transitions.

```dart
blocTest<MyBloc, MyState>(
  'emits [loading, success] when fetchData succeeds',
  build: () => MyBloc(mockFacade),
  act: (bloc) => bloc.add(const MyEvent.fetch()),
  expect: () => [
    state.copyWith(status: BlocStatus.loading()),
    state.copyWith(status: BlocStatus.success(), data: mockData),
  ],
);
```

- Always call `tearDown(() => cubit.close())`.
- Use `group()` named after the class under test.
- Name test cases with "should" to describe expected behavior.
- Register fallback values for custom types: `registerFallbackValue(FakeMyEvent())`.

### 2. Widget Testing (Presentation)
- **Isolation**: Test widgets as standalone components.
- **Initialization**: Always wrap with `ScreenUtilInit` and `MaterialApp` if the widget depends on them.
- **Interactions**: Use `tester.tap()` and `tester.pumpAndSettle()` to verify UI changes.

---

## 🎨 UI & Styling Rules

- **Responsiveness**: Use `flutter_screenutil` extensions (`.w`, `.h`, `.r`, `.sp`).
- **Theming**: Use `context.appColors` extension instead of `Theme.of(context)`.
- **Formatting**: Always use **Trailing Commas** for better branch diffs and formatting.

---

## 🔄 Verification Loop

Before considering a task complete, you MUST:
1. `dart format .` - Ensure consistent code style.
2. `flutter analyze` - Resolve all linting and type errors.
3. `flutter test` - Ensure no regressions in existing logic.
4. Update `part` files if `freezed` or `json_serializable` models changed (run `flutter pub run build_runner build --delete-conflicting-outputs`).

---

## References
- [Bloc Library](https://bloclibrary.dev/)
- [flutter_bloc Package](https://pub.dev/packages/flutter_bloc)
