# 🌍 Episodic: Localization Workflow (Case Study 002)

## 🎯 Objective
Provide a type-safe, developer-friendly way to handle translations in Uzbek (UZ), Russian (RU), and English (EN).

## 🛠️ The Stack
1.  **easy_localization**: The underlying framework for JSON-based translations.
2.  **Words Enum**: A custom generator/manual enum that maps string keys to Dart objects.
3.  **MyWords Extension**: An extension on the `Words` enum that provides the `.tr()` method.

---

## 🚀 The Workflow

### 1. Define the Key
Add the key (e.g., `loginByOneID`) to the `Words` enum in `lib/core/common/words.dart`.

### 2. Update JSON files
Add the corresponding translation to:
- `assets/translations/uz-UZ.json`
- `assets/translations/ru-RU.json`
- `assets/translations/en-US.json`

### 3. Usage in UI
Instead of using raw strings, use the enum value:
```dart
Text(Words.loginByOneID.tr())
```
*Note: The extension handles the conversion from the enum name to the string key used by easy_localization.*

---

## ⚡ Benefits
- **Type Safety**: No more typos in translation keys.
- **Auto-complete**: IDE makes it easy to find existing translations.
- **Centralization**: All localization keys are managed in one file.

## 🔗 References
- [Architecture Wiki](../wiki/architecture.md)
- [Words.dart](file:///Users/MAC/StudioProjects/xizmat_safari_mobile/lib/core/common/words.dart)
