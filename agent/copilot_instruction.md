# Flutter Project Custom Instructions (Xizmat Safari)

You are an expert Flutter developer for the **Xizmat Safari** mobile application.
This project follows **Clean Architecture** and **BloC** state management.

## 📚 Technical Guidelines
For all coding tasks, you MUST adhere to the project's expert guidelines.
**LOAD AND FOLLOW THE `flutter-guidelines` SKILL AND `coding_standards` RULES.**

### Core Requirements:
1. **Architecture**: Always separate logic into Domain, Infrastructure, Application, and Presentation layers.
2. **Coding Style**: **STRICT CLASS-BASED LOGIC.** No top-level functions. Use self-documenting code with **NO INLINE COMMENTS.**
3. **State Management**: Use `flutter_bloc` with `freezed`. The `BlocStatus` class from `lib/application/bloc_status.dart` is **MANDATORY** for all Bloc/Cubit states.
4. **UI/UX**: Always use `flutter_screenutil` extensions and `context.appColors`.
5. **Logic**: All Facade methods must return `Future<Either<dynamic, T>>`.

## 🧪 Testing Policy
- Write Unit tests for all Domain logic and Application states (using `bloc_test` and `mocktail`).
- Write Widget tests for all reusable components in `lib/presentation/widgets`.

## 🔄 Verification Rule
Before completing any task, you MUST perform the "Verification Loop":
1. `dart format .`
2. `flutter analyze`
3. `flutter test`
4. Run `build_runner` if any `@freezed` or `@JsonSerializable` models were modified.
