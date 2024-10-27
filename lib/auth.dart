import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_sync/authentication/signin.dart';
import 'package:ride_sync/authentication/signup_google.dart';
import 'package:ride_sync/authentication/verification_screen.dart';
import 'package:ride_sync/colours.dart';
import 'package:ride_sync/screens/home.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Not logged in
          if (!snapshot.hasData) {
            return const SignInPage();
          } else {
            User? user = snapshot.data;

            // If the user is signed in with Google
            if (user?.providerData
                    .any((userInfo) => userInfo.providerId == 'google.com') ==
                true) {
              return FutureBuilder<bool>(
                future: checkUserRegistered(user),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: deepGreen,
                    ));
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('An error occurred'));
                  } else if (snapshot.hasData) {
                    bool isRegistered = snapshot.data!;
                    if (isRegistered) {
                      return const HomePage();
                    } else {
                      return RegisterGooglePage(
                        name: user?.displayName ?? '',
                        email: user?.email ?? '',
                        photoUrl: user?.photoURL ?? '',
                        uid: user!.uid,
                      );
                    }
                  } else {
                    return const Center(child: Text('Something went wrong'));
                  }
                },
              );
            }

            // If email is verified
            if (user?.emailVerified == true) {
              return const HomePage();
            }
            return const VerificationScreen();
          }
        },
      ),
    );
  }

  Future<bool> checkUserRegistered(User? user) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: user?.email)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
