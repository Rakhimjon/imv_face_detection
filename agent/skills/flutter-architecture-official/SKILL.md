---
name: flutter-architecture-official
description: Provides official Flutter app architecture best practices, including layered architecture, data flow, state management patterns, and extensibility guidelines. Use when structuring new features, designing repositories, or deciding on data flow patterns.
---

# Flutter Architecture (Official) Skill

This skill provides comprehensive guidelines for structuring Flutter applications using layered architecture, proper data flow, and best practices for maintainability and testability.
Sourced from [docs.flutter.dev/app-architecture](https://docs.flutter.dev/app-architecture).

---

## Architecture Layers

1. Separate features into a **UI Layer** (presentation), a **Data Layer** (business data and logic), and optionally a **Domain (Logic) Layer** between them for complex business logic.
2. Organize code **by feature** (e.g., `auth/`, `profile/`) or by type, or use a hybrid approach.
3. Only allow communication between **adjacent layers** — UI should not access the Data layer directly.
4. Introduce a Logic/Domain Layer only for complex business logic that doesn't fit cleanly in UI or Data layers.
5. Clearly define responsibilities, boundaries, and interfaces of each layer and component.

---

## Component Responsibilities

### UI Layer
- **Views**: Describe how to present data to the user; keep logic minimal and UI-related only.
- **ViewModels/BLoCs**: Contain logic to convert app data into UI state. Maintain current state. Expose callbacks (commands) to Views. Retrieve and transform data from repositories.

### Data Layer
- **Repositories**: Single Source of Truth (SSOT) for model data. Handle business logic such as caching, error handling, and refreshing. Transform raw data from services into domain models.
- **Services**: Wrap API endpoints. Expose asynchronous response objects. Isolate data-loading. Hold no state.

---

## Data Flow and State

1. Follow **unidirectional data flow**: state flows from Data → Logic → UI, events flow from UI → Logic → Data.
2. Data changes should always happen in the **SSOT (data layer)**, not in UI or Logic layers.
3. Only the SSOT class (usually the repository) should be able to **mutate its data**.
4. UI should always reflect the **current (immutable) state**; trigger rebuilds only in response to state changes.
5. Views should contain as little logic as possible and be driven by state from ViewModels/BLoCs.

---

## Use Cases / Interactors

1. Introduce use cases/interactors in the domain layer **only when logic is complex**, reused, or merges data from multiple repositories.
2. Use cases depend on repositories and may be used by multiple view models.
3. Add use cases only when needed; refactor to use them exclusively if logic is repeatedly shared across view models.

---

## Extensibility and Testability

1. All architectural components should have **well-defined inputs and outputs** (interfaces).
2. Favor **dependency injection** to allow swapping implementations without changing consumers.
3. Test view models by mocking repositories; test UI logic independently of widgets.
4. Design components to be easily **replaceable and independently testable**.

---

## Best Practices

| Area | Practice |
|---|---|
| Architecture | Separation of concerns, layered architecture |
| Dependencies | Dependency injection for testability and flexibility |
| Pattern | MVVM as default, adapt as needed for complexity |
| Storage | Key-value for simple data, SQL for complex relationships |
| UX | Optimistic updates for perceived responsiveness |
| Offline | Combine local and remote data sources in repositories |
| Widgets | `StatelessWidget` when possible, `const` constructors |
| State | Keep state as local as possible to minimize rebuilds |
| Performance | Avoid expensive operations in build methods, implement pagination |
| Files | Single responsibility, `final` fields, `private` declarations |
| Naming | Follow Dart naming conventions |
| Types | Prefer explicit typing on public APIs |
| Immutability | `abstract class` with `const` constructors for small domain models |
| Constants | Descriptive constant names (e.g., `_todoTableName` over `_kTableTodo`) |

---

## References
- [Flutter App Architecture](https://docs.flutter.dev/app-architecture)
- [Flutter App Architecture Case Study](https://docs.flutter.dev/app-architecture/case-study)
