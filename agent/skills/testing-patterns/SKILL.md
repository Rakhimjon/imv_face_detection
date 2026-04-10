---
name: testing-patterns
description: Testing patterns and principles. Unit, integration, mocking strategies. Use when writing unit tests, widget tests, or reviewing existing tests for correctness, structure, and naming conventions.
---

# Testing Patterns

> Principles for reliable test suites.

---

## 0. Test Validity (MANDATORY)

> **Before writing or accepting a test, ask: "Can this test actually fail if the real code is broken?"**

- Avoid tests that only confirm mocked/fake behavior that doesn't reflect real logic.
- Avoid tests that confirm behavior guaranteed by the language or trivially obvious code.
- Every test should be capable of catching a **real regression**.

---

## 1. Testing Pyramid

```
        /\          E2E (Few)
       /  \         Critical flows
      /----\
     /      \       Integration (Some)
    /--------\      API, DB queries
   /          \
  /------------\    Unit (Many)
                    Functions, classes
```

---

## 2. AAA Pattern

| Step | Purpose |
|------|---------|
| **Arrange** | Set up test data |
| **Act** | Execute code under test |
| **Assert** | Verify outcome |

---

## 3. Test Structure (MANDATORY)

Always use `group()` in test files — even when there is only one test. Name the group after the **class under test**:

```dart
group('Counter', () {
  test('should start at 0', () {
    final counter = Counter();
    expect(counter.value, 0);
  });
});
```

---

## 4. Naming Convention (MANDATORY)

Name test cases using **"should"** to clearly describe the expected behavior:

```dart
test('should emit updated list when item is added', () { ... });
test('should throw ArgumentError when input is negative', () { ... });
test('should return error when network fails', () { ... });
```

---

## 5. Test Type Selection

| Type | Best For | Speed |
|------|----------|-------|
| **Unit** | Pure functions, BLoC logic | Fast (<50ms) |
| **Integration** | API, DB, services | Medium |
| **E2E** | Critical user flows | Slow |

---

## 6. Unit Test Principles

### Good Unit Tests

| Principle | Meaning |
|-----------|---------|
| Fast | < 100ms each |
| Isolated | No external deps |
| Repeatable | Same result always |
| Self-checking | No manual verification |
| Timely | Written with code |

### What to Unit Test

| Test | Don't Test |
|------|------------|
| Business logic | Framework code |
| Edge cases | Third-party libs |
| Error handling | Simple getters |

---

## 7. Mocking Principles

### When to Mock

| Mock | Don't Mock |
|------|------------|
| External APIs | The code under test |
| Database (unit) | Simple dependencies |
| Time/random | Pure functions |
| Network | In-memory stores |

### Mock Types

| Type | Use |
|------|-----|
| Stub | Return fixed values |
| Spy | Track calls |
| Mock | Set expectations |
| Fake | Simplified implementation |

**Decision**: Prefer Real > Fake > Mock (see `mocktail-testing` skill for details).

---

## 8. Test Organization

### Grouping

| Level | Use |
|-------|-----|
| `group` | Group by class under test |
| `test` / `blocTest` | Individual case |
| `setUp` / `tearDown` | Common setup/cleanup |

### BLoC Test Pattern

```dart
group('MyBloc', () {
  late IMyFacade mockFacade;
  late MyBloc bloc;

  setUp(() {
    mockFacade = MockMyFacade();
    bloc = MyBloc(mockFacade);
  });

  tearDown(() => bloc.close());

  blocTest<MyBloc, MyState>(
    'should emit [loading, success] when fetch succeeds',
    build: () {
      when(() => mockFacade.fetchData())
          .thenAnswer((_) async => right(mockData));
      return bloc;
    },
    act: (bloc) => bloc.add(const MyEvent.fetch()),
    expect: () => [
      state.copyWith(status: BlocStatus.loading()),
      state.copyWith(status: BlocStatus.success(), data: mockData),
    ],
  );
});
```

---

## 9. Test Data

| Approach | Use |
|----------|-----|
| Factories | Generate test data |
| Fixtures | Predefined datasets |
| Builders | Fluent object creation |

- Use realistic data
- Randomize non-essential values (faker)
- Share common fixtures
- Keep data minimal

---

## 10. Best Practices

| Practice | Why |
|----------|-----|
| One assert per test | Clear failure reason |
| Independent tests | No order dependency |
| Fast tests | Run frequently |
| Descriptive names | Self-documenting |
| Clean up | Avoid side effects |
| Always `tearDown` blocs | Prevent resource leaks |

---

## 11. Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| Test implementation | Test behavior |
| Duplicate test code | Use factories |
| Complex test setup | Simplify or split |
| Ignore flaky tests | Fix root cause |
| Skip cleanup | Reset state |
| Only test happy path | Cover error cases |

---

> **Remember:** Tests are documentation. If someone can't understand what the code does from the tests, rewrite them.
