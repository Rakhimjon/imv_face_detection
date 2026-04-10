# 🧠 Xizmat Safari - Development Brain (Wiki v2)

Welcome to the **Development Brain** of the Xizmat Safari mobile project. This system is designed for **Knowledge Compounding**, ensuring that structural decisions and complex logic are preserved and evolved.

---

## 🏛️ Semantic Memory (Core Wiki)
Stable principles and structural laws.

- **[🏗️ Architecture](./brain/wiki/architecture.md)**: Clean Architecture breakdown & Dependency Flow.
- **[🚦 State Management](./brain/wiki/state_management.md)**: `BlocStatus`, Error Handling, and BLoC patterns.
- **[🎨 UI & Styling](./brain/wiki/ui_standards.md)**: Design Tokens, Typography, and ScreenUtil standards.

---

## 📚 Episodic Memory (Case Studies)
Detailed context for complex technical implementations.

- **[🔐 001: OneID SSO Integration](./brain/episodic/001_oneid_sso_integration.md)**: OAuth2, PKCE, and WebView lessons.
- **[🌍 002: Localization Workflow](./brain/episodic/002_localization_workflow.md)**: Type-safe translations with Words enum.

---

## 🛠️ Procedural Memory (Meta)
- **[🧠 Brain Schema](./brain/schema/brain_schema.md)**: Rules for contributing and updating this brain.

---

## 🔄 Verification Loop (The "Mobile Ritual")
To ensure the brain and the code stay in sync, follow this loop for every feature:

1. **Format**: `dart format .`
2. **Analyze**: `flutter analyze`
3. **Test**: `flutter test`
4. **Build**: `flutter pub run build_runner build --delete-conflicting-outputs`
5. **Brain**: **Synthesize insights** into the relevant Wiki or Episode.

