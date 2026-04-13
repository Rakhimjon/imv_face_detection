import 'package:face_imv/presentation/core/app_colors.dart';
import 'package:face_imv/presentation/pages/myid_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF07101D), Color(0xFF0D1B33), Color(0xFF101D2E)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    'Secure Face Verification',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ),
                SizedBox(height: 28.h),
                Text(
                  'Welcome to\nFace_IMV',
                  style: TextStyle(
                    fontSize: 36.sp,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Start with a quick identity check using live face detection, liveness steps, and a guided verification flow.',
                  style: TextStyle(
                    fontSize: 15.sp,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
                SizedBox(height: 28.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF15345F), Color(0xFF0E7AC7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                            child: Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 28.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              'Verification takes about 1 minute',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Prepare your passport details and sit in good lighting before you continue.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 22.h),
                _InfoCard(
                  icon: Icons.document_scanner_rounded,
                  title: 'Step 1',
                  description: 'Enter passport details correctly.',
                ),
                SizedBox(height: 14.h),
                _InfoCard(
                  icon: Icons.face_6_rounded,
                  title: 'Step 2',
                  description: 'Complete live face scan and liveness check.',
                ),
                SizedBox(height: 14.h),
                _InfoCard(
                  icon: Icons.security_rounded,
                  title: 'Step 3',
                  description: 'Review the result instantly on the device.',
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MyIdVerificationPage(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF161616),
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                    child: Text(
                      'Start Verification',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Center(
                  child: Text(
                    'Camera permission will be requested on the next screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
