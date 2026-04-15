# Coding Standards & Clean Code Rules

To ensure a premium, maintainable codebase for **  **, the following strict coding standards MUST be followed.

## 🏛️ Class-Based Structure
**Rule**: Prefer classes over top-level functions or variables for all logic, utilities, and constants.

- **Encapsulation**: Group related functional logic into static classes or singletons.
- **Constants**: Use `class AppConstants { static const ... }` instead of top-level constants.
- **Utilities**: Use `class AppUtils { static void ... }` instead of top-level helper functions.

---

## 📖 Self-Documenting Code (No Inline Comments)
**Rule**: Code must be inherently readable. Do NOT use inline comments for logic explanation.

- **Descriptive Naming**: Variables, functions, and classes should have names that clearly explain their purpose (e.g., `isUserAuthenticated` instead of `isAuth`).
- **Complexity**: If code needs a comment to be understood, refactor it into smaller, descriptive methods.
- **Cleanliness**: Avoid "commenting out" code. If it's not used, delete it.

---

## 🚫 No "Sloppy" (Slop) Code
**Rule**: Maintain high technical rigor. Avoid lazy or loosely typed code.

- **Strict Typing**: NEVER use `dynamic`. Always define explicit types for variables and function returns.
- **Null Safety**: Use `late`, `?`, and `!` judiciously. Prefer proper initialization or optional handling over force unwrapping.
- **Error Handling**: Use the `Either<dynamic, T>` pattern for all network and infrastructure calls. Never swallow exceptions.
- **DRY Principle**: Do not repeat logic. Abstract common patterns into reusable components or mixins.

---

## 🎨 Clean Formatting
- **Trailing Commas**: Mandatory for all constructors and multi-line arguments to ensure clean formatting and branch diffs.
- **Consistency**: Follow the project's standard directory structure as defined in `ARCHITECTURE.md`.
