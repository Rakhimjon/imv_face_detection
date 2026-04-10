name: flutter-repository
description: A Flutter repository skill for managing facades and models.
license: MIT
--- 
# Flutter Repository Skill  
## Purpose  

This skill provides a structured approach to managing facades and models in a Flutter application, following best practices for repository patterns.

## File Naming Convention  
**CRITICAL**: Repository files MUST end with `_repository.dart` for consistency and clarity!
Example: `user_repository.dart`, `product_repository.dart`  
## Code Structure  
```dart


import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import '../../domain/auth_facade.dart';
import '../../domain/common/failure.dart';
import '../../presentation/routes/routes.dart';
import '../../presentation/routes/routes_text.dart';
import '../api/api_base.dart';
import '../storage/auth_pref.dart';

class AuthRepository implements AuthFacade {
  final ApiBase _base;

  final AuthPreferences pref;

  const AuthRepository(this._base, this.pref);

  @override
  Future<Either<ResponseFailure, bool>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _base.dio.post(
        '/auth/refresh',
        // options: Options(headers: {'Authorization': refreshToken}),
      );

      await pref.saveAuth(response.data['content']['access_token'] as String);
      // await pref.saveRefreshToken(response.data['content']['refresh_token'] as String);

      rootNavigatorKey.currentContext?.go(RouteText.splash);

      return right(true);
    } on DioException catch (e) {
      // debugPrint(e.response?.statusCode.toString() ?? '');
      // if(e.response?.statusCode == 401){
      //   await pref.clearDb();
      // }
      debugPrint('Error refreshing token: repo ${e.message}');
      await pref.clearDb();

      return left(Unknown(message: 'unknown_error'.tr()));
    } catch (e) {
      debugPrint('Error refreshing token: repo catch ${e.toString()}');

      return left(Unknown(message: 'unknown_error'.tr()));
    }
  }

  @override
  Future<Either<ResponseFailure, bool>> sendFcmToken({
    required String token,
  }) async {
    try {
      await _base.dio.post('/auth/firebase', data: {'f_token': token});

      return right(true);
    } on DioException catch (_) {
      return left(Unknown(message: 'unknown_error'.tr()));
    } catch (e) {
      return left(Unknown(message: 'unknown_error'.tr()));
    }
  }


}

```## Explanation  
- **Imports**: The necessary packages and modules are imported, including Dio for HTTP requests, Easy Localization for translations, and FPDart for functional programming constructs.  
- **Class Definition**: The `AuthRepository` class implements the `AuthFacade` interface, providing concrete implementations
    for authentication-related operations.
- **Constructor**: The constructor takes an instance of `ApiBase` for making API calls and `AuthPreferences` for managing authentication preferences.
