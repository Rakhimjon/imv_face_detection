---
name: flutter-facade
description:  |
  Generate Dart Facade using following DDD Clean Architecture patterns
  for the Ochiq budget mobile project. 
license: MIT
---

# Flutter facade skills

## Overview
This skill generates Dart facades following Domain-Driven Design (DDD) and Clean Architecture patterns for the Ochiq Budget mobile application. Facades serve as the interface layer between the application layer and the domain layer.

## Architecture Pattern

### Directory Structure
```
lib/
  domain/
    facades/
      auth/
        auth_facade.dart
      profile/
        profile_facade.dart
      [feature]/
        [feature]_facade.dart
```

### Facade Pattern
Facades in this project follow these conventions:

1. **Abstract Interface**: Defined as abstract classes with method signatures
2. **Either Return Type**: Uses `dartz` package's `Either<dynamic, T>` for error handling
3. **Async Operations**: All methods return `Future` for asynchronous operations
4. **Caching Support**: Include `cached` parameter where applicable (default: `true`)
5. **Named Parameters**: Use named parameters for required fields

## Template Structure

```dart
import 'package:dartz/dartz.dart';

abstract class [Feature]Facade {
  // Get methods - retrieve data
  Future<Either<dynamic, List<Model>>> get[Feature]s({bool cached = true});
  
  Future<Either<dynamic, Model>> get[Feature]ById({
    required int id,
    bool cached = true,
  });

  // Create methods
  Future<Either<dynamic, Model>> create[Feature]({
    required ModelInput model,
  });

  // Update methods
  Future<Either<dynamic, Model>> update[Feature]({
    required int id,
    required ModelInput model,
  });

  // Delete methods
  Future<Either<dynamic, bool>> delete[Feature]({
    required int id,
  });

  // Search/Filter methods
  Future<Either<dynamic, List<Model>>> search[Feature]({
    required String query,
    bool cached = false,
  });
}
```

## Key Principles

### 1. Error Handling
- Use `Either<dynamic, T>` where:
  - `Left` (dynamic): Contains error information
  - `Right` (T): Contains success data

### 2. Caching Strategy
- Add `cached` parameter for GET operations
- Default to `true` for cached data
- Set to `false` for real-time data needs

### 3. Parameters
- Use `required` for mandatory fields
- Use named parameters for better readability
- Include optional parameters with default values

### 4. Naming Conventions
- Facade name: `[Feature]Facade`
- File name: `[feature]_facade.dart`
- Methods: `get`, `create`, `update`, `delete`, `search`, `verify`, `check`

## Example: Auth Facade

```dart
import 'package:dartz/dartz.dart';
import 'package:open_budget_2/domain/models/auth/token_model.dart';
import 'package:open_budget_2/domain/models/auth/captcha_model.dart';

abstract class AuthFacade {
  // Captcha operations
  Future<Either<dynamic, CaptchaModel>> getCaptcha();

  // Login flow
  Future<Either<dynamic, OtpKeyModel>> sendOTP({
    required String captchaKey,
    required int captchaResult,
    required String phone,
  });

  Future<Either<dynamic, TokenModel>> verifyOTP({
    required String phone,
    required String smsCode,
    required String otpKey,
  });

  // Token management
  Future<Either<dynamic, TokenModel>> refreshToken();
}
```

## Usage Examples

### Creating a New Facade

**Step 1**: Create feature directory
```
lib/domain/facades/[feature]/
```

**Step 2**: Create facade file
```dart
// lib/domain/facades/skills/skills_facade.dart
import 'package:dartz/dartz.dart';

abstract class SkillsFacade {
  Future<Either<dynamic, List<SkillModel>>> getSkills({bool cached = true});
  
  Future<Either<dynamic, SkillModel>> getSkillById({
    required int skillId,
    bool cached = true,
  });
  
  Future<Either<dynamic, SkillModel>> addSkill({
    required SkillInputModel skillData,
  });
  
  Future<Either<dynamic, SkillModel>> updateSkill({
    required int skillId,
    required SkillInputModel skillData,
  });
  
  Future<Either<dynamic, bool>> deleteSkill({
    required int skillId,
  });
}
```

**Step 3**: Implement in infrastructure layer
```dart
// lib/infrastructure/repositories/skills_repository.dart
class SkillsRepositoryImpl implements SkillsFacade {
  @override
  Future<Either<dynamic, List<SkillModel>>> getSkills({bool cached = true}) async {
    // Implementation here
  }
  
  // ... other implementations
}
```

## Best Practices

1. **Keep facades thin**: Facades should only define interfaces, not implement logic
2. **Single Responsibility**: Each facade should handle one domain area
3. **Consistent return types**: Always use `Either<dynamic, T>` for error handling
4. **Document complex operations**: Add comments for non-obvious method behaviors
5. **Import models properly**: Always import domain models, not infrastructure models
6. **Version control**: Keep facades stable; breaking changes affect multiple layers

## Common Facade Methods

### Data Retrieval
- `get[Resource]s()` - Get list of resources
- `get[Resource]ById()` - Get single resource
- `search[Resource]()` - Search/filter resources

### Data Manipulation
- `create[Resource]()` - Create new resource
- `update[Resource]()` - Update existing resource
- `delete[Resource]()` - Delete resource

### Specialized Operations
- `verify[Resource]()` - Verification operations
- `upload[Resource]()` - File uploads
- `check[Resource]()` - Validation checks
- `refresh[Resource]()` - Refresh/reload operations

## Dependencies

Required packages in `pubspec.yaml`:
```yaml
dependencies:
  dartz: ^0.10.1  # For Either type
```

## Integration Points

Facades integrate with:
1. **Application Layer (BLoC)**: Business logic components call facade methods
2. **Infrastructure Layer**: Repository implementations of facades
3. **Domain Models**: Type-safe data structures returned by facades
4. **Dependency Injection**: Facades registered in DI container

## Testing Facade Implementations

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockSkillsFacade extends Mock implements SkillsFacade {}

void main() {
  late MockSkillsFacade mockFacade;

  setUp(() {
    mockFacade = MockSkillsFacade();
  });

  test('getSkills returns list of skills', () async {
    // Arrange
    when(mockFacade.getSkills()).thenAnswer(
      (_) async => Right([SkillModel(id: 1, name: 'Flutter')]),
    );

    // Act
    final result = await mockFacade.getSkills();

    // Assert
    expect(result.isRight(), true);
  });
}
```

## Checklist for New Facades

- [ ] Create directory: `lib/domain/facades/[feature]/`
- [ ] Create abstract class with appropriate name
- [ ] Import `dartz` for `Either` type
- [ ] Import relevant domain models
- [ ] Define all CRUD operations as needed
- [ ] Add `cached` parameter to GET methods
- [ ] Use named, required parameters
- [ ] Add documentation comments
- [ ] Implement in infrastructure layer
- [ ] Register in dependency injection
- [ ] Create unit tests

## Related Documentation

- Domain Models: `lib/domain/models/`
- Infrastructure: `lib/infrastructure/repositories/`
- Dependency Injection: `lib/di.dart`
- Application Layer: `lib/application/`
