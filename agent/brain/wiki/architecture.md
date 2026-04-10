# 🏗️ Architecture (Semantic Core)

## 🎯 Rationale: Why Clean Architecture?

We use a layered **Clean Architecture** to ensure that our business logic (Domain) remains pure and independent of external frameworks (Flutter), databases, or UI details. This allows for:
1.  **Framework Independence**: We can swap components or upgrade libraries with minimal risk to the core logic.
2.  **Testability**: Each layer can be tested in isolation using mocks for its dependencies.
3.  **Scalability**: New features can be added by following established patterns without "polluting" existing layers.

---

## 🧩 The Four Layers

### 1. Domain Layer (`lib/domain/`)
**The most stable layer.** Contains the "Truth" of the application.
- **Entities**: Plain Dart objects representing business models.
- **Value Objects**: Objects with built-in validation (e.g., `EmailAddress`, `Password`).
- **Facades (Abstract)**: Interfaces for external actions (API, Auth, Storage).
- **Failures**: Definition of business-level errors.
- **DEPENDENCY**: none.

### 2. Infrastructure Layer (`lib/infrastructure/`)
**The implementation layer.** Connects the application to the outside world.
- **DTOs (Data Transfer Objects)**: Models with `@json_serializable` for API parsing.
- **Facade Implementations**: Concrete logic for API calls using `Dio`, LocalStorage using `Hive`, etc.
- **Mappers**: Logic to convert DTOs (Infrastructure) <-> Entities (Domain).
- **DEPENDENCY**: Domain.

### 3. Application Layer (`lib/application/`)
**The orchestration layer.** Manages state and logic flow.
- **BLoCs/Cubits**: Uses `flutter_bloc` and `freezed` to manage state transitions.
- **BlocStatus**: A standardized way to track loading, success, and failure.
- **DEPENDENCY**: Domain, Infrastructure (via injection).

### 4. Presentation Layer (`lib/presentation/`)
**The interaction layer.** Everything the user sees and touches.
- **Pages**: Top-level route containers.
- **Widgets**: Reusable UI components.
- **Styles/Theming**: `AppColors`, `AppStyles`, and `ScreenUtil` integration.
- **DEPENDENCY**: Application, Domain.

---

## 🚦 Dependency Flow Rule

> [!IMPORTANT]
> **Dependencies MUST only point inwards.**
> Presentation -> Application -> Domain <- Infrastructure
> 
> *Domain should NEVER depend on any other layer.*

---

## 🔗 References
- [Brain Schema](../schema/brain_schema.md)
- [State Management Wiki](./state_management.md)
