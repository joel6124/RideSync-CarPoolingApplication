import 'package:flutter/material.dart';
import 'package:ride_sync/authentication/auth_service.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/widgets/custom_buttom.dart';
import 'package:ride_sync/widgets/custom_textfield.dart';

const List<String> gender_cat = <String>['Male', 'Female'];

class RegisterGooglePage extends StatefulWidget {
  const RegisterGooglePage(
      {super.key,
      required this.name,
      required this.email,
      required this.photoUrl,
      required this.uid});
  final String name;
  final String email;
  final String photoUrl;
  final String uid;

  @override
  State<RegisterGooglePage> createState() => _RegisterGooglePageState();
}

class _RegisterGooglePageState extends State<RegisterGooglePage> {
  String dropdownValue = gender_cat.first;

  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  String genderSelected = "Male";

  final _formkey = GlobalKey<FormState>();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formkey,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Image.asset(
                    "assets/google.png",
                    width: double.maxFinite,
                    height: 150,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Register With Google!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      controller: nameController,
                      obscureText: false,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(5)),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: lightGreen,
                            ),
                          ),
                          enabled: false,
                          fillColor: Color.fromARGB(255, 227, 231, 221),
                          filled: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextField(
                      controller: emailController,
                      obscureText: false,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(5)),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: lightGreen,
                            ),
                          ),
                          enabled: false,
                          fillColor: Color.fromARGB(255, 227, 231, 221),
                          filled: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    context: context,
                    controller: phoneController,
                    hintText: "Phone Number",
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: dropdownValue,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValue = newValue!;
                              genderSelected = dropdownValue;
                            });
                          },
                          items: gender_cat
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    txt: 'Register With Google',
                    onTap: () async {
                      await _authService.registerUserWithGoogle(
                        context,
                        nameController.text,
                        emailController.text,
                        phoneController.text,
                        genderSelected,
                        widget.photoUrl,
                        widget.uid,
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
