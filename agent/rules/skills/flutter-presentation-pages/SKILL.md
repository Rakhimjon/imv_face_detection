---
name: flutter-presentation-pages
description: A Flutter presentation pages skill for building UI components.
license: MIT
---     
# # Flutter Presentation Page Skill 

# Using style appColors and app text styles ,app icons and screenUtils and words 

## Code Structure
```dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markab/core/common/words.dart';
import 'package:markab/presentation/routes/path.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:markab/presentation/widgets/custom_button.dart';
import 'package:markab/presentation/styles/styles_importer.dart';

class SelectLanguagePage extends StatefulWidget {
  const SelectLanguagePage({super.key});

  @override
  State<SelectLanguagePage> createState() => _SelectLanguagePageState();
}

class _SelectLanguagePageState extends State<SelectLanguagePage> {
  selectLanguage(Locale locale) async {
    await context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcons.icAppLogo,
                  15.horizontalSpace,
                  AppIcons.icMarkab.copyWith(
                    colorFilter: ColorFilter.mode(
                      colors.fgPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
            64.verticalSpace,
            Text(
              Words.selectInterfaceLanguage.tr(),
              style: AppTextStyles.bold700.copyWith(
                fontSize: 26.sp,
                color: colors.textPrimary,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            11.verticalSpace,
            Text(
              Words.selectInterfaceLangDes.tr(),
              style: AppTextStyles.regular400.copyWith(
                color: colors.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
            44.verticalSpace,
            LanguageTile(
              title: "O`zbek tili",
              icon: AppIcons.icUZ,
              isSelected: context.locale.languageCode == 'uz',
              onTap: () {
                selectLanguage(const Locale('uz', 'UZB'));
                setState(() {});
              },
            ),
            LanguageTile(
              title: "Русский язык",
              icon: AppIcons.icRU,
              isSelected: context.locale.languageCode == 'ru',
              onTap: () {
                selectLanguage(const Locale('ru', 'RUS'));
                setState(() {});
              },
            ),
            LanguageTile(
              title: "English language",
              icon: AppIcons.icGB,
              isSelected: context.locale.languageCode == 'en',
              onTap: () {
                selectLanguage(const Locale('en', 'US'));
                setState(() {});
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
        child: CustomButton(
          title: Words.continueE.tr(),
          icon: AppIcons.icArrowRight,
          onTap: () => context.go(RoutePath.onboard),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class LanguageTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Widget icon;
  final VoidCallback onTap;

  const LanguageTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        margin: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? colors.borderBrand : Colors.transparent,
            width: 1.sp,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.medium500.copyWith(
                  fontSize: 16.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}



