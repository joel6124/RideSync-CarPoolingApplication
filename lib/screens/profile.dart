import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/text_box.dart';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:ride_sync/screens/verification.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // @override
  // void dispose() {
  //   // Dispose the controllers when the widget is removed from the tree
  //   nameController.dispose();
  //   phoneController.dispose();
  //   emailController.dispose();
  //   super.dispose();
  // }

  final User? user = FirebaseAuth.instance.currentUser;
  String phoneNumber = "";
  String name = "";
  String email = "";
  String gender = "";
  String imgURL = "";
  int totalPools = 0;
  double rating = 0.0;
  bool isVerified = false;
  // String driverLicenseNo ="";

  Future<void> editField(String field, String currentValue) async {
    TextEditingController controller;

    // Select the correct controller based on the field
    if (field == 'name') {
      controller = nameController;
    } else if (field == 'number') {
      controller = phoneController;
    } else if (field == 'email') {
      controller = emailController;
    } else {
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: AlertDialog(
              backgroundColor: deepGreen
                  .withOpacity(0.1), // Background color for the AlertDialog
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    8.0), // Rounded corners for AlertDialog
                side:
                    BorderSide(color: Colors.black, width: 0.5), // Black border
              ),
              title: Text(
                'Edit $field',
                style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold), // Text color for title
              ),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter new $field',
                  filled: true,
                  fillColor: const Color.fromARGB(
                      255, 234, 234, 234), // Background color for the TextField
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        8.0), // Rounded corners for TextField
                  ),
                ),
                style: TextStyle(
                    color: Colors.black), // Text color inside TextField
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: const Color.fromARGB(255, 255, 255, 255)),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: const Color.fromARGB(255, 30, 79, 61),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text(
                    'Save',
                    style: TextStyle(
                        color: const Color.fromARGB(255, 255, 255, 255)),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: const Color.fromARGB(255, 30, 79, 61),
                  ),
                  onPressed: () async {
                    await saveUpdatedField(field, controller.text);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveUpdatedField(String field, String newValue) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .update({field: newValue});

        // Update the local state after successfully updating Firestore
        setState(() {
          if (field == 'name') {
            name = newValue;
          } else if (field == 'number') {
            phoneNumber = newValue;
          } else if (field == 'email') {
            email = newValue;
          }
        });
      } catch (e) {
        print('Error updating $field: $e');
      }
    }
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user!.uid)
            .get();

        if (documentSnapshot.exists) {
          setState(() {
            phoneNumber = documentSnapshot['phone'] ?? 'No Number Found';
            name = documentSnapshot['name'] ?? 'No Name Found';
            email = documentSnapshot['email'] ?? 'No Email_ID Found';
            gender = documentSnapshot['gender'] ?? 'No gender Found';
            imgURL = documentSnapshot['imgURL'] ??
                'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg';
            totalPools = (documentSnapshot['totalPools'] ?? 0) as int;
            rating = (documentSnapshot['rating'] ?? 0.0).toDouble();

            isVerified = documentSnapshot['verifiedGender'];

            // driverLicenseNo = documentSnapshot['driverLicenseNo'] ?? 'No License Found';
          });
        } else {
          setState(() {
            phoneNumber = 'No Number Found';
            name = 'No Name Found';
            email = 'No Email Found';
            gender = 'No Gender Found';
            imgURL =
                'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg';
            totalPools = 0;
            rating = 0.0;
            isVerified = false;
            // driverLicenseNo = 'No License Found';
          });
        }
      } catch (e) {
        setState(() {
          phoneNumber = 'Error fetching phone number';
          name = 'Error fetching name';
          email = 'Error fetching email';
          gender = 'Error fetching gender';
          imgURL =
              'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg';
          totalPools = 0;
          rating = 0.0;
          isVerified = false;
        });
        print('Error fetching user data: $e');
      }
    }
  }

  // // Edit field function
  // Future<void> editfield(String field) async {
  //   // Logic for editing fields
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: deepGreen,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 2),

          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: imgURL.isNotEmpty
                  ? NetworkImage(imgURL)
                  : NetworkImage(
                      'https://icon-library.com/images/user-icon-jpg/user-icon-jpg-0.jpg'),
            ),
          ),

          const SizedBox(height: 1),

          // Verified user
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVerified
                    ? Icons.verified_user_outlined
                    : Icons.sentiment_dissatisfied_sharp,
                color:
                    isVerified ? Colors.green : Color.fromARGB(255, 255, 0, 0),
              ),
              const SizedBox(width: 5),
              Text(
                isVerified ? "User Verified" : "Gender Not Verified",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[900]),
              ),
              if (!isVerified) ...{
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileVerificationPage()),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.amber,
                        ),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Verify',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              }
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color.fromARGB(255, 255, 191, 0),
                size: 22,
              ),
              Text(
                rating.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[900]),
              ),
            ],
          ),

          const SizedBox(height: 20),

          MyTextBox(
            text: name,
            sectionName: 'Name',
            onPressed: () => editField('name', name),
            prefixIcon: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25), color: deepGreen),
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          MyTextBox(
            text: phoneNumber,
            sectionName: 'Phone Number',
            onPressed: () => editField('number', phoneNumber),
            prefixIcon: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25), color: deepGreen),
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Icon(
                  Icons.phone_android,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 1),

          MyTextBox(
            text: email,
            sectionName: 'Email',
            onPressed: () => editField('email', email),
            prefixIcon: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25), color: deepGreen),
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Icon(
                  Icons.email,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 1),

          Stack(
            children: [
              MyTextBox(
                text: totalPools.toString(),
                sectionName: 'Rides Completed',
                onPressed: null,
                prefixIcon: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: deepGreen),
                  child: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: Icon(
                      Icons.local_taxi_outlined,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 1),

          Stack(
            children: [
              MyTextBox(
                text: gender,
                sectionName: 'Gender',
                onPressed: null,
                prefixIcon: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: deepGreen),
                  child: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: gender == "male"
                        ? Icon(
                            Icons.male,
                            color: Colors.white,
                            size: 24,
                          )
                        : Icon(
                            Icons.female,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
