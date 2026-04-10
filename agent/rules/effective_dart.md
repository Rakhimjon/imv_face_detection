# Effective Dart — Quick Reference Rules

Condensed Effective Dart rules for quick enforcement during coding tasks.
Full details in `.agent/skills/effective-dart/SKILL.md`.

---

## Naming

| Kind | Convention | Example |
|---|---|---|
| Classes, enums, typedefs | `UpperCamelCase` | `UserProfile`, `BlocStatus` |
| Files, directories, packages | `lowercase_with_underscores` | `user_profile.dart` |
| Variables, functions, parameters | `lowerCamelCase` | `userName`, `fetchData()` |
| Acronyms > 2 letters | Capitalize like words | `HttpRequest`, not `HTTPRequest` |

## Types

- **Always** annotate return types, parameter types, and uninitialized variables.
- **Never** use `dynamic` — use explicit types.
- Use `Future<void>` for async members that produce no value.

## Style

- Format with `dart format .` — never manually format.
- Use **curly braces** for all flow control statements.
- Prefer `final` over `var`; use `const` for compile-time constants.
- **Trailing commas** on all multi-line arguments (mandatory in this project).

## Imports

- **Prefer relative imports** within the package.
- Don't import from `src/` of another package.
- Don't use `/lib/` or `../` in import paths.

## Documentation

- Use `///` doc comments for public APIs.
- Start with a **single-sentence summary**.
- Start function docs with a **third-person verb** (e.g., "Returns the user…").
- Start boolean docs with **"Whether"** (e.g., "Whether the user is authenticated.").
- Reference identifiers with `[identifier]` syntax.
