import 'package:flutter/material.dart';
import 'package:ride_sync/colours.dart';

class MyTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final Widget prefixIcon;
  final void Function()? onPressed;

  const MyTextBox({
    super.key,
    required this.text,
    required this.sectionName,
    required this.onPressed,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // color: const Color(0x6736D69B),
        color: deepGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListTile(
        leading: prefixIcon,
        title: Text(
          sectionName,
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          text,
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          onPressed: onPressed,
          icon: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF026430),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 2, 55, 13).withOpacity(0.3),
                  spreadRadius: 4,
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Icon(
                Icons.edit,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
