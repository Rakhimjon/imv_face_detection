# Flutter Common Errors — Quick Reference

Quick-fix reference for the most frequent Flutter runtime/layout errors.
Full details in `.agent/skills/flutter-common-errors/SKILL.md`.

---

## Error → Fix Table

| Error | Cause | Fix |
|---|---|---|
| `RenderFlex overflowed by X pixels` | `Row`/`Column` children too wide/tall | Wrap child in `Expanded` or `Flexible` |
| `Vertical viewport was given unbounded height` | `ListView` inside `Column` without bounded height | Wrap `ListView` in `Expanded` or `SizedBox` |
| `InputDecorator cannot have unbounded width` | `TextField` without width constraints | Wrap in `Expanded` inside `Row` |
| `setState() called during build` | `setState`/`showDialog` in `build` | Use `addPostFrameCallback` or user actions |
| `ScrollController attached to multiple scroll views` | Shared `ScrollController` | Create separate instances per scrollable |
| `RenderBox was not laid out` | Missing or unbounded constraints | Add `Expanded`, `SizedBox`, or `ConstrainedBox` |

## Debugging Tips

- Use **Flutter Inspector** (DevTools) to visualize constraints.
- Enable **"Show guidelines"** to see layout boundaries.
- Temporarily add `debugPaintSizeEnabled = true;` in `main()`.
- Read: [Flutter Constraints](https://docs.flutter.dev/ui/layout/constraints).
