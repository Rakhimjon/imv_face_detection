import 'package:face_imv/presentation/pages/myid_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_imv/application/camera_state.dart';
import 'package:face_imv/application/face_detection_state.dart';
import 'package:face_imv/injection.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        return MaterialApp(
          title: 'Face_IMV',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.indigo,
            useMaterial3: true,
          ),
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => getIt<CameraCubit>()..initialize(),
              ),
              BlocProvider(create: (context) => getIt<FaceDetectionCubit>()),
            ],
            child: const MyIdVerificationPage(),
          ),
        );
      },
    );
  }
}
