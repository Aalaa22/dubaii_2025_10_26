import 'package:flutter/material.dart';
import '../../constant/string.dart';

class CustomElevatedButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onpress;

  const CustomElevatedButton({super.key, this.text, this.onpress});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.06, // ✅ ارتفاع نسبي حسب الشاشة
      child: ElevatedButton(
        onPressed: onpress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: KTextColor,
          side: const BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: KTextColor,
            ),
          ),
        ),
      ),
    );
  }
}


// class CustomElevatedButton extends StatelessWidget {
//   CustomElevatedButton({this.text, this.onpress});
//   String? text;
//   VoidCallback? onpress;
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onpress!,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.white,
//         foregroundColor: KTextColor,
//         side: BorderSide(color: Color.fromRGBO(8, 194, 201, 1)),
//         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//       child: Text(text!),
//     );
//   }
// }
