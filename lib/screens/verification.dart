import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ride_sync/colours.dart';
import 'dart:developer' as dev;

import 'package:ride_sync/screens/profile.dart';

class ProfileVerificationPage extends StatefulWidget {
  const ProfileVerificationPage({super.key});

  @override
  State<ProfileVerificationPage> createState() =>
      _ProfileVerificationPageState();
}

class _ProfileVerificationPageState extends State<ProfileVerificationPage> {
  String imgURL = "";
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<void> uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imgURL = image.path;
      });
    }
  }

  Future<void> verifyUser() async {
    if (imgURL.isNotEmpty) {
      final inputImage = InputImage.fromFilePath(imgURL);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;
      String? gender = _extractGenderAndCheckValidity(extractedText);

      if (gender != null) {
        showDialog(
            context: context,
            builder: (context) {
              return const Center(
                child: CircularProgressIndicator(
                  color: deepGreen,
                ),
              );
            });
        dev.log("Gender verified: $gender");
        try {
          User? user = FirebaseAuth.instance.currentUser;
          var userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .get();

          if (gender.toLowerCase() ==
              (userDoc['gender'].toString().toLowerCase())) {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .update({
              'verifiedGender': true,
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Gender verified successfully!"),
              ),
            );
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfilePage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    "Mismatch: Gender in Aadhaar does not match your registered gender."),
              ),
            );
          }
        } catch (e) {
          dev.log("Error fetching user details for verification: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "An error occurred while verifying your gender. Please try again."),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Invalid Aadhaar card. Please upload a valid card that clearly shows your gender."),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No image selected. Please upload an Aadhaar card."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String? _extractGenderAndCheckValidity(String extractedText) {
    dev.log(extractedText);

    RegExp aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b');

    bool hasValidAadharNo = aadhaarRegex.hasMatch(extractedText);
    String lowerCaseText = extractedText.toLowerCase();
    if (lowerCaseText.contains("male") &&
        lowerCaseText.contains("government of india") &&
        hasValidAadharNo) {
      return "MALE";
    } else if (lowerCaseText.contains("female") &&
        lowerCaseText.contains("government of india") &&
        hasValidAadharNo) {
      return "FEMALE";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Profile Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: deepGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () {
                uploadImage();
              },
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: imgURL.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(imgURL)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imgURL.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_upload,
                              size: 150, color: Colors.grey),
                          const Text(
                            'Upload Aadhaar Here...',
                            style: TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 17),
                          )
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: verifyUser,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: const Text(
                "Verify User",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              backgroundColor: deepGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
