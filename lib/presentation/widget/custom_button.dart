import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  CustomButton({this.text,this.ontap});
  String? text;
   VoidCallback? ontap ;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        
        decoration: BoxDecoration(
            color: Color.fromRGBO(1, 84, 126, 1),
            borderRadius: BorderRadius.circular(8)),
        height: 48,
        width: double.infinity,
        child: Center(
            child: Text(
          text!,
          style: TextStyle(
              color: Colors.white,
               //fontWeight: FontWeight.w500,
                fontSize: 16),
        )),
      ),
    );
  }
}
