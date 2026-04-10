import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:face_imv/presentation/core/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool filled;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final TextInputFormatter? inputFormatter;
  final TextInputType? textInputType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final int? maxLength;
  final int? maxLines;
  final EdgeInsetsGeometry? contentPadding;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.controller,
    this.onTap,
    this.hintText,
    this.validator,
    this.filled = true,
    this.readOnly = false,
    this.inputFormatter,
    this.textInputType,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.autovalidateMode,
    this.focusNode,
    this.maxLength,
    this.maxLines = 1,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly || onTap != null,
      onTap: onTap,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatter != null ? [inputFormatter!] : [],
      keyboardType: textInputType,
      focusNode: focusNode,
      autovalidateMode: autovalidateMode,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
        letterSpacing: 0.3,
      ),
      decoration: InputDecoration(
        fillColor: AppColors.surface,
        filled: filled,
        hintText: hintText,
        counterText: '',
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        hintStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary.withOpacity(0.6),
        ),
        // Prefix icon
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: prefixIcon,
              )
            : null,
        prefixIconConstraints: prefixIcon != null
            ? BoxConstraints(minWidth: 46.w, minHeight: 46.h)
            : null,
        // Suffix — chevron when tappable, otherwise custom widget
        suffixIcon: onTap != null
            ? Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 22.sp,
                ),
              )
            : suffixIcon,
        suffixIconConstraints: BoxConstraints(minWidth: 46.w, minHeight: 46.h),
        // Borders
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            // When readOnly/tappable, keep subtle border — otherwise show primary
            color: (onTap != null || readOnly)
                ? AppColors.textSecondary.withOpacity(0.25)
                : AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: TextStyle(
          fontSize: 11.sp,
          color: AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
