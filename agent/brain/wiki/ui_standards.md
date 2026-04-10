# 🎨 UI & Styling Standards (Semantic Core)

## 📍 Responsiveness: ScreenUtil

To ensure the UI looks consistent across different screen sizes (iOS/Android), we use `flutter_screenutil`.

### Core Rules:
1.  **Width/Height**: Use `.w` and `.h` (e.g., `Container(width: 100.w, height: 50.h)`).
2.  **Font Size**: Always use `.sp` (e.g., `fontSize: 14.sp`).
3.  **Radius**: Use `.r` for corners.

---

## 🌈 Color Palette (Tokens)

We use a centralized `AppColors` system with support for Light/Dark modes (currently primary focus on Light).

### Core Tokens:
- **Primary**: `0xFF155EEF` (Action buttons, highlights).
- **Background**:
  - `bgPrimary`: `0xFFFFFFFF` (Main page background).
  - `bgTertiary`: `0xFFF5F5F5` (Subtle sections).
- **Text**:
  - `textPrimary`: `0xFF181D27` (Headlines/Main text).
  - `textTertiary`: `0xFF535862` (Subtitles/Secondary).
  - `textDisabled`: `0xFF717680` (Hints).
- **Status**:
  - `error`: `0xFFD92D20`.
  - `success`: `0xFF079455`.
  - `warning`: `0xFFF79009`.

**Usage**:
```dart
color: context.appColors.primary
```

---

## ✍️ Typography

We use **Inter** (via Google Fonts) as our primary typeface.

### Style Naming Convention:
Styles are categorized by weight (400-900) and type (regular, medium, semibold, bold).

- `AppTextStyles.regular400`: Standard body text.
- `AppTextStyles.semibold600`: Strong headers or button text.
- `AppTextStyles.bold700`: Main headlines.

---

## 🔗 References
- [Architecture Wiki](./architecture.md)
- [State Management Wiki](./state_management.md)
