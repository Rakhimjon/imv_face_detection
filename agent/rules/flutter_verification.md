# Flutter Development Verification Rules

To ensure high-quality code and project consistency, the following verification loop MUST be executed before finishing any Flutter development task.

## 🔄 The Verification Loop

### 1. Formatting
Run `dart format .` to ensure all files follow the standard Dart style.
> [!TIP]
> Always use Trailing Commas in Flutter widgets for better formatting and git diffs.

### 2. Static Analysis
Run `flutter analyze` to catch potential bugs, linting issues, and type mismatches.
> [!IMPORTANT]
> Do NOT ignore lint warnings unless absolutely necessary and documented with `// ignore: <lint_rule>`.

### 3. Unit and Widget Testing
Run `flutter test` to ensure no regression in business logic or UI behavior.
- Ensure all Blocs/Cubits have corresponding `blocTest` cases.
- Mock all external dependencies (Facades, APIs) using `mocktail`.

### 4. Code Generation
If any files with `@freezed` or `@JsonSerializable` annotations were modified, run:
`flutter pub run build_runner build --delete-conflicting-outputs`

## 🧪 Testing Best Practices

### Unit Tests (Domain & Application)
- **Arrange**: Set up mocks and dependencies using `mocktail`.
- **Act**: Execute the function or add an event to the Bloc.
- **Assert**: Verify the result or expected states using `expect`.

### Widget Tests (Presentation)
- Always initialize `ScreenUtil` if the widget uses it.
- Use `pumpAndSettle()` to wait for animations and state updates.
