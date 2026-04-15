import 'package:face_imv/injection.dart';
import 'package:face_imv/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:face_imv/presentation/core/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'application/camera_state.dart';
import 'application/face_detection_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencyInjection();
  runApp(const FaceAnalyzerApp());
}

class FaceAnalyzerApp extends StatelessWidget {
  const FaceAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 13 size
      minTextAdapt: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => getIt<CameraCubit>()),
            BlocProvider(create: (context) => getIt<FaceDetectionCubit>()),
          ],
          child: MaterialApp(
            title: 'Face_IMV',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}
