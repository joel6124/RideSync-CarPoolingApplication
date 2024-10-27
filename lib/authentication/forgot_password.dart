import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ride_sync/authentication/auth_service.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/widgets/custom_buttom.dart';
import 'package:ride_sync/widgets/custom_textfield.dart';

class ForgotPassword extends StatelessWidget {
  ForgotPassword({super.key});

  final TextEditingController recoveryEmailController = TextEditingController();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: deepGreen,
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 70,
                ),
                Container(
                  alignment: Alignment.topCenter,
                  child: const Text(
                    'Password Recovery',
                    style: TextStyle(
                        color: titleGrey,
                        fontSize: 19,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                CustomTextField(
                    controller: recoveryEmailController,
                    hintText: "Recovery Email",
                    obscureText: false,
                    context: context),
                const SizedBox(
                  height: 50,
                ),
              ],
            ),
            GestureDetector(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: CustomButton(
                  onTap: () {
                    return _authService.resetPassword(
                        context, recoveryEmailController.text);
                  },
                  txt: 'Send Email',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
