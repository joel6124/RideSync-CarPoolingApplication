import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ride_sync/auth.dart';
import 'package:ride_sync/authentication/auth_database.dart';
import 'package:ride_sync/authentication/signin.dart';
import 'package:ride_sync/colours.dart';
import 'dart:developer';

class AuthService {
  final _authDatabase = AuthDatabase();

  //RESET PASSWORD
  Future<void> resetPassword(BuildContext context, String email) async {
    if (email.isEmpty) {
      errorMsg(context, "Please enter your email to reset your password!");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
        "Password Reset Email has been sent!",
        style: TextStyle(fontSize: 16),
      )));
      if (!context.mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) {
        return SignInPage();
      }));
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        errorMsg(context, "No such user found with this email!");
      } else if (e.code == "invalid-email") {
        errorMsg(context, "Please enter a valid Email!");
      } else {
        errorMsg(context, e.code);
      }
    }
  }

  //SEND EMAIL VERIFICATION
  Future<void> sendEmailVerificationLink() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (e) {
      print(e.toString());
    }
  }

  //REGISTER USER
  Future<void> registerUser(
      BuildContext context,
      String name,
      String email,
      String password,
      String passwordConfirm,
      String phone,
      String gender) async {
    if (password != passwordConfirm) {
      errorMsg(context, "Passwords do not match!");
      return;
    } else if (name.isEmpty) {
      errorMsg(context, "Please enter your Name!");
      return;
    } else if (email.isEmpty) {
      errorMsg(context, "Please enter your Email!");
      return;
    } else if (password.isEmpty || passwordConfirm.isEmpty) {
      errorMsg(context, 'Please enter your Password!');
      return;
    } else if (phone.length != 10) {
      errorMsg(context, "Please enter a valid 10 digit number!");
      return;
    }

    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });

    try {
      //registering user
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = credential.user;
      // VerificationScreen();
      // adding to firestore
      Map<String, dynamic> userInfoMap = {
        "name": name,
        "email": email,
        "phone": phone,
        "gender": gender,
        "imgURL": "",
        "id": user?.uid,
        "verifiedGender": false,
        "rating": 0,
        "fuelSaved": 0,
        "totalPools": 0,
        "totalCo2Saved": 0,
        "totalDistanceCovered": 0
      };

      if (!context.mounted) return;
      Navigator.pop(context); // Close the dialog

      await _authDatabase.addUser(user!.uid, userInfoMap);

      if (!context.mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) {
        return const AuthPage();
      }));

      // await _authDatabase.addUser(user!.uid, userInfoMap).then((value) {
      //   Navigator.of(context).pushReplacement(
      //     MaterialPageRoute(builder: (context) {
      //       return const AuthPage();
      //     }),
      //   );
      // }).catchError((error) {
      //   // Navigator.pop(context);
      //   errorMsg(context, "Error: $error");
      // }); // Naviogin page
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'weak-password') {
        errorMsg(context, "The password provided is too weak.");
      } else if (e.code == 'email-already-in-use') {
        errorMsg(context, "The account already exists for that email.");
      } else {
        errorMsg(context, e.code);
      }
    }
  }

  //SIGN IN
  //
  Future<void> signInUser(
      BuildContext context, String email, String password) async {
    if (email.isEmpty) {
      errorMsg(context, "Please enter your Email!");
      return;
    } else if (password.isEmpty) {
      errorMsg(context, "Please enter your Password!");
      return;
    }
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close the dialog
      if (!context.mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) {
        return const AuthPage();
      }));
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      if (e.code == 'invalid-email') {
        errorMsg(context, 'Enter a valid Email with proper format!');
      } else if (e.code == 'invalid-credential') {
        errorMsg(
            context, 'The provided credential is invalid. Please try again.');
      } else if (e.code == 'user-not-found') {
        errorMsg(context, "No such user with this Email!");
      } else if (e.code == 'wrong-password') {
        errorMsg(context, "Incorrect Password!");
      } else {
        errorMsg(context, e.code);
      }
    }
  }

// SIGN OUT USER
  void SignOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // GOOGLE AUTHENTICATION
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      log("Check 1");
      if (googleSignInAccount == null) {
        print("Error: Google Sign-In canceled by user.");
        errorMsg(context, "Google Sign-In canceled by user.");
        return;
      }
      log("Check 2");

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      log("ID Token: ${googleSignInAuthentication.idToken}");
      log("Access Token: ${googleSignInAuthentication.accessToken}");

      log("Check 3");
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );
      log("Check 4");
      UserCredential result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? userDetails = result.user;

      if (userDetails == null) {
        if (!context.mounted) return;
        errorMsg(context, "Error: User sign-in failed!");
        return;
      }

      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) {
        return const AuthPage();
      }));
    } catch (e) {
      if (!context.mounted) return;

      // if (e is PlatformException) {
      //   // Handle PlatformException specifically
      //   final String? errorCode = e.code;
      //   final String? errorMessage = e.message;
      //   final dynamic errorDetails = e.details;

      //   errorMsg(context,
      //       "PlatformException: Code: $errorCode, Message: $errorMessage");
      //   print(
      //       "PlatformException: Code: $errorCode, Message: $errorMessage, Details: $errorDetails");
      // } else {
      // Handle other types of exceptions
      errorMsg(context, "Error: ${e.toString()}");
      print("Error: GSignIn: ${e.toString()}");
    }
  }

// REGISTERING WITH GOOGLE
  Future<void> registerUserWithGoogle(
      BuildContext context,
      String name,
      String email,
      String phone,
      String gender,
      String photoUrl,
      String uid) async {
    if (phone.length != 10) {
      errorMsg(context, "Please enter a valid 10 digit number!");
      return;
    }

    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: deepGreen,
            ),
          );
        });

    try {
      Map<String, dynamic> userInfoMap = {
        "name": name,
        "email": email,
        "phone": phone,
        "gender": gender,
        "imgURL": photoUrl,
        "id": uid,
        "verifiedGender": false,
        "rating": 0,
        "fuelSaved": 0,
        "totalPools": 0,
        "totalCo2Saved": 0,
        "totalDistanceCovered": 0
      };

      if (!context.mounted) return;
      Navigator.pop(context); // Close the dialog

      await _authDatabase.addUser(uid, userInfoMap).then((value) {
        print("User registered successfully, navigating to AuthPage.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) {
            print("Navigating to AuthPage");
            return const AuthPage();
          }),
        );
      }).catchError((error) {
        errorMsg(context, "Error: $error");
      });
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      errorMsg(context, e.toString());
    }
  }

// SNACKBAR FOR ERRORS
  void errorMsg(BuildContext context, String errorMsg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        errorMsg,
        style: const TextStyle(fontSize: 16),
      )));
    }
  }
}
