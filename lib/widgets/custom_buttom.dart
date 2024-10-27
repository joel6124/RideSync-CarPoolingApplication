import 'package:flutter/material.dart';
import '../colours.dart';

class CustomButton extends StatelessWidget {
  final String txt;
  final Function()? onTap;
  const CustomButton({super.key, required this.txt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          margin: EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: deepGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              txt,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )),
    );
  }
}
