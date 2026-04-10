---
name: flutter-freezed-models
description:  |
  Generate Dart models using Freezed following DDD Clean Architecture patterns
  for the Ochiq budget project. 
license: MIT
---

# Flutter Freezed Models Skill

## Purpose
Generate immutable Freezed models with JSON serialization following project conventions.

## File Naming Convention
**CRITICAL**: Model files MUST end with `_model.dart` for code generation to work!

Example:  `user_model.dart`, `product_model.dart`

## Code Structure

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_name_model.freezed.dart';
part 'model_name_model. g.dart';

@freezed
class ModelName with _$ModelName {
  const factory ModelName({
    @JsonKey(name: 'user_id') @Default(0) int userId,
    @JsonKey(name: 'user_name') @Default('') String userName,
    @Default(false) bool isActive,
    @Default([]) List<String> tags,
    @Default(Status. UNKNOWN) 
    @JsonKey(unknownEnumValue: Status.UNKNOWN) 
    Status status,
  }) = _ModelName;

  factory ModelName.fromJson(Map<String, dynamic> json) => 
      _$ModelNameFromJson(json);
}

enum Status {
  @JsonValue('unknown')
  UNKNOWN,
  @JsonValue('active')
  ACTIVE,
  @JsonValue('inactive')
  INACTIVE,
}
```

## Rules

### Structure
1. Always use `@freezed` annotation
2. Include both `.freezed.dart` and `.g.dart` part files
3. Provide both `const factory` constructor and `fromJson` factory

### Fields
1. **@JsonKey**:  Use when API field name differs from Dart camelCase
    - API: `user_name` → Dart: `@JsonKey(name:  'user_name') String userName`
    - API: `status` → Dart: `String status` (no JsonKey needed)

2. **@Default values are MANDATORY**:
    - String: `@Default('')`
    - int: `@Default(0)`
    - double: `@Default(0.0)`
    - bool: `@Default(false)`
    - List: `@Default([])`
    - Enum: `@Default(EnumName.UNKNOWN)`

3. **Enums**:
    - First value must be `UNKNOWN`
    - Use `@JsonKey(unknownEnumValue: Enum. UNKNOWN)`
    - Use `@JsonValue` for API mapping

### Naming Convention
- Class name: PascalCase (e.g., `UserModel`, `ProductDetail`)
- Fields: camelCase (e.g., `userName`, `productId`)
- File name: snake_case ending with `_model.dart`

### Code Reuse
- If multiple API endpoints return identical JSON structures, create ONE model and reuse it

## Examples

### Simple Model
```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @Default(0) int id,
    @Default('') String name,
    @Default('') String email,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}
```

### Model with API Name Mapping
```dart
@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    @JsonKey(name: 'product_id') @Default(0) int productId,
    @JsonKey(name: 'product_name') @Default('') String productName,
    @JsonKey(name: 'price_usd') @Default(0.0) double priceUsd,
    @Default(true) bool isAvailable,
  }) = _ProductModel;

  factory ProductModel. fromJson(Map<String, dynamic> json) => 
      _$ProductModelFromJson(json);
}
```

### Model with Nested Objects
```dart
@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    @Default(0) int id,
    @Default(UserModel()) UserModel user,
    @Default([]) List<ProductModel> products,
    @Default(0.0) double total,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) => 
      _$OrderModelFromJson(json);
}
```

## After Generation

Run code generation:
```bash
make gen
# or
flutter pub run build_runner build --delete-conflicting-outputs
```

## File Location
Models should be placed in: `lib/infrastructure/models/`