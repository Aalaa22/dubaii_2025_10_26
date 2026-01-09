import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:advertising_app/constant/string.dart'; // تأكد من استيراد هذا الملف

class CustomTextField extends StatefulWidget {
  final String? hintText;
  final bool isPassword;
  final TextDirection? textDirection;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;

  const CustomTextField({
    this.hintText,
    this.isPassword = false,
    this.textDirection,
    super.key,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      textDirection: widget.textDirection,
      
      // --- هنا هو الإصلاح ---
      // تحديد ستايل النص الذي يكتبه المستخدم
      style: TextStyle(
        color: KTextColor, // اللون المطلوب
        fontSize: 15.sp,
        fontWeight: FontWeight.w500,
      ),
      // --------------------

      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Color.fromRGBO(129, 126, 126, 1),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color.fromRGBO(8, 194, 201, 1),
                ),
                onPressed: () => setState(() { _obscureText = !_obscureText; }),
              )
            : null,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}